// File: screens/user/room_list_screen_user.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// SỬA IMPORT: Đảm bảo import đúng RequestModel và hàm checkIfUserIsCurrentlyRenting
import 'package:do_an_cuoi_ki/models/request.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_cuoi_ki/screens/user/room_detail_screen.dart';
import 'package:do_an_cuoi_ki/models/room.dart';

// Helper extension để format tên RequestType (tùy chọn, bạn có thể đặt ở file chung)
extension StringFormattingExtension on String {
  String capitalizeFirstLetterPerWord() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return '';
      // Xử lý trường hợp từ có thể là '' sau khi split
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}


class RoomListScreen_User extends StatelessWidget {
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

  // Hàm hiển thị dialog tạo yêu cầu đã được cập nhật
  void showCreateRequestDialog(
    BuildContext context,
    String selectedRoomId,
    String userIdOfRequester,
    // Thêm sdt và userName làm tham số vì hàm này là static method của StatelessWidget
    // Hoặc bạn có thể truy cập trực tiếp this.sdt, this.userName nếu hàm này không phải static
    // Tuy nhiên, vì nó được gọi từ bên trong builder, việc truyền rõ ràng là tốt hơn.
    String userSdtForRequest,
    String userNameForRequest,
  ) async { // Thêm async
    final formKey = GlobalKey<FormState>();

    // Gọi hàm kiểm tra từ request_model.dart
    bool isCurrentlyRenting = await checkIfUserIsCurrentlyRenting(userIdOfRequester);

    List<RequestType> availableRequestTypes;
    RequestType? defaultSelectedType;

    if (isCurrentlyRenting) {
      // Nếu đang thuê phòng, có thể trả phòng hoặc sửa chữa
      // Nếu logic cho phép thuê nhiều phòng, bạn có thể thêm RequestType.thuePhong ở đây
      availableRequestTypes = [
        RequestType.traPhong,
        RequestType.suaChua,
      ];
      defaultSelectedType = RequestType.suaChua;
    } else {
      // Nếu chưa thuê phòng, chỉ có thể yêu cầu thuê phòng
      availableRequestTypes = [RequestType.thuePhong];
      defaultSelectedType = RequestType.thuePhong;
    }

    RequestType selectedType = defaultSelectedType;
    final TextEditingController moTaController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder( // Sử dụng StatefulBuilder để cập nhật Dropdown
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
                          // Sử dụng getDisplayName từ RequestTypeExtension
                          child: Text(type.getDisplayName()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() { // Cập nhật state của dialog
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
                        sdt: userSdtForRequest,   // Sử dụng tham số truyền vào
                        Name: userNameForRequest, // Sử dụng tham số truyền vào
                      );

                      try {
                        await FirebaseFirestore.instance
                            .collection('requests')
                            .doc(request.id)
                            .set(request.toJson());

                        Navigator.pop(dialogContext);
                        // mounted check không cần thiết ở đây vì context của ScaffoldMessenger là context gốc
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gửi yêu cầu thành công')),
                        );
                      } catch (e) {
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .where('buildingId', isEqualTo: buildingId)
            .where('status', isEqualTo: RoomStatus.available.toJson()) // Lấy phòng còn trống
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có phòng nào trống."));
          }

          final roomsDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.7,
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

              String imageUrl = '';
              // Lấy ảnh từ currentRoom đã được parse thay vì data trực tiếp
              if (currentRoom.imageUrls.isNotEmpty) {
                imageUrl = currentRoom.imageUrls[0];
              }

              return GestureDetector(
                onTap: () {
                  print("Card tapped! Room ID: ${currentRoom.id}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomDetailScreen(
                        room: currentRoom,
                        userId: userId,
                        userSdt: sdt,
                        userName: userName,
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
                        child: CachedNetworkImage(
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
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    "${currentRoom.price.toStringAsFixed(0)} VNĐ/tháng",
                                    style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Diện tích: ${currentRoom.area.toStringAsFixed(1)} m²",
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Truyền sdt và userName của class vào hàm
                                    showCreateRequestDialog(context, currentRoom.id, userId, sdt, userName);
                                  },
                                  child: const Text('Liên hệ'),
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