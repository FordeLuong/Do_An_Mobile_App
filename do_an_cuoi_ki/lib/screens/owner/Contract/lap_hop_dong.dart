import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/room.dart';
import 'package:do_an_cuoi_ki/models/request.dart';
import 'package:do_an_cuoi_ki/services/contract_service.dart';
import 'package:do_an_cuoi_ki/services/request_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContractFormPage extends StatefulWidget {
  final String roomId;
  final String ownerId;

  const ContractFormPage({
    super.key,
    required this.roomId,
    required this.ownerId,
  });

  @override
  _ContractFormPageState createState() => _ContractFormPageState();
}

enum ContractDuration { sixMonths, twelveMonths }
enum DepositOption { payNow, extend48h } // Thêm enum cho lựa chọn đóng cọc

class _ContractFormPageState extends State<ContractFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _contractService = ContractService();
  final _requestService = RequestService();
  
  String? _selectedTenantId;
  List<Map<String, dynamic>> _tenantRequests = [];

  late DateTime _startDate;
  double _rentAmount = 0.0;
  double _depositAmount = 0.0;
  final String _defaultTermsAndConditions = """
**ĐIỀU KHOẢN VÀ ĐIỀU KIỆN HỢP ĐỒNG THUÊ TRỌ**

**Bên A (Bên Cho Thuê):**
**Bên B (Bên Thuê):**

Hai bên thống nhất ký kết hợp đồng thuê trọ với các điều khoản sau:

**I. TRÁCH NHIỆM CỦA BÊN A (BÊN CHO THUÊ):**
1. Bàn giao phòng trọ cho Bên B đúng theo hiện trạng đã thỏa thuận, đảm bảo các trang thiết bị cơ bản (nếu có) hoạt động bình thường.
2. Đảm bảo quyền sử dụng riêng biệt, trọn vẹn phần diện tích thuê của Bên B.
3. Cung cấp đầy đủ, kịp thời các dịch vụ đã cam kết (điện, nước, internet - nếu có) và thu phí theo đúng quy định/thỏa thuận.
4. Thực hiện sửa chữa các hư hỏng thuộc về cấu trúc của căn nhà hoặc các thiết bị do Bên A lắp đặt (trừ trường hợp hư hỏng do lỗi của Bên B).
5. Thông báo trước cho Bên B một khoảng thời gian hợp lý (ví dụ: 07 ngày) nếu có kế hoạch sửa chữa lớn hoặc các thay đổi ảnh hưởng đến việc sử dụng phòng của Bên B.

**II. TRÁCH NHIỆM CỦA BÊN B (BÊN THUÊ):**
1. Thanh toán tiền thuê phòng và các chi phí dịch vụ khác (nếu có) đầy đủ và đúng hạn theo thỏa thuận.
2. Sử dụng phòng trọ đúng mục đích thuê (để ở), giữ gìn vệ sinh chung và tài sản trong phòng. Không tự ý sửa chữa, thay đổi kết cấu phòng khi chưa có sự đồng ý của Bên A.
3. Chịu trách nhiệm đối với những hư hỏng tài sản trong phòng do lỗi của mình gây ra.
4. Chấp hành các quy định về an ninh trật tự, phòng cháy chữa cháy của khu vực và nội quy nhà trọ (nếu có). Không tàng trữ, sử dụng các chất cấm, chất cháy nổ.
5. Không cho người khác thuê lại hoặc chuyển nhượng hợp đồng thuê khi chưa có sự đồng ý bằng văn bản của Bên A. Bàn giao lại phòng và các trang thiết bị (nếu có) cho Bên A khi hết hạn hợp đồng hoặc chấm dứt hợp đồng trước thời hạn theo đúng hiện trạng ban đầu (có tính hao mòn tự nhiên).

**III. ĐIỀU KHOẢN CHUNG:**
1. Mọi sửa đổi, bổ sung điều khoản của hợp đồng này phải được hai bên thỏa thuận bằng văn bản.
2. Hợp đồng này được lập thành 02 bản, mỗi bên giữ 01 bản và có giá trị pháp lý như nhau.
3. Hợp đồng có hiệu lực kể từ ngày ký.
""";
  // ContractStatus _status; // Sẽ được xác định tự động
  ContractDuration _selectedDuration = ContractDuration.sixMonths;
  DepositOption _selectedDepositOption = DepositOption.extend48h; // Mặc định là chờ

  late TextEditingController _termsController;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _termsController = TextEditingController(text: _defaultTermsAndConditions);
    _loadTenantRequests();
  }

  DateTime _calculateEndDate(DateTime startDate, ContractDuration duration) {
    int monthsToAdd = duration == ContractDuration.sixMonths ? 6 : 12;
    var newMonth = startDate.month + monthsToAdd;
    var newYear = startDate.year;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    var day = startDate.day;
    var daysInTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (day > daysInTargetMonth) {
      day = daysInTargetMonth;
    }
    return DateTime(newYear, newMonth, day, startDate.hour, startDate.minute, startDate.second);
  }

  Future<void> _loadTenantRequests() async {
    if (!mounted) return;
    try {
      final loadedRequests = await _requestService.getTenantRequestsForRoom(widget.roomId);
      
      if (!mounted) return;
      setState(() {
        _tenantRequests = loadedRequests;
        if (_tenantRequests.isNotEmpty) {
          _selectedTenantId = _tenantRequests.first['user_khach_id'];
        } else {
          _selectedTenantId = null;
        }
      });
    } catch (e) {
      print("Lỗi khi tải danh sách yêu cầu: ${e.toString()}");
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi tải danh sách yêu cầu thuê phòng.')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (_selectedTenantId == null || _selectedTenantId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn người thuê')),
        );
      }
      return;
    }

    final DateTime finalEndDate = _calculateEndDate(_startDate, _selectedDuration);
    final String generatedContractId = FirebaseFirestore.instance.collection('contracts').doc().id;

    // Xác định trạng thái hợp đồng dựa trên lựa chọn đóng cọc
    ContractStatus contractStatus;
    if (_selectedDepositOption == DepositOption.payNow) {
      contractStatus = ContractStatus.active; // Đang hiệu lực
    } else {
      contractStatus = ContractStatus.pending; // Chờ duyệt (chờ đóng cọc)
    }

    try {
      final newContract = ContractModel(
        id: generatedContractId,
        roomId: widget.roomId,
        tenantId: _selectedTenantId!,
        ownerId: widget.ownerId,
        startDate: _startDate,
        endDate: finalEndDate,
        rentAmount: _rentAmount,
        depositAmount: _depositAmount,
        termsAndConditions: _termsController.text,
        status: contractStatus, // Sử dụng trạng thái đã xác định
        paymentHistoryIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _contractService.createContract(newContract);

      // Chỉ cập nhật trạng thái phòng thành 'rented' nếu hợp đồng 'active' (đã đóng cọc)
      // Nếu là 'pending', chủ trọ có thể cần quy trình khác để xác nhận sau khi cọc được thanh toán.
      // Tuy nhiên, để đơn giản, nếu đã tạo hợp đồng thì phòng coi như đã có người giữ chỗ.
      // Nếu bạn muốn logic phức tạp hơn (ví dụ: phòng chỉ rented khi hợp đồng active), bạn cần điều chỉnh.
      
      RoomStatus roomNewStatus = RoomStatus.pending_payment; // Tạo trạng thái mới cho phòng chờ thanh toán
      if (contractStatus == ContractStatus.active) {
        roomNewStatus = RoomStatus.rented;
      }

      await _contractService.updateRoomStatusAfterContract(
        widget.roomId, 
        _selectedTenantId!, 
        roomNewStatus,
      );

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hợp đồng đã được tạo với trạng thái $_selectedTenantId vvvvvvvvv: ${contractStatus.getDisplayName()}')),
        );
        Navigator.pop(context, true);
      }

    } catch (e) {
       print("Lỗi khi tạo hợp đồng: ${e.toString()}");
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tạo hợp đồng: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày bắt đầu hợp đồng',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null && picked != _startDate) {
       if (!mounted) return;
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Xác định trạng thái hợp đồng hiển thị dựa trên lựa chọn đóng cọc
    ContractStatus displayContractStatus = _selectedDepositOption == DepositOption.payNow
        ? ContractStatus.active
        : ContractStatus.pending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Hợp Đồng Thuê Trọ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('ID Phòng:', widget.roomId),
              _buildInfoRow('ID Chủ trọ:', widget.ownerId),
              const SizedBox(height: 20),
              if (_tenantRequests.isEmpty && _selectedTenantId == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator())
                )
              else if (_tenantRequests.isEmpty)
                 Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Không có yêu cầu thuê phòng nào cho phòng này hoặc không tải được danh sách.',
                     style: TextStyle(color: Colors.orange.shade700, fontStyle: FontStyle.italic),
                     textAlign: TextAlign.center,
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedTenantId,
                  decoration: const InputDecoration(
                    labelText: 'Người thuê',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: _tenantRequests.map((request) {
                    return DropdownMenuItem<String>(
                      value: request['user_khach_id'],
                      child: Text(request['Name'] ?? 'Không có tên'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      if (!mounted) return;
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
                  hint: const Text('Chọn người đã yêu cầu thuê phòng'),
                ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Ngày bắt đầu',
                date: _startDate,
                onTap: () => _selectStartDate(context),
              ),
              const SizedBox(height: 20),
              Text("Thời hạn hợp đồng:", style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<ContractDuration>(
                      title: const Text('6 tháng'),
                      value: ContractDuration.sixMonths,
                      groupValue: _selectedDuration,
                      onChanged: (ContractDuration? value) {
                        if (value != null) {
                           if (!mounted) return;
                          setState(() {
                            _selectedDuration = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ContractDuration>(
                      title: const Text('12 tháng'),
                      value: ContractDuration.twelveMonths,
                      groupValue: _selectedDuration,
                      onChanged: (ContractDuration? value) {
                        if (value != null) {
                           if (!mounted) return;
                          setState(() {
                            _selectedDuration = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Text("Ngày kết thúc (dự kiến): ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('dd/MM/yyyy').format(_calculateEndDate(_startDate, _selectedDuration))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField( // Tiền thuê
                decoration: const InputDecoration(
                  labelText: 'Số tiền thuê hàng tháng',
                  prefixText: '₫ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on_outlined)
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số tiền thuê';
                  final cleanValue = value.replaceAll(',', '');
                  if (double.tryParse(cleanValue) == null) return 'Số tiền không hợp lệ';
                  if (double.parse(cleanValue) <= 0) return 'Số tiền phải lớn hơn 0';
                  return null;
                },
                onSaved: (value) =>
                    _rentAmount = double.tryParse(value?.replaceAll(',', '') ?? '0') ?? 0.0,
              ),
              const SizedBox(height: 16),
              TextFormField( // Tiền cọc
                decoration: const InputDecoration(
                  labelText: 'Tiền đặt cọc',
                  prefixText: '₫ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security_outlined)
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số tiền cọc';
                  final cleanValue = value.replaceAll(',', '');
                  if (double.tryParse(cleanValue) == null) return 'Số tiền không hợp lệ';
                  if (double.parse(cleanValue) < 0) return 'Số tiền không được âm';
                  if (double.parse(cleanValue) == 0 && _selectedDepositOption == DepositOption.payNow) {
                    // Nếu chọn đóng cọc ngay mà tiền cọc là 0 thì có thể không hợp lý, tùy logic của bạn
                    // return 'Tiền cọc phải lớn hơn 0 nếu đóng ngay';
                  }
                  return null;
                },
                onSaved: (value) =>
                    _depositAmount = double.tryParse(value?.replaceAll(',', '') ?? '0') ?? 0.0,
              ),
              const SizedBox(height: 20),

              // Lựa chọn đóng cọc
              Text("Tình trạng đóng cọc:", style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<DepositOption>(
                      title: const Text('Đóng cọc ngay'),
                      value: DepositOption.payNow,
                      groupValue: _selectedDepositOption,
                      onChanged: (DepositOption? value) {
                        if (value != null) {
                           if (!mounted) return;
                          setState(() {
                            _selectedDepositOption = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<DepositOption>(
                      title: const Text('Gia hạn 48h'), // Hoặc "Chờ đóng cọc"
                      value: DepositOption.extend48h,
                      groupValue: _selectedDepositOption,
                      onChanged: (DepositOption? value) {
                        if (value != null) {
                           if (!mounted) return;
                          setState(() {
                            _selectedDepositOption = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hiển thị trạng thái hợp đồng (chỉ đọc, bị làm mờ)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Trạng thái hợp đồng (tự động)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200], // Làm mờ nền
                  prefixIcon: const Icon(Icons.flag_outlined)
                ),
                child: Text(
                  displayContractStatus.getDisplayName(),
                  style: TextStyle(
                    color: Colors.grey[700], // Làm mờ chữ
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField( // Điều khoản
                controller: _termsController,
                decoration: const InputDecoration(
                  labelText: 'Điều khoản và điều kiện',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.article_outlined)
                ),
                maxLines: 7,
                 validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Điều khoản không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text(
                    'Tạo Hợp Đồng',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: (_tenantRequests.isEmpty && _selectedTenantId == null) || (_tenantRequests.isNotEmpty && _selectedTenantId == null)
                      ? null
                      : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)
                    )
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
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
          prefixIcon: const Icon(Icons.calendar_today_outlined)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(date)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _termsController.dispose();
    super.dispose();
  }
}
// Cần đảm bảo RoomStatus có trạng thái `pending_payment`
// Ví dụ:
// enum RoomStatus { available, rented, maintenance, pending_payment }
// extension RoomStatusExtension on RoomStatus {
//   String toJson() {
//     switch (this) {
//       case RoomStatus.available: return 'available';
//       case RoomStatus.rented: return 'rented';
//       case RoomStatus.maintenance: return 'maintenance';
//       case RoomStatus.pending_payment: return 'pending_payment'; // Thêm case này
//     }
//   }
//   // ... fromJson nếu cần
// }