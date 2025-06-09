// lib/screens/owner/owner_room_list_for_repair.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/room.dart';
import 'package:do_an_cuoi_ki/screens/owner/quanlysuachua_screen.dart';

class OwnerRoomListForRepair extends StatelessWidget {
  final String ownerId;

  const OwnerRoomListForRepair({super.key, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    print('OwnerRoomListForRepair: ownerId = $ownerId'); // Để debug

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Phòng để Quản lý Sửa chữa'),
        backgroundColor: Colors.green.shade800,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            // SỬA DÒNG DƯỚI ĐÂY NẾU TÊN TRƯỜNG OWNER ID KHÔNG PHẢI LÀ 'ownerId'
            .where('ownerId', isEqualTo: ownerId) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // RẤT QUAN TRỌNG: In lỗi chi tiết từ Firestore
            print('Lỗi tải danh sách phòng cho sửa chữa: ${snapshot.error}');
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bạn chưa có phòng nào để quản lý sửa chữa.'));
          }

          final rooms = snapshot.data!.docs.map((doc) => RoomModel.fromJson({
            ...doc.data(),
            'id': doc.id,
          })).toList();

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(room.title),
                  subtitle: Text('Địa chỉ: ${room.address} | Trạng thái: ${room.status}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => QuanLyPhieuSuaChuaScreen(roomId: room.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}