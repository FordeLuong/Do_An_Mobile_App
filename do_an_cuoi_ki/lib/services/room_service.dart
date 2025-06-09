import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
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



  Future<String> getRoomTitle(String roomId) async {
    if (roomId.isEmpty) return "Không rõ phòng";
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['title'] as String? ?? 'Phòng không tên';
      } else {
        return "ID: $roomId (Không tìm thấy)";
      }
    } catch (e) {
      print("Lỗi khi lấy tên phòng ($roomId): $e");
    }
    return "ID: $roomId (Lỗi)";
  }

  // Cập nhật trạng thái phòng khi hợp đồng thay đổi
  Future<void> updateRoomStatusForContract({
    required String roomId,
    required ContractStatus newContractStatus,
    required String? tenantId,
  }) async {
    RoomStatus? newRoomStatus;
    String? newCurrentTenantId = tenantId;

    if (newContractStatus == ContractStatus.active) {
      newRoomStatus = RoomStatus.rented;
    } else if (newContractStatus == ContractStatus.pending) {
      newRoomStatus = RoomStatus.pending_payment;
    } else if (newContractStatus == ContractStatus.cancelled || 
               newContractStatus == ContractStatus.terminated || 
               newContractStatus == ContractStatus.expired) {
      newRoomStatus = RoomStatus.available;
      newCurrentTenantId = null;
    }

    if (newRoomStatus != null) {
      await _firestore.collection('rooms').doc(roomId).update({
        'status': newRoomStatus.toJson(),
        'currentTenantId': newCurrentTenantId,
        'updatedAt': Timestamp.now(),
      });
    }
  }

    Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
            'ownerId': '',
          });
    } catch (e) {
      print('Lỗi khi cập nhật phòng: $e');
      rethrow;
    }
  }



    Stream<QuerySnapshot> getRoomsByBuildingId(String buildingId) {
    return _firestore
        .collection('rooms')
        .where('buildingId', isEqualTo: buildingId)
        .snapshots();
  }

  /// Xóa phòng
  Future<void> deleteRoom(String roomId) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .delete();
  }

  Future<RoomModel?> getRoomById1(String roomId) async {
    try {
      final roomSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .get();

      if (roomSnapshot.exists && roomSnapshot.data() != null) {
        Map<String, dynamic> roomDataWithId = Map.from(roomSnapshot.data()!);
        roomDataWithId['id'] = roomSnapshot.id;
        return RoomModel.fromJson(roomDataWithId);
      }
      return null;
    } catch (e) {
      print("Error getting room: $e");
      return null;
    }
  }

   Future<RoomModel?> getRoomById2(String roomId) async {
    try {
      final roomSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .get();

      if (roomSnapshot.exists) {
        return RoomModel.fromJson({
          'id': roomSnapshot.id,
          ...roomSnapshot.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      print("Error getting room: $e");
      return null;
    }
  }

  Stream<QuerySnapshot> getAvailableRoomsByBuildingId(String buildingId) {
    return _firestore
        .collection('rooms')
        .where('buildingId', isEqualTo: buildingId)
        .where('status', isEqualTo: RoomStatus.available.toJson())
        .snapshots();
  }

  Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
    if (userId.isEmpty) {
      print("checkIfUserIsCurrentlyRenting: userId is empty, returning false.");
      return false;
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('rooms') // Tên collection chứa thông tin phòng
          .where('currentTenantId', isEqualTo: userId)
          .where('status', isEqualTo: RoomStatus.rented.toJson()) // Sử dụng RoomStatus từ model phòng
          .limit(1) // Chỉ cần tìm một phòng là đủ
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Lỗi khi kiểm tra trạng thái thuê phòng của người dùng $userId: $e");
      return false; // Mặc định là chưa thuê nếu có lỗi xảy ra
    }
  }
}