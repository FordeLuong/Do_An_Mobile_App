// File: screens/user/room_list_screen_user.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// SỬA IMPORT: Đảm bảo import đúng RequestModel và các hàm liên quan
import 'package:do_an_cuoi_ki/models/request.dart'; // Đổi từ request.dart thành request_model.dart
import 'package:do_an_cuoi_ki/services/request_service.dart';
import 'package:do_an_cuoi_ki/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_cuoi_ki/screens/user/room_detail_screen.dart';
import 'package:do_an_cuoi_ki/models/room.dart';
import 'package:intl/intl.dart';

// Helper extension để format tên RequestType (tùy chọn, bạn có thể đặt ở file chung)
// Bạn có thể đã có extension này trong request_model.dart, nếu vậy không cần định nghĩa lại ở đây
// extension StringFormattingExtension on String {
//   String capitalizeFirstLetterPerWord() {
//     if (isEmpty) return this;
//     return split(' ').map((word) {
//       if (word.isEmpty) return '';
//       if (word.length == 1) return word.toUpperCase();
//       return word[0].toUpperCase() + word.substring(1).toLowerCase();
//     }).join(' ');
//   }
// }


class RoomListScreen_User extends StatefulWidget { // Chuyển thành StatefulWidget
  final String buildingId;
  final String userId;
  final String sdt;
  final String userName;

  const RoomListScreen_User({
    super.key,
    required this.buildingId,
    required this.userId,
    required this.sdt,
    required this.userName,
  });

  @override
  State<RoomListScreen_User> createState() => _RoomListScreen_UserState();
}

class _RoomListScreen_UserState extends State<RoomListScreen_User> {
  bool _isCurrentlyRenting = false;
  bool _isLoadingRentingStatus = true;
  RoomService _roomService= RoomService();
  RequestService _requestService= RequestService();
  @override
  void initState() {
    super.initState();
    _checkRentingStatus();
  }

