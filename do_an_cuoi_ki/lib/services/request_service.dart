import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RequestService {
  final FirebaseFirestore _firestore;

  RequestService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Tương đương với đoạn query bạn đã cung cấp 
 Future<List<Map<String, dynamic>>> getTenantRequestsForRoom(String roomId) async {
    final querySnapshot = await _firestore
        .collection('requests')
        .where('room_id', isEqualTo: roomId)
        .where('loai_request', isEqualTo: RequestType.thuePhong.toJson())
        .get();


    final List<Map<String, dynamic>> loadedRequests = [];
    
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['user_khach_id'] != null) {
        final userDoc = await _firestore.collection('users').doc(data['user_khach_id']).get();
        if (userDoc.exists && userDoc.data() != null) {
          loadedRequests.add({
            'id': doc.id,
            'user_khach_id': data['user_khach_id'],
            'Name': userDoc.data()!['name'] ?? data['Name'] ?? 'Chưa có tên',
          });
        } else {
          loadedRequests.add({
            'id': doc.id,
            'user_khach_id': data['user_khach_id'],
            'Name': data['Name'] ?? 'Chưa có tên (user không tồn tại)',
          });
        }
      }
    }
    
    return loadedRequests;
  }
  Future<List<RequestModel>> getRequestsByTenantAndRoom(
      String userKhachId, String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('requests')
    } catch (e) {
      throw Exception('Lỗi khi tải yêu cầu: $e');
    }
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _firestore
          .collection('requests')
          .doc(requestId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái yêu cầu: $e');
    }
  }
}