import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:do_an_cuoi_ki/models/room.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Hàm chọn ảnh
  Future<List<File>> pickImages() async {
    final picked = await _picker.pickMultiImage();
    return picked.isNotEmpty ? picked.map((e) => File(e.path)).toList() : [];
  }

  // Hàm upload ảnh lên Firebase Storage
  Future<List<String>> uploadImages(List<File> images, String roomId) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final ref = _storage
          .ref()
          .child('rooms')
          .child(roomId)
          .child('img_$i.jpg');

      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  // Hàm tạo phòng mới
  Future<String> createRoom({
    required BuildContext context,
    required String buildingId,
    required String title,
    required String description,
    required String address,
    required double price,
    required double area,
    required int capacity,
    required List<String> amenities,
    required List<File> images,
    String? ownerId,
  }) async {
    try {
      final roomId = _uuid.v4();
      final imageUrls = await uploadImages(images, roomId);

      final room = RoomModel(
        id: roomId,
        buildingId: buildingId,
        ownerId: ownerId ?? '',
        title: title,
        description: description,
        address: address,
        latitude: 0,
        longitude: 0,
        price: price,
        area: area,
        capacity: capacity,
        amenities: amenities,
        imageUrls: imageUrls,
        status: RoomStatus.available,
        createdAt: DateTime.now(),
        updatedAt: null,
        sodien: 0,
      );

      await _firestore.collection('rooms').doc(roomId).set(room.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tạo phòng thành công!")),
      );
      return roomId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xảy ra lỗi khi tạo phòng.")),
      );
      rethrow;
    }
  }


  // Lấy tất cả phòng trong một tòa nhà có trạng thái cụ thể
  Stream<QuerySnapshot> getRentedRoomsByBuilding(String buildingId) {
    return _firestore
        .collection('rooms')
        .where('buildingId', isEqualTo: buildingId)
        .where('status', isEqualTo: 'rented')
        .snapshots();
  }

  // Lấy thông tin phòng theo ID
  Future<DocumentSnapshot> getRoomById(String roomId) {
    return _firestore.collection('rooms').doc(roomId).get();
  }

  // Lấy hóa đơn gần nhất của phòng
  Future<QuerySnapshot> getLastBillForRoom(String roomId) {
    return _firestore
        .collection('bills')
        .where('roomId', isEqualTo: roomId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
  }


    Future<List<DocumentSnapshot>> filterBillsByBuilding(
    List<DocumentSnapshot> bills, 
    String? buildingId,
  ) async {
    if (buildingId == null) return bills;

    // Lấy tất cả phòng thuộc building
    final roomsQuery = await _firestore
        .collection('rooms')
        .where('buildingId', isEqualTo: buildingId)
        .get();

    if (roomsQuery.docs.isEmpty) return [];

    final roomIds = roomsQuery.docs.map((doc) => doc.id).toList();
    
    // Lọc bills chỉ giữ lại những bill có roomId thuộc building
    return bills.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return roomIds.contains(data['roomId']);
    }).toList();
  }

   Future<String?> getRoomTitleById(String roomId) async {
    try {
      final DocumentSnapshot roomSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .get();

      if (!roomSnapshot.exists) return null;
      
      final data = roomSnapshot.data()! as Map<String, dynamic>;
      return data['title']?.toString(); // Safe conversion to String
    } catch (e) {
      // Consider using a proper logging solution
      debugPrint('Error fetching room title for $roomId: $e'); 
      rethrow; // Let the caller handle the exception
    }
  }

}