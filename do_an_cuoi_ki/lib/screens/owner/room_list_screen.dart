// File: screens/owner/room_list_screen.dart (Hoặc tên file của bạn)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart'; // Model User của bạn
import 'package:do_an_cuoi_ki/screens/owner/lap_hop_dong.dart';
import 'package:do_an_cuoi_ki/screens/owner/sua_chua.dart';
import 'package:do_an_cuoi_ki/screens/owner/sua_chua_2.dart'; 
import 'package:do_an_cuoi_ki/screens/owner/thanh_ly_hop_dong.dart';
// import 'package:do_an_cuoi_ki/screens/owner/quan_ly_phieu_sua_chua_screen.dart'; // Import màn hình quản lý phiếu sửa chữa
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_cuoi_ki/models/request.dart'; // <<=== IMPORT REQUEST MODEL
import 'package:intl/intl.dart'; // Để format DateTime nếu cần

class RoomListScreen extends StatelessWidget {
  final String buildingId;
  final String ownerID; // Giữ nguyên tên biến ownerID
  final UserModel currentUser;
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
  const RoomListScreen({super.key, required this.buildingId, required this.ownerID, required this.currentUser});

  
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

  const RoomListScreen({
    super.key,
    required this.buildingId,
    required this.ownerID,
    required this.currentUser,
  });
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

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
            // .where('ownerId', isEqualTo: ownerID) // Thêm điều kiện này nếu cần thiết và có trường ownerId trong room
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Lỗi StreamBuilder (RoomListScreen): ${snapshot.error}");
            return Center(child: Text("Lỗi tải danh sách phòng: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có phòng nào trong tòa nhà này."));
          }

          final rooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final roomDoc = rooms[index]; // Đây là QueryDocumentSnapshot
              final data = roomDoc.data() as Map<String, dynamic>; // Dữ liệu của phòng

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: (data['imageUrls'] as List<dynamic>?)?.isNotEmpty == true
                              ? data['imageUrls'][0] as String
                              : '', // URL ảnh mặc định hoặc xử lý khác
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded( // Cho Text tiêu đề co giãn
                                  child: Text(
                                    data['title'] ?? 'Phòng không tên',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Không dùng Positioned ở đây, StreamBuilder sẽ tự điều chỉnh
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('requests')
                                      .where('room_id', isEqualTo: roomDoc.id) // Sử dụng roomDoc.id
                                      // Thêm điều kiện lọc request chưa xử lý nếu cần
                                      // .where('statusRequest', isEqualTo: 'pending')
                                      .snapshots(),
                                  builder: (context, requestSnapshot) { // Đổi tên snapshot để tránh nhầm lẫn
                                    if (requestSnapshot.connectionState == ConnectionState.waiting) {
                                      return const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2,));
                                    }
                                    int requestCount = requestSnapshot.data?.docs.length ?? 0;

                                    return GestureDetector(
                                      onTap: () {
                                        if (requestSnapshot.hasData && requestSnapshot.data!.docs.isNotEmpty) {
                                          showDialog(
                                            context: context,
                                            // Truyền trực tiếp danh sách các DocumentSnapshot
                                            builder: (context) => RequestDialog(requestSnapshot.data!.docs),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Không có yêu cầu nào cho phòng này.')),
                                          );
                                        }
                                      },
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          Icon(
                                            requestCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                                            color: requestCount > 0 ? Colors.red.shade600 : Colors.grey.shade600,
                                            size: 30,
                                          ),
                                          if (requestCount > 0)
                                            Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle, // Bo tròn hơn
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 18,
                                                minHeight: 18,
                                              ),
                                              child: Text(
                                                '$requestCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11, // Giảm font một chút
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Giá: ${data['price'] ?? 'N/A'} VNĐ / tháng"),
                            const SizedBox(height: 4),
                            Text("Diện tích: ${data['area'] ?? 'N/A'} m²"),
                            const SizedBox(height: 4),
                            Text("Sức chứa: ${data['capacity'] ?? 'N/A'} người"),
                            const SizedBox(height: 4),
                            Text("Trạng thái: ${data['status'] ?? 'N/A'}"),
                            const SizedBox(height: 12),
                            Wrap( // Sử dụng Wrap để các nút tự xuống dòng nếu không đủ chỗ
                              spacing: 8.0, // Khoảng cách ngang
                              runSpacing: 8.0, // Khoảng cách dọc
                              alignment: WrapAlignment.spaceBetween, // Căn đều nếu có không gian
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.description_outlined, size: 18),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (data['status'] == 'rented')
                                        ? Colors.grey.shade400
                                        : Colors.blue.shade600,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onPressed: (data['status'] == 'rented')
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ContractFormPage(
                                                roomId: roomDoc.id, // Sử dụng roomDoc.id
                                                ownerId: ownerID,
                                              ),
                                            ),
                                          );
                                        },
                                  label: const Text('Lập HĐ'),
                                ),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.receipt_long_outlined, size: 18),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ThanhLyHopDong(
                                          currentUser: currentUser,
                                          roomId: roomDoc.id, // Sử dụng roomDoc.id
                                        ),
                                      ),
                                    );
                                  },
                                  label: const Text('Thanh Lý'),
                                ),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.build_outlined, size: 18),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade600,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuanLyPhieuSuaChuaScreen(
                                          roomId: roomDoc.id, // Sử dụng roomDoc.id
                                        ),
                                      ),
                                    );
                                  },
                                  label: const Text('Sửa Chữa'),
                                ),
                                // Các IconButton có thể gộp thành một PopupMenuButton nếu nhiều
                                IconButton(
                                  icon: const Icon(Icons.edit_note_outlined, color: Colors.teal),
                                  tooltip: "Chỉnh sửa phòng",
                                  onPressed: () {
                                    // TODO: Chuyển sang trang chỉnh sửa phòng
                                    print("Edit room: ${roomDoc.id}");
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                                  tooltip: "Xóa phòng",
                                  onPressed: () async {
                                    final confirmDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext dialogContext) => AlertDialog(
                                        title: const Text('Xác nhận xóa'),
                                        content: Text('Bạn có chắc chắn muốn xóa phòng "${data['title'] ?? roomDoc.id}" không? Hành động này không thể hoàn tác.'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Hủy'),
                                            onPressed: () => Navigator.of(dialogContext).pop(false),
                                          ),
                                          TextButton(
                                            child: const Text('XÓA', style: TextStyle(color: Colors.red)),
                                            onPressed: () => Navigator.of(dialogContext).pop(true),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmDelete == true) {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('rooms')
                                            .doc(roomDoc.id)
                                            .delete();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Đã xóa phòng: ${data['title'] ?? roomDoc.id}')),
                                        );
                                      } catch (e) {
                                         ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Lỗi khi xóa phòng: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
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

class RequestDialog extends StatelessWidget {
  final List<QueryDocumentSnapshot> requestDocs;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm'); // Di chuyển DateFormat ra ngoài để tái sử dụng

  RequestDialog(this.requestDocs, {super.key}); // Sửa constructor

  Future<void> deleteRequestById(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .delete();
      debugPrint("Request có ID '$requestId' đã được xóa thành công.");
    } catch (e) {
      debugPrint("Lỗi khi xóa request: $e");
      // Có thể throw lỗi lại để UI xử lý nếu cần
    }
  }

  // Hàm helper để lấy tên phòng (nếu bạn muốn hiển thị trong dialog)
  Future<String> _getRoomTitleForRequest(String roomId) async {
    if (roomId.isEmpty) return "Không rõ phòng";
    try {
      final doc = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['title'] as String? ?? 'Phòng không tên';
      }
    } catch (e) {
      print("Lỗi khi lấy tên phòng cho request: $e");
    }
    return "Phòng ID: $roomId";
  }


  @override
  Widget build(BuildContext context) {
    // Không cần localDocs và StatefulBuilder nếu không có logic thay đổi danh sách bên trong dialog này nữa
    // Nếu có logic xóa item ngay trong dialog thì vẫn cần StatefulBuilder và localDocs

    return AlertDialog(
      title: const Text('Danh sách yêu cầu'),
      contentPadding: const EdgeInsets.fromLTRB(12.0, 20.0, 12.0, 0), // Điều chỉnh padding
      content: SizedBox(
        width: double.maxFinite,
        child: requestDocs.isEmpty
            ? const Center(child: Text("Không có yêu cầu nào."))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: requestDocs.length,
                itemBuilder: (context, index) {
                  final requestDocData = requestDocs[index].data() as Map<String, dynamic>;
                  // TÁI SỬ DỤNG RequestModel.fromJson
                  RequestModel request;
                  try {
                    // Đảm bảo ID của document được gán vào model nếu fromJson không tự xử lý
                    Map<String, dynamic> dataWithId = Map.from(requestDocData);
                    if (!dataWithId.containsKey('id') || (dataWithId['id'] == null || (dataWithId['id'] as String).isEmpty)) {
                       dataWithId['id'] = requestDocs[index].id;
                    }
                    request = RequestModel.fromJson(dataWithId);
                  } catch (e,s) {
                    print("Lỗi parse RequestModel trong Dialog: $e. Data: $requestDocData");
                    print("Stack trace: $s");
                    return ListTile(
                      leading: Icon(Icons.error, color: Colors.red),
                      title: Text("Lỗi dữ liệu yêu cầu"),
                      subtitle: Text("ID: ${requestDocs[index].id}"),
                    );
                  }

                  final isSuaChua = request.loaiRequest == RequestType.suaChua;

                  return Card( // Bọc mỗi item bằng Card cho đẹp hơn
                    margin: const EdgeInsets.only(bottom: 8.0),
                    elevation: 1,
                    child: ListTile(
                      leading: Icon(
                        request.loaiRequest == RequestType.thuePhong ? Icons.vpn_key_outlined :
                        request.loaiRequest == RequestType.traPhong ? Icons.logout_outlined :
                        Icons.build_circle_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(request.loaiRequest.getDisplayName(), style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Người gửi: ${request.Name}"),
                          Text("SĐT: ${request.sdt}"),
                          Text("Mô tả: ${request.moTa}"),
                          Text(
                            'Lúc: ${_dateFormat.format(request.thoiGian)}', // Sử dụng thuộc tính thoiGian từ RequestModel
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          // Bạn có thể thêm FutureBuilder để hiển thị tên phòng nếu cần
                          // FutureBuilder<String>(
                          //   future: _getRoomTitleForRequest(request.roomId),
                          //   builder: (context, roomSnapshot) {
                          //     return Text("Phòng: ${roomSnapshot.data ?? 'Đang tải...'}");
                          //   },
                          // ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSuaChua)
                            Tooltip(
                              message: "Xử lý sửa chữa",
                              child: IconButton(
                                icon: const Icon(Icons.construction, color: Colors.orange),
                                onPressed: () {
                                    Navigator.pop(context); // Đóng dialog hiện tại
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SuaChua( // Đảm bảo SuaChua là một widget
                                          roomId: request.roomId,
                                          tenantId: request.userKhachId,
                                          // requestId: request.id, // Có thể truyền requestId để cập nhật
                                        ),
                                      ),
                                    );
                                },
                              ),
                            ),
                          Tooltip(
                            message: "Xóa yêu cầu",
                            child: IconButton(
                              icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: const Text('Bạn có chắc muốn xóa yêu cầu này không?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await deleteRequestById(request.id); // Sử dụng request.id từ model
                                  // Không cần setState ở đây nếu RequestDialog là StatelessWidget
                                  // và bạn muốn dialog tự đóng hoặc danh sách làm mới từ StreamBuilder cha.
                                  // Nếu muốn cập nhật ngay lập tức trong dialog mà không đóng,
                                  // RequestDialog cần là StatefulWidget và bạn sẽ gọi setState.
                                  // Tạm thời, giả sử dialog sẽ đóng và danh sách bên ngoài tự cập nhật.
                                   Navigator.pop(context); // Đóng dialog sau khi xóa
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã xóa yêu cầu của ${request.Name}')),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}