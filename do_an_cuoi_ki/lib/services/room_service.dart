import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class RoomService {
  final CollectionReference roomsRef =
      FirebaseFirestore.instance.collection('rooms');

  /// Lấy tất cả phòng
  Future<List<RoomModel>> getAllRooms() async {
    final snapshot = await roomsRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Bổ sung ID vào map nếu chưa có
      data['id'] = doc.id;
      return RoomModel.fromJson(data);
    }).toList();
  }

  /// Thêm phòng mới
  Future<void> addRoom(RoomModel room) async {
    await roomsRef.doc(room.id).set(room.toJson());
  }

  /// Xóa phòng theo ID
  Future<void> deleteRoom(String id) async {
    await roomsRef.doc(id).delete();
  }

  /// Cập nhật thông tin phòng
  Future<void> updateRoom(RoomModel room) async {
    await roomsRef.doc(room.id).update(room.toJson());
  }

  /// Lấy một phòng theo ID
  Future<RoomModel?> getRoomById(String id) async {
    final doc = await roomsRef.doc(id).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return RoomModel.fromJson(data);
    }
    return null;
  }
}
