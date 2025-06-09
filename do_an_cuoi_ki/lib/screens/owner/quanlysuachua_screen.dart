import 'package:do_an_cuoi_ki/models/DVSC.dart';
import 'package:do_an_cuoi_ki/models/phieu_sua_chua.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

// Đảm bảo đường dẫn này đúng cho BillModel và PaymentStatus enum
import 'package:do_an_cuoi_ki/models/bill/bill.dart'; 
// Mới: Import các model cần thiết để lấy thông tin chủ trọ/khách thuê
import 'package:do_an_cuoi_ki/models/room.dart'; 
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';

class QuanLyPhieuSuaChuaScreen extends StatefulWidget {
  final String roomId;

  const QuanLyPhieuSuaChuaScreen({super.key, required this.roomId});

  @override
  _QuanLyPhieuSuaChuaScreenState createState() => _QuanLyPhieuSuaChuaScreenState();
}

class _QuanLyPhieuSuaChuaScreenState extends State<QuanLyPhieuSuaChuaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PhieuSuaChua> _phieuList = [];
  PhieuSuaChua? _selectedPhieu;
  bool _isLoading = true;
  final List<CompensationItem> _items = [];
  final TextEditingController _itemInfoController = TextEditingController();
  final TextEditingController _itemCostController = TextEditingController();
  DonViSuaChua? _selectedDonViSuaChua;
  List<DonViSuaChua> _donViSuaChuaList = [];
  FaultSource? _selectedFaultSource;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemInfoController.dispose();
    _itemCostController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await Future.wait([
        _loadPhieuSuaChua(),
        _loadDonViSuaChuaList(),
      ]);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi khi tải dữ liệu: $e');
    }
  }

  Future<void> _loadPhieuSuaChua() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('phieu_sua')
          .where('roomId', isEqualTo: widget.roomId)
          .get();

      setState(() {
        _phieuList = querySnapshot.docs
            .map((doc) => PhieuSuaChua.fromFirestore(doc, null))
            .toList();
        if (_selectedPhieu != null && !_phieuList.any((p) => p.id == _selectedPhieu!.id)) {
          _selectedPhieu = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi khi tải danh sách phiếu: $e');
    }
  }

  Future<void> _loadDonViSuaChuaList() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('DonViSuaChuas')
          .get();

      setState(() {
        _donViSuaChuaList = querySnapshot.docs.map((doc) => DonViSuaChua.fromFirestore(doc, null)).toList();
      });
    } catch (e) {
      _showError('Lỗi khi tải danh sách nhà cung cấp: $e');
    }
  }

  Future<void> _savePhieuSuaChua(PhieuSuaChua phieu) async {
    if (_items.isEmpty) {
      _showError('Vui lòng thêm ít nhất một hạng mục');
      return;
    }
    if (_selectedFaultSource == null) {
      _showError('Vui lòng chọn nguồn lỗi');
      return;
    }

    try {
      final updatedPhieu = phieu.copyWith(
        items: _items,
        tongTien: PhieuSuaChua.calculateTotal(_items),
        DVSSId: _selectedDonViSuaChua?.id,
        faultSource: _selectedFaultSource,
        status: phieu.status,
      );

      // Lưu/Cập nhật phiếu sửa chữa
      if (phieu.id == null) {
        await FirebaseFirestore.instance
            .collection('phieu_sua')
            .add(updatedPhieu.toFirestore());
      } else {
        await FirebaseFirestore.instance
            .collection('phieu_sua')
            .doc(phieu.id)
            .update(updatedPhieu.toFirestore());
      }

      // Cập nhật trạng thái yêu cầu
      if (phieu.requestId != null) {
        final status = updatedPhieu.status == RepairStatus.completed ? 'approved' :
                       updatedPhieu.status == RepairStatus.cancelled ? 'rejected' : 'pending';
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(phieu.requestId)
            .update({'status': status});
      }

      // Logic cập nhật hóa đơn
      if (updatedPhieu.status == RepairStatus.completed && updatedPhieu.faultSource == FaultSource.tenant) {
        final currentMonth = DateFormat('MM/yyyy').format(DateTime.now());
        final billsRef = FirebaseFirestore.instance.collection('bills');

        try {
          final billQuery = await billsRef
              .where('roomId', isEqualTo: updatedPhieu.roomId)
              .where('thangNam', isEqualTo: currentMonth)
              .limit(1)
              .get();

          if (billQuery.docs.isNotEmpty) {
            // Hóa đơn tồn tại, cập nhật chi phí tiện ích (amenitiesPrice) và tổng tiền
            final billDoc = billQuery.docs.first;
            final currentBillData = billDoc.data();
            
            // Chuyển đổi dữ liệu hiện có thành BillModel để dùng copyWith
            final existingBill = BillModel.fromJson({
                ...currentBillData, 
                'id': billDoc.id,
                // Đảm bảo các trường int/double không null để fromJson không dùng ?? 0
                'sodienCu': (currentBillData['sodienCu'] as num?)?.toInt() ?? 0,
                'sodienMoi': (currentBillData['sodienMoi'] as num?)?.toInt() ?? 0,
                'soNguoi': (currentBillData['soNguoi'] as num?)?.toInt() ?? 0,
                'priceRoom': (currentBillData['priceRoom'] as num?)?.toDouble() ?? 0.0,
                'priceDien': (currentBillData['priceDien'] as num?)?.toDouble() ?? 0.0,
                'priceWater': (currentBillData['priceWater'] as num?)?.toDouble() ?? 0.0,
                'amenitiesPrice': (currentBillData['amenitiesPrice'] as num?)?.toDouble() ?? 0.0,
                // Đảm bảo date là DateTime
                'date': (currentBillData['date'] is Timestamp) ? (currentBillData['date'] as Timestamp).toDate() : DateTime.now(),
                // Đảm bảo status là string để fromJson xử lý
                'status': currentBillData['status'] as String? ?? PaymentStatus.pending.toJson(),
            });

            // Cập nhật amenitiesPrice và tính lại sumPrice bằng copyWith
            final updatedAmenitiesPrice = existingBill.amenitiesPrice + updatedPhieu.tongTien;
            final updatedBill = existingBill.copyWith(
              amenitiesPrice: updatedAmenitiesPrice,
              // sumPrice sẽ được tính lại tự động bởi tinhTongTien trong copyWith nếu các trường liên quan thay đổi
            );

            await billsRef.doc(billDoc.id).update(updatedBill.toJson()); // Lưu toàn bộ Map đã cập nhật
            _showSuccess('Phiếu sửa chữa đã lưu. Chi phí đã được thêm vào hóa đơn tháng này!');
          } else {
            // Hóa đơn chưa tồn tại, tạo hóa đơn mới với chi phí sửa chữa
            String ownerId = '';
            String khachThueId = '';

            // Bước 1: Lấy ownerId từ thông tin phòng
            final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(updatedPhieu.roomId).get();
            if (roomDoc.exists) {
              ownerId = roomDoc.data()?['ownerId'] as String? ?? ''; // Giả định 'ownerId' có trong document room
            } else {
              _showError('Không tìm thấy thông tin phòng để lấy chủ trọ.');
              return;
            }

            // Bước 2: Lấy khachThueId từ hợp đồng đang hoạt động của phòng
            final contractQuery = await FirebaseFirestore.instance.collection('contracts')
                .where('roomId', isEqualTo: updatedPhieu.roomId)
                .where('status', isEqualTo: ContractStatus.active.toJson()) // Dùng toJson() cho enum
                .limit(1)
                .get();
            if (contractQuery.docs.isNotEmpty) {
              khachThueId = contractQuery.docs.first.data()['tenantId'] as String? ?? ''; // Giả định 'tenantId' có trong document contract
            } else {
              _showError('Không tìm thấy hợp đồng đang hoạt động cho phòng này để lấy khách thuê.');
              return;
            }
            
            if (ownerId.isEmpty || khachThueId.isEmpty) {
                 _showError('Thiếu thông tin chủ trọ hoặc khách thuê hợp lệ để tạo hóa đơn.');
                 return;
            }

            final newBillId = billsRef.doc().id;
            final newBill = BillModel(
              id: newBillId,
              roomId: updatedPhieu.roomId,
              ownerId: ownerId, // Lấy từ phòng
              khachThueId: khachThueId, // Lấy từ hợp đồng
              sodienCu: 0,
              sodienMoi: 0,
              soNguoi: 0,
              priceRoom: 0.0,
              priceDien: 0.0,
              priceWater: 0.0,
              amenitiesPrice: updatedPhieu.tongTien, // Chi phí sửa chữa là amenitiesPrice
              date: DateTime.now(),
              thangNam: currentMonth,
              sumPrice: 0.0, // Tạm thời, sẽ được tính lại bằng tinhTongTien
              status: PaymentStatus.pending, // Trạng thái mặc định là pending enum
            );
            
            // Tính toán sumPrice cuối cùng và lưu hóa đơn mới
            final calculatedSumPrice = newBill.tinhTongTien;
            await billsRef.doc(newBillId).set(newBill.copyWith(sumPrice: calculatedSumPrice).toJson());
            _showSuccess('Phiếu sửa chữa đã lưu. Hóa đơn mới đã được tạo với chi phí sửa chữa!');
          }
        } catch (billError) {
          print("Lỗi khi cập nhật/tạo hóa đơn: $billError");
          _showError('Lỗi khi cập nhật hóa đơn: $billError');
        }
      } else {
        _showSuccess('Lưu phiếu thành công!');
      }

      await _loadPhieuSuaChua();
      setState(() {
        _selectedPhieu = null;
        _items.clear();
        _selectedDonViSuaChua = null;
        _selectedFaultSource = null;
      });
      _tabController.animateTo(0);
    } catch (e) {
      _showError('Lỗi khi lưu phiếu: $e');
    }
  }

  Future<void> _deletePhieu(String phieuId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa phiếu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final phieu = _phieuList.firstWhere((p) => p.id == phieuId);
      await FirebaseFirestore.instance
          .collection('phieu_sua')
          .doc(phieuId)
          .delete();

      if (phieu.requestId != null) {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(phieu.requestId)
            .update({'status': 'rejected'});
      }

      _showSuccess('Đã xóa phiếu thành công!');
      await _loadPhieuSuaChua();
      if (_selectedPhieu?.id == phieuId) {
        setState(() {
          _selectedPhieu = null;
          _items.clear();
          _selectedDonViSuaChua = null;
          _selectedFaultSource = null;
        });
      }
    } catch (e) {
      _showError('Lỗi khi xóa phiếu: $e');
    }
  }

  void _addItem() {
    if (_itemInfoController.text.isEmpty || _itemCostController.text.isEmpty) {
      _showError('Vui lòng nhập đầy đủ mô tả và chi phí');
      return;
    }

    final double cost = double.tryParse(_itemCostController.text) ?? 0;
    if (cost < 0) {
      _showError('Chi phí không thể âm');
      return;
    }

    setState(() {
      _items.add(CompensationItem(
        info: _itemInfoController.text.trim(),
        cost: cost,
      ));
      _itemInfoController.clear();
      _itemCostController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPhieu?.ngaySua ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedPhieu = _selectedPhieu?.copyWith(ngaySua: picked) ??
            PhieuSuaChua(
              roomId: widget.roomId,
              tenantId: _selectedPhieu?.tenantId ?? '',
              ngaySua: picked,
              tongTien: 0,
              status: RepairStatus.completed,
              faultSource: _selectedFaultSource ?? FaultSource.tenant,
            );
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Sửa chữa - Phòng ${widget.roomId}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Danh sách'),
            Tab(icon: Icon(Icons.edit), text: 'Chỉnh sửa/Tạo mới'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDanhSachTab(),
          _buildChinhSuaTab(),
        ],
      ),
    );
  }

  Widget _buildDanhSachTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_phieuList.isEmpty) {
      return const Center(child: Text('Không có phiếu sửa chữa nào.'));
    }

    return ListView.builder(
      itemCount: _phieuList.length,
      itemBuilder: (context, index) {
        final phieu = _phieuList[index];
        return Card(
          margin: const EdgeInsets.all(8),
          color: _selectedPhieu?.id == phieu.id ? Colors.blue[50] : null,
          child: ListTile(
            title: Text('Phiếu #${phieu.id?.substring(0, 8)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngày: ${DateFormat('dd/MM/yyyy').format(phieu.ngaySua)}'),
                Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi').format(phieu.tongTien)}'),
                Text('Trạng thái: ${phieu.statusText}'),
                Text('Nguồn lỗi: ${phieu.faultSourceText}'),
                if (phieu.requestId != null)
                  Text('Yêu cầu: #${phieu.requestId!.substring(0, 8)}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePhieu(phieu.id!),
            ),
            onTap: () {
              setState(() {
                _selectedPhieu = phieu;
                _items.clear();
                if (phieu.items != null) {
                  _items.addAll(phieu.items!);
                }
                _selectedFaultSource = phieu.faultSource;

                if (phieu.DVSSId == null || phieu.DVSSId!.isEmpty) {
                  _selectedDonViSuaChua = null;
                } else {
                  _selectedDonViSuaChua = _donViSuaChuaList.firstWhereOrNull((ncc) => ncc.id == phieu.DVSSId);
                }
                _tabController.animateTo(1);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildChinhSuaTab() {
    final phieu = _selectedPhieu ?? PhieuSuaChua(
      roomId: widget.roomId,
      tenantId: '',
      ngaySua: DateTime.now(),
      tongTien: 0,
      status: RepairStatus.completed,
      faultSource: FaultSource.tenant,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Ngày sửa chữa'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(phieu.ngaySua)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<DonViSuaChua>(
                    value: _selectedDonViSuaChua,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị sửa chữa',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<DonViSuaChua>(
                        value: null,
                        child: Text('Không chọn'),
                      ),
                      ..._donViSuaChuaList.map((ncc) {
                        return DropdownMenuItem<DonViSuaChua>(
                          value: ncc,
                          child: Text(ncc.ten),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDonViSuaChua = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<RepairStatus>(
                    value: phieu.status,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    items: RepairStatus.values.map((status) {
                      return DropdownMenuItem<RepairStatus>(
                        value: status,
                        child: Text(status == RepairStatus.pending ? 'Chờ xử lý' :
                                    status == RepairStatus.completed ? 'Đã hoàn thành' :
                                    'Đã hủy'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPhieu = phieu.copyWith(status: value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<FaultSource>(
                    value: _selectedFaultSource ?? phieu.faultSource,
                    decoration: const InputDecoration(
                      labelText: 'Nguồn lỗi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null ? 'Vui lòng chọn nguồn lỗi' : null,
                    items: FaultSource.values.map((source) {
                      return DropdownMenuItem<FaultSource>(
                        value: source,
                        child: Text(source == FaultSource.tenant ? 'Khách thuê' : 'Chủ trọ'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFaultSource = value;
                          _selectedPhieu = phieu.copyWith(faultSource: value);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Vật tư/Hạng mục sửa chữa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _itemInfoController,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _itemCostController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Chi phí',
                            border: OutlineInputBorder(),
                            prefixText: '₫',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_items.isNotEmpty)
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return ListTile(
                        title: Text(item.info),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(NumberFormat.currency(locale: 'vi', symbol: '₫').format(item.cost)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'vi', symbol: '₫').format(
                      PhieuSuaChua.calculateTotal(_items),
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_selectedFaultSource == null) {
                _showError('Vui lòng chọn nguồn lỗi');
                return;
              }
              _savePhieuSuaChua(phieu);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('LƯU PHIẾU'),
          ),
        ],
      ),
    );
  }
}