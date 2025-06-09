import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/DVSC.dart';
import 'package:do_an_cuoi_ki/models/phieu_sua_chua.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SuaChua extends StatefulWidget {
  final String roomId;
  final String tenantId;
  final String? requestId;

  const SuaChua({
    super.key,
    required this.roomId,
    required this.tenantId,
    this.requestId,
  });

  @override
  State<SuaChua> createState() => _SuaChuaState();
}

class _SuaChuaState extends State<SuaChua> {
  final TextEditingController _itemInfoController = TextEditingController();
  final TextEditingController _itemCostController = TextEditingController();
  List<CompensationItem> _items = [];
  DonViSuaChua? _selectedDonViSuaChua;
  List<DonViSuaChua> _donViSuaChuaList = [];
  FaultSource? _selectedFaultSource;
  DateTime _ngaySua = DateTime.now();
  bool _isLoading = true;
  RepairStatus _status = RepairStatus.pending;

  @override
  void initState() {
    super.initState();
    _loadDonViSuaChua();
    if (widget.requestId != null) {
      _status = RepairStatus.pending;
    }
  }

  Future<void> _loadDonViSuaChua() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('DonViSuaChuas')
          .get();
      setState(() {
        _donViSuaChuaList = querySnapshot.docs
            .map((doc) => DonViSuaChua.fromFirestore(doc, null))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi tải danh sách đơn vị sửa chữa: $e');
    }
  }

  // ĐÃ LOẠI BỎ: Hàm _sendNotification
  /*
  Future<void> _sendNotification(String tenantId, String title, String message) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'id': FirebaseFirestore.instance.collection('notifications').doc().id,
        'userId': tenantId,
        'title': title,
        'message': message,
        'timestamp': Timestamp.now(),
        'isRead': false,
      });
    } catch (e) {
      print('Lỗi gửi thông báo: $e');
    }
  }
  */

  Future<bool> _savePhieu() async {
    if (_items.isEmpty) {
      _showError('Vui lòng thêm ít nhất một hạng mục');
      return false;
    }
    if (_selectedFaultSource == null) {
      _showError('Vui lòng chọn nguồn lỗi');
      return false;
    }

    try {
      final phieu = PhieuSuaChua(
        id: null,
        roomId: widget.roomId,
        tenantId: widget.tenantId,
        ngaySua: _ngaySua,
        items: _items,
        tongTien: PhieuSuaChua.calculateTotal(_items),
        DVSSId: _selectedDonViSuaChua?.id,
        status: _status,
        faultSource: _selectedFaultSource!,
        requestId: widget.requestId,
      );

      final docRef = await FirebaseFirestore.instance
          .collection('phieu_sua')
          .add(phieu.toFirestore());

      // ĐÃ LOẠI BỎ: Lời gọi _sendNotification
      /*
      await _sendNotification(
        widget.tenantId,
        'Phiếu sửa chữa mới',
        'Phiếu sửa chữa #${docRef.id.substring(0, 8)} đã được tạo cho phòng ${widget.roomId}.',
      );
      */

      if (widget.requestId != null) {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId)
            .update({'status': 'approved'});
      }

      _showSuccess('Tạo phiếu sửa chữa thành công!');
      Navigator.pop(context, true);
      return true;
    } catch (e) {
      _showError('Lỗi khi tạo phiếu: $e');
      return false;
    }
  }

  void _addItem() {
    if (_itemInfoController.text.isEmpty || _itemCostController.text.isEmpty) {
      _showError('Vui lòng nhập đầy đủ mô tả và chi phí');
      return;
    }

    final cost = double.tryParse(_itemCostController.text);
    if (cost == null || cost < 0) {
      _showError('Chi phí không hợp lệ');
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngaySua,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _ngaySua = picked;
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isStatusDropdownDisabled = widget.requestId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo Phiếu Sửa Chữa - Phòng ${widget.roomId}'),
      ),
      body: SingleChildScrollView(
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
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_ngaySua)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _selectDate,
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
                        ..._donViSuaChuaList.map((ncc) => DropdownMenuItem<DonViSuaChua>(
                              value: ncc,
                              child: Text(ncc.ten),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDonViSuaChua = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FaultSource>(
                      value: _selectedFaultSource,
                      decoration: const InputDecoration(
                        labelText: 'Nguồn lỗi',
                        border: OutlineInputBorder(),
                      ),
                      items: FaultSource.values.map((source) {
                        return DropdownMenuItem<FaultSource>(
                          value: source,
                          child: Text(source == FaultSource.tenant ? 'Khách thuê' : 'Chủ trọ'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFaultSource = value;
                        });
                      },
                      validator: (value) => value == null ? 'Vui lòng chọn nguồn lỗi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RepairStatus>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        border: const OutlineInputBorder(),
                        enabled: !isStatusDropdownDisabled,
                      ),
                      items: RepairStatus.values.map((status) {
                        return DropdownMenuItem<RepairStatus>(
                          value: status,
                          child: Text(status == RepairStatus.pending
                              ? 'Chờ xử lý'
                              : status == RepairStatus.completed
                                  ? 'Đã hoàn thành'
                                  : 'Đã hủy'),
                        );
                      }).toList(),
                      onChanged: isStatusDropdownDisabled ? null : (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
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
                      'Hạng mục sửa chữa',
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
                              Text(NumberFormat.currency(locale: 'vi').format(item.cost)),
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
                      NumberFormat.currency(locale: 'vi').format(
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
            if (widget.requestId != null)
              Text(
                'Liên kết với yêu cầu: #${widget.requestId!.substring(0, 8)}',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _savePhieu();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('LƯU PHIẾU'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _itemInfoController.dispose();
    _itemCostController.dispose();
    super.dispose();
  }
}