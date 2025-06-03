  import 'package:do_an_cuoi_ki/models/DVSC.dart';
  import 'package:do_an_cuoi_ki/models/phieu_sua_chua.dart';
  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:intl/intl.dart';

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
final List<DonViSuaChua> _DonViSuaChuaList = [];

    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 2, vsync: this);
      _loadData();
    }

    Future<void> _loadData() async {
      await Future.wait([
        _loadPhieuSuaChua(),
        _loadDonViSuaChuaList(),
      ]);
    }

    Future<void> _loadPhieuSuaChua() async {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('phieuSuaChua')
            .where('roomId', isEqualTo: widget.roomId)
            .get();

        setState(() {
          _phieuList = querySnapshot.docs
              .map((doc) => PhieuSuaChua.fromFirestore(doc, null))
              .toList();
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
        _DonViSuaChuaList.addAll(
          querySnapshot.docs.map((doc) => DonViSuaChua.fromFirestore(doc, null)),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách nhà cung cấp: $e')),
      );
    }
  }

    Future<void> _savePhieuSuaChua(PhieuSuaChua phieu) async {
      try {
        if (phieu.id == null) {
          await FirebaseFirestore.instance
              .collection('phieuSuaChua')
              .add(phieu.toFirestore());
        } else {
          await FirebaseFirestore.instance
              .collection('phieuSuaChua')
              .doc(phieu.id)
              .update(phieu.toFirestore());
        }
        _showSuccess('Lưu phiếu thành công!');
        await _loadPhieuSuaChua();
      } catch (e) {
        _showError('Lỗi khi lưu phiếu: $e');
      }
    }

    void _addItem() {
      if (_itemInfoController.text.isEmpty && _itemCostController.text.isEmpty) return;

      setState(() {
        _items.add(CompensationItem(
          info: _itemInfoController.text,
          cost: double.tryParse(_itemCostController.text) ?? 0,
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
                tenantId: '',
                ngaySua: picked,
                tongTien: 0,
                status: RepairStatus.pending,
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
              Tab(icon: Icon(Icons.list_alt)),
              Tab(icon: Icon(Icons.edit)),
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
        status: RepairStatus.pending,
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
                                ..._DonViSuaChuaList.map((ncc) {
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
                      items: RepairStatus.values.map((status) {
                        return DropdownMenuItem<RepairStatus>(
                          value: status,
                          child: Text(status.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPhieu = phieu.copyWith(status: value);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Danh sách vật tư/hạng mục
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
                              Text(
                                NumberFormat.currency(locale: 'vi', symbol: '₫').format(item.cost),
                              ),
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

            // Tổng tiền
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
                      NumberFormat.currency(locale: 'vi', symbol: '₫')
                          .format(PhieuSuaChua.calculateTotal(_items.isEmpty ? null : _items)),
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

            // Nút lưu
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final updatedPhieu = phieu.copyWith(
                  items: _items.isEmpty ? null : _items,
                  tongTien: PhieuSuaChua.calculateTotal(_items.isEmpty ? null : _items),
                );
                _savePhieuSuaChua(updatedPhieu);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('LƯU PHIẾU SỬA CHỮA'),
            ),
          ],
        ),
      );
    }

    Future<void> _deletePhieu(String phieuId) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc muốn xóa phiếu này?'),
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

      if (confirm == true) {
        try {
          await FirebaseFirestore.instance
              .collection('phieuSuaChua')
              .doc(phieuId)
              .delete();
          _showSuccess('Đã xóa phiếu thành công');
          await _loadPhieuSuaChua();
          if (_selectedPhieu?.id == phieuId) {
            setState(() {
              _selectedPhieu = null;
              _items.clear();
            });
          }
        } catch (e) {
          _showError('Lỗi khi xóa phiếu: $e');
        }
      }
    }

    @override
    void dispose() {
      _tabController.dispose();
      _itemInfoController.dispose();
      _itemCostController.dispose();
      super.dispose();
    }
  }