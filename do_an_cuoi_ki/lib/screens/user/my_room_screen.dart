// File: screens/user/my_room_screen.dart
import 'package:do_an_cuoi_ki/services/contract_service.dart';
import 'package:do_an_cuoi_ki/services/request_service.dart';
import 'package:do_an_cuoi_ki/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/models/room.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/request.dart'; // Cần RequestModel và RequestType
// import 'package:do_an_cuoi_ki/screens/user/bill_list_screen.dart'; // Màn hình xem hóa đơn (tạo sau)
// import 'package:do_an_cuoi_ki/screens/user/contract_detail_screen.dart'; // Màn hình xem chi tiết hợp đồng (tạo sau)
import 'package:intl/intl.dart';

class MyRoomScreen extends StatefulWidget {
  final UserModel? currentUser;

  const MyRoomScreen({super.key, required this.currentUser});

  @override
  State<MyRoomScreen> createState() => _MyRoomScreenState();
}

class _MyRoomScreenState extends State<MyRoomScreen> {
  ContractModel? _activeContract;
  RoomModel? _rentedRoom;
  bool _isLoading = true;
  String _loadingMessage = "Đang tải thông tin trọ của bạn...";

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final ContractService _contractService = ContractService();
  final RoomService _roomService = RoomService();
  final RequestService _requestService = RequestService();

  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null) {
      _fetchRentedRoomInfo();
    } else {
      setState(() {
        _isLoading = false;
        _loadingMessage = "Vui lòng đăng nhập để xem thông tin trọ.";
      });
    }
  }
  
  @override
  void didUpdateWidget(covariant MyRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("MyRoomScreen didUpdateWidget: oldUser: ${oldWidget.currentUser?.email}, newUser: ${widget.currentUser?.email}"); // Log
    if (widget.currentUser != oldWidget.currentUser) { // Kiểm tra xem currentUser có thực sự thay đổi không
      if (widget.currentUser != null) {
        _fetchRentedRoomInfo(); // Tải lại thông tin nếu user thay đổi và không null
      } else {
        // Người dùng đã đăng xuất từ tab khác
        if (mounted) {
          setState(() {
            _isLoading = false;
            _activeContract = null;
            _rentedRoom = null;
            _loadingMessage = "Vui lòng đăng nhập để xem thông tin trọ.";
          });
        }
      }
    }
  }

  Future<void> _fetchRentedRoomInfo() async {
    if (widget.currentUser == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Đang tìm kiếm phòng bạn đang thuê...";
    });

    try {
      _activeContract = await _contractService.getActiveContractForTenant(widget.currentUser!.id);

      if (_activeContract != null && _activeContract!.roomId.isNotEmpty) {
        _rentedRoom = await _roomService.getRoomById1(_activeContract!.roomId);
        if (_rentedRoom == null) {
          _loadingMessage = "Không tìm thấy thông tin phòng trọ liên kết với hợp đồng của bạn.";
        }
      } else {
        _loadingMessage = "Bạn hiện không thuê phòng nào (không có hợp đồng đang hiệu lực).";
      }
    } catch (e) {
      print("Lỗi khi tải thông tin trọ: $e");
      _loadingMessage = "Đã xảy ra lỗi khi tải thông tin.";
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateRequestDialog(RequestType initialType) {
    if (widget.currentUser == null || _rentedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tạo yêu cầu. Thiếu thông tin người dùng hoặc phòng.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    RequestType selectedType = initialType;
    final TextEditingController moTaController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text('Tạo yêu cầu ${initialType == RequestType.suaChua ? "Sửa chữa" : "Trả phòng"}'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Không cần dropdown vì type đã được xác định
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Phòng: ${_rentedRoom!.title}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextFormField(
                      controller: moTaController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả chi tiết yêu cầu',
                        border: const OutlineInputBorder(),
                        hintText: initialType == RequestType.suaChua
                            ? "Ví dụ: Vòi nước bị rò rỉ, đèn không sáng..."
                            : "Ví dụ: Lý do trả phòng, ngày dự kiến trả...",
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Vui lòng nhập mô tả' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final request = RequestModel(
                        id: FirebaseFirestore.instance.collection('requests').doc().id,
                        loaiRequest: selectedType,
                        moTa: moTaController.text.trim(),
                        roomId: _rentedRoom!.id,
                        userKhachId: widget.currentUser!.id,
                        thoiGian: DateTime.now(),
                        sdt: widget.currentUser!.phoneNumber ?? 'N/A',
                        Name: widget.currentUser!.name,
                      );

                      try {
                        await _requestService.createRequest(request);
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gửi yêu cầu thành công!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi gửi yêu cầu: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Gửi'),
                ),
              ],
            );
          }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Vui lòng đăng nhập để quản lý thông tin trọ của bạn.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(_loadingMessage),
          ],
        ),
      );
    }

    if (_rentedRoom == null || _activeContract == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _loadingMessage, // Hiển thị thông báo lỗi hoặc không tìm thấy phòng
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    // Nếu có thông tin phòng và hợp đồng
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trọ của tôi"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Xin chào, ${widget.currentUser!.name}!", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Thông tin phòng
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thông tin phòng đang thuê", style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    Text("Tên phòng: ${_rentedRoom!.title}", style: const TextStyle(fontSize: 16)),
                    Text("Địa chỉ: ${_rentedRoom!.address}", style: const TextStyle(fontSize: 16)),
                    Text("Giá thuê: ${NumberFormat("#,##0", "vi_VN").format(_rentedRoom!.price)} VNĐ/tháng", style: const TextStyle(fontSize: 16)),
                    // Thêm các thông tin phòng khác nếu cần
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin hợp đồng
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thông tin hợp đồng", style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    Text("Ngày bắt đầu: ${_dateFormat.format(_activeContract!.startDate)}", style: const TextStyle(fontSize: 16)),
                    Text("Ngày kết thúc: ${_dateFormat.format(_activeContract!.endDate)}", style: const TextStyle(fontSize: 16)),
                    Text("Tiền cọc: ${NumberFormat("#,##0", "vi_VN").format(_activeContract!.depositAmount)} VNĐ", style: const TextStyle(fontSize: 16)),
                    Text("Trạng thái: ${_activeContract!.status.getDisplayName()}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Điều hướng đến màn hình chi tiết hợp đồng
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xem chi tiết hợp đồng (chưa làm)")));
                        },
                        child: const Text("Xem chi tiết"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hóa đơn (phần này cần query riêng)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text("Hóa đơn", style: Theme.of(context).textTheme.titleLarge),
                     const Divider(),
                     const Text("Danh sách hóa đơn sẽ được hiển thị ở đây.", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                     const SizedBox(height: 8),
                     Align(
                      alignment: Alignment.centerRight,
                       child: TextButton(
                        onPressed: () {
                          // TODO: Điều hướng đến màn hình danh sách hóa đơn
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xem tất cả hóa đơn (chưa làm)")));
                        },
                        child: const Text("Xem tất cả hóa đơn"),
                                           ),
                     ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút tạo yêu cầu
            Text("Yêu cầu dịch vụ", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.build_circle_outlined),
                  label: const Text("Sửa chữa"),
                  onPressed: () {
                    _showCreateRequestDialog(RequestType.suaChua);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text("Trả phòng"),
                  onPressed: () {
                     _showCreateRequestDialog(RequestType.traPhong);
                  },
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}