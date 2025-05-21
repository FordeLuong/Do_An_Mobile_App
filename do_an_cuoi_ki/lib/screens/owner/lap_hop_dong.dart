import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ContractFormPage extends StatefulWidget {
  final String roomId;
  final String ownerId;

  const ContractFormPage({
    Key? key,
    required this.roomId,
    required this.ownerId,
  }) : super(key: key);

  @override
  _ContractFormPageState createState() => _ContractFormPageState();
}

class _ContractFormPageState extends State<ContractFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  late String _selectedTenantId = '';
  List<Map<String, dynamic>> _tenantRequests = [];

  // Các biến khác giữ nguyên...
  late DateTime _startDate;
  late DateTime _endDate;
  double _rentAmount = 0.0;
  double _depositAmount = 0.0;
  String _termsAndConditions = '';
  ContractStatus _status = ContractStatus.active;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 365));
    _loadTenantRequests();
  }

  Future<void> _loadTenantRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection('requests')
          .where('room_id', isEqualTo: widget.roomId)
          .where('loai_request', isEqualTo: 'thue_phong')
          .get();

      setState(() {
        _tenantRequests = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'user_khach_id': data['user_khach_id'],
            'sdt': data['sdt'],
            'mo_ta': data['mo_ta'],
            'Name':data['Name']
          };
        }).toList();

        if (_tenantRequests.isNotEmpty) {
          _selectedTenantId = _tenantRequests.first['user_khach_id'];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách yêu cầu: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedTenantId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn người thuê')),
        );
        return;
      }

      try {
        // Tạo hợp đồng mới
        final newContract = ContractModel(
          id: _firestore.collection('contracts').doc().id,
          roomId: widget.roomId,
          tenantId: _selectedTenantId,
          ownerId: widget.ownerId,
          startDate: _startDate,
          endDate: _endDate,
          rentAmount: _rentAmount,
          depositAmount: _depositAmount,
          termsAndConditions: _termsAndConditions,
          status: _status,
          paymentHistoryIds: null,
          createdAt: DateTime.now(),
          updatedAt: null,
        );

        // Lưu vào Firestore
        await _firestore
            .collection('contracts')
            .doc(newContract.id)
            .set(newContract.toJson());

        final batch = _firestore.batch();
        final roomRef = _firestore.collection('rooms').doc(widget.roomId);
        batch.update(roomRef, {
          'status': 'rented',
          'ownerId':_selectedTenantId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await batch.commit();
        // Thông báo thành công và quay lại
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hợp đồng đã được tạo thành công!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tạo hợp đồng: ${e.toString()}')),
        );
      }
    }
  }
   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Nếu ngày kết thúc nhỏ hơn ngày bắt đầu, cập nhật ngày kết thúc
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Các phương thức khác (_selectDate, _buildInfoRow, _buildDateField) giữ nguyên...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Hợp Đồng Thuê Trọ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin phòng và chủ trọ (chỉ hiển thị)
              _buildInfoRow('Phòng trọ:', widget.roomId),
              _buildInfoRow('Chủ trọ:', widget.ownerId),

              const SizedBox(height: 20),

              // Dropdown người thuê
              DropdownButtonFormField<String>(
                value: _selectedTenantId.isNotEmpty ? _selectedTenantId : null,
                decoration: const InputDecoration(
                  labelText: 'Người thuê',
                  border: OutlineInputBorder(),
                ),
                items: _tenantRequests.map((request) {
                  return DropdownMenuItem<String>(
                    value: request['user_khach_id'],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text('SĐT: ${request['sdt']}'),
                        // Text('Mô tả: ${request['mo_ta']}'),
                        Text('Tên: ${request['Name']}'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTenantId = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn người thuê';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Các trường khác giữ nguyên...
              _buildDateField(
                label: 'Ngày bắt đầu',
                date: _startDate,
                onTap: () => _selectDate(context, true),
              ),

              const SizedBox(height: 16),

              _buildDateField(
                label: 'Ngày kết thúc',
                date: _endDate,
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 16),

              // Số tiền thuê
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Số tiền thuê hàng tháng',
                  prefixText: '₫',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền thuê';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
                onSaved: (value) =>
                    _rentAmount = double.tryParse(value ?? '0') ?? 0.0,
              ),

              const SizedBox(height: 16),

              // Tiền cọc
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Tiền đặt cọc',
                  prefixText: '₫',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền cọc';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
                onSaved: (value) =>
                    _depositAmount = double.tryParse(value ?? '0') ?? 0.0,
              ),

              const SizedBox(height: 16),

              // Trạng thái hợp đồng
              DropdownButtonFormField<ContractStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái hợp đồng',
                  border: OutlineInputBorder(),
                ),
                items: ContractStatus.values.map((status) {
                  return DropdownMenuItem<ContractStatus>(
                    value: status,
                    child: Text(status.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Điều khoản và điều kiện
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Điều khoản và điều kiện',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                onSaved: (value) => _termsAndConditions = value ?? '',
              ),

              const SizedBox(height: 24),

              // Nút gửi
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Tạo Hợp Đồng',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(date)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}