  Future<void> _checkRentingStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRentingStatus = true;
    });
    bool renting = await _roomService.checkIfUserIsCurrentlyRenting(widget.userId);
    if (mounted) {
      setState(() {
        _isCurrentlyRenting = renting;
        _isLoadingRentingStatus = false;
      });
    }
  }


  void showCreateRequestDialog(
    BuildContext context,
    String selectedRoomId,
    String userIdOfRequester,
    String userSdtForRequest,
    String userNameForRequest,
  ) async {
    // Kiểm tra lại ở đây như một lớp bảo vệ thứ hai
    if (_isCurrentlyRenting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đang thuê một phòng. Không thể gửi thêm yêu cầu.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    // Không cần gọi lại checkIfUserIsCurrentlyRenting ở đây nữa vì đã kiểm tra ở trên
    // và _isCurrentlyRenting đã có giá trị.

    List<RequestType> availableRequestTypes;
    RequestType? defaultSelectedType;

    // Vì đã có kiểm tra _isCurrentlyRenting ở ngoài, logic này sẽ luôn rơi vào trường hợp 'else'
    // Tuy nhiên, để code rõ ràng và phòng trường hợp, ta vẫn giữ nó.
    // Nhưng thực tế, nếu _isCurrentlyRenting là true, hàm này sẽ không được gọi.
    if (_isCurrentlyRenting) { // Logic này sẽ không bao giờ được thực thi nếu kiểm tra bên ngoài hoạt động đúng
      availableRequestTypes = []; // Không có request nào được phép
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Lỗi: Bạn không nên thấy dialog này nếu đang thuê phòng.')),
      );
      return; // Thoát sớm
    } else {
      // Nếu chưa thuê phòng, chỉ có thể yêu cầu thuê phòng
      availableRequestTypes = [RequestType.thuePhong];
      defaultSelectedType = RequestType.thuePhong;
    }

    // Nếu không có loại request nào khả dụng (dù trường hợp này khó xảy ra với logic hiện tại)
    if (availableRequestTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hiện không có loại yêu cầu nào phù hợp.')),
      );
      return;
    }


    RequestType selectedType = defaultSelectedType!; // Chắc chắn không null vì availableRequestTypes không rỗng
    final TextEditingController moTaController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Tạo yêu cầu mới'),
              contentPadding: const EdgeInsets.all(16.0),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<RequestType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại yêu cầu',
                        border: OutlineInputBorder(),
                      ),
                      items: availableRequestTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.getDisplayName()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedType = value;
                          });
                        }
                      },
                      validator: (value) => value == null ? 'Vui lòng chọn loại yêu cầu' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: moTaController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả yêu cầu',
                        border: OutlineInputBorder(),
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
                        roomId: selectedRoomId,
                        userKhachId: userIdOfRequester,
                        thoiGian: DateTime.now(),
                        sdt: userSdtForRequest,
                        Name: userNameForRequest,
                      );

                      try {
                        await _requestService.createRequest(request);

                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gửi yêu cầu thành công')),
                        );
                      } catch (e) {
                         if (Navigator.canPop(dialogContext)) { // Kiểm tra trước khi pop lần nữa
                           Navigator.pop(dialogContext);
                         }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi gửi yêu cầu: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Gửi yêu cầu'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách phòng"),
        backgroundColor: Colors.green.shade800,
      ),
      body: _isLoadingRentingStatus
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green)))
          : StreamBuilder<QuerySnapshot>(
        stream: _roomService.getAvailableRoomsByBuildingId(widget.buildingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isLoadingRentingStatus) { // Chỉ hiện loading của stream nếu không phải loading ban đầu
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có phòng nào trống trong tòa nhà này."));
          }

          final roomsDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.7, // Điều chỉnh tỷ lệ này nếu cần
            ),
            itemCount: roomsDocs.length,
            itemBuilder: (context, index) {
              final roomDoc = roomsDocs[index];
              final data = roomDoc.data() as Map<String, dynamic>;

              final RoomModel currentRoom;
              try {
                Map<String, dynamic> roomDataWithId = Map.from(data);
                roomDataWithId['id'] = roomDoc.id;
                currentRoom = RoomModel.fromJson(roomDataWithId);
              } catch (e, s) {
                print("Lỗi khi parse RoomModel: $e. Dữ liệu: $data, ID: ${roomDoc.id}");
                print("Stack trace: $s");
                return Card(child: Center(child: Text("Lỗi dữ liệu phòng")));
              }

              String imageUrl = currentRoom.imageUrls.isNotEmpty ? currentRoom.imageUrls[0] : '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomDetailScreen(
                        room: currentRoom,
                        userId: widget.userId, // Sửa: widget.userId
                        userSdt: widget.sdt,   // Sửa: widget.sdt
                        userName: widget.userName, // Sửa: widget.userName
                      ),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
                                ),
                              )
                            : Container( // Placeholder nếu không có ảnh
                                color: Colors.grey[200],
                                child: Icon(Icons.apartment, color: Colors.grey[400], size: 50),
                              ),
                      ),
                      Expanded(
                        flex: 4, // Tăng flex để có thêm không gian cho text và button
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Để button đẩy xuống dưới
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentRoom.title,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${NumberFormat("#,##0", "vi_VN").format(currentRoom.price)} VNĐ/tháng",
                                    style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Diện tích: ${currentRoom.area.toStringAsFixed(1)} m²",
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isCurrentlyRenting ? Colors.grey.shade400 : Colors.amber.shade700, // Vô hiệu hóa màu nếu đang thuê
                                    foregroundColor: _isCurrentlyRenting ? Colors.white : Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _isCurrentlyRenting
                                    ? () { // Hành động khi nút bị "vô hiệu hóa" (thực ra là có onPressed khác)
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Bạn đang thuê một phòng. Không thể gửi thêm yêu cầu.')),
                                        );
                                      }
                                    : () { // Hành động khi có thể gửi yêu cầu
                                        showCreateRequestDialog(context, currentRoom.id, widget.userId, widget.sdt, widget.userName);
                                      },
                                  child: Text(_isCurrentlyRenting ? 'Đã thuê phòng' : 'Gửi yêu cầu'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}