import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/request.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RoomListScreen_User extends StatelessWidget {
  final String buildingId;
  final String userId;
  final String sdt;
  final String userName;
  const RoomListScreen_User({super.key, required this.buildingId, required this.userId, required this.sdt, required this.userName});


  void showCreateRequestDialog(BuildContext context, String buildingId, String userId) {
  final formKey = GlobalKey<FormState>();
  RequestType selectedType = RequestType.thuePhong;
  final TextEditingController moTaController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Tạo yêu cầu mới'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RequestType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Loại yêu cầu'),
                items: RequestType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toJson()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
              ),
              TextFormField(
                controller: moTaController,
                decoration: const InputDecoration(labelText: 'Mô tả yêu cầu'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final request = RequestModel(
                  id: FirebaseFirestore.instance.collection('requests').doc().id,
                  loaiRequest: selectedType,
                  moTa: moTaController.text.trim(),
                  roomId: buildingId,
                  userKhachId: userId,
                  thoiGian: DateTime.now(),
                  sdt: sdt,
                  Name: userName
                );

                try {
                  await FirebaseFirestore.instance
                      .collection('requests')
                      .doc(request.id)
                      .set(request.toJson());

                  Navigator.pop(context);
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
            .where('status', isEqualTo: 'available') 
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
                            Text(
                              data['title'] ?? 'Phòng không tên',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () {
                                        showCreateRequestDialog(context, rooms[index].id, userId);
                                      },
                                      child: Text('Liên hệ chủ trọ'),
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
