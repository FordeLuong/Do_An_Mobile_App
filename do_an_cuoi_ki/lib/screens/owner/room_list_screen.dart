import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/screens/owner/lap_hop_dong.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RoomListScreen extends StatelessWidget {
  final String buildingId;
  final ownerID;
  const RoomListScreen({super.key, required this.buildingId, required this.ownerID});

  




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
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có phòng nào."));
          }

          final rooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final data = rooms[index].data() as Map<String, dynamic>;

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
                          imageUrl: data['imageUrls']?[0] ?? '',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                    Text(
                                      data['title'] ?? 'Phòng không tên',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Positioned(
                                                top: 8,
                                                right: 8,
                                                child: StreamBuilder<QuerySnapshot>(
                                                  stream: FirebaseFirestore.instance
                                                      .collection('requests')
                                                      .where('room_id', isEqualTo: rooms[index].id)
                                                      .snapshots(),
                                                  builder: (context, snapshot) {
                                                    int requestCount = snapshot.data?.docs.length ?? 0;

                                                    return GestureDetector(
                                                      onTap: () {
                                                        if (requestCount > 0) {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => RequestDialog(snapshot.data!.docs),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Không có yêu cầu nào.')),
                                                          );
                                                        }
                                                      },
                                                      child: Stack(
                                                        alignment: Alignment.topRight,
                                                        children: [
                                                          Icon(
                                                            requestCount > 0 ? Icons.notifications_active : Icons.notifications_none,
                                                            color: requestCount > 0 ? Colors.red : Colors.grey,
                                                            size: 28,
                                                          ),
                                                          if (requestCount > 0)
                                                            Container(
                                                              padding: const EdgeInsets.all(2),
                                                              decoration: BoxDecoration(
                                                                color: Colors.redAccent,
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              constraints: const BoxConstraints(
                                                                minWidth: 18,
                                                                minHeight: 18,
                                                              ),
                                                              child: Text(
                                                                '$requestCount',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 12,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            Text("Giá: ${data['price']} VNĐ / tháng"),
                            const SizedBox(height: 4),
                            Text("Diện tích: ${data['area']} m²"),
                            const SizedBox(height: 4),
                            Text("Sức chứa: ${data['capacity']} người"),
                            const SizedBox(height: 4),
                            Text("Trạng thái: ${data['status']}"),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: data['status'] == 'rented' ? Colors.grey : Colors.amber,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  onPressed: data['status'] == 'rented' 
                                      ? null 
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ContractFormPage(
                                                roomId: rooms[index].id,
                                                ownerId: ownerID,
                                              ),
                                            ),
                                          );
                                        },
                                  child: Text('Lập hợp đồng'),
                                ),
                                ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () {
                                        // xử lý đặt lịch
                                        
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder: (_) => CreateRoomPage(buildingId: buildings[index].id),
                                        //   ),
                                        // );
                                      },
                                      
                                      child: Text('Thanh lý'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    // Chuyển sang trang chỉnh sửa phòng nếu cần
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    // Xử lý xóa phòng
                                    FirebaseFirestore.instance
                                        .collection('rooms')
                                        .doc(rooms[index].id)
                                        .delete();
                                  },
                                ),
                                
                              ],
                            )
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

  const RequestDialog(this.requestDocs, {super.key});

  Future<void> deleteRequestById(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .delete();
      debugPrint("Request có ID '$requestId' đã được xóa thành công.");
    } catch (e) {
      debugPrint("Lỗi khi xóa request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<QueryDocumentSnapshot> localDocs = List.from(requestDocs); // Danh sách tạm

    return AlertDialog(
      title: const Text('Danh sách yêu cầu'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: localDocs.length,
              itemBuilder: (context, index) {
                final data = localDocs[index].data() as Map<String, dynamic>;
                final name= data['Name'] ?? '';
                final loai = data['loai_request'] ?? 'Không rõ';
                final moTa = data['mo_ta'] ?? '';
                final thoiGian = data['thoi_gian'] != null
                    ? DateTime.parse(data['thoi_gian']).toLocal()
                    : null;
                final sdt=data['sdt'];
                return ListTile(
                  leading: const Icon(Icons.assignment),
                  title: Text(loai),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name),
                      Text(moTa),
                      if (thoiGian != null)
                        Text(
                          'Lúc: ${thoiGian.day}/${thoiGian.month}/${thoiGian.year} ${thoiGian.hour}:${thoiGian.minute}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      Text(sdt),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Xác nhận'),
                          content: const Text('Bạn có chắc muốn xóa yêu cầu này không?'),
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
                        await deleteRequestById(localDocs[index].id);
                        setState(() {
                          localDocs.removeAt(index);
                        });
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
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