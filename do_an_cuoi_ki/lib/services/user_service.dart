
// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy tên người dùng theo userId
  Future<String> getTenantName(String userId) async {
    if (userId.isEmpty) return "Chưa có người thuê";
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] as String? ?? 'Người thuê không tên';
      } else {
        return "ID: $userId (Không tìm thấy)";
      }
    } catch (e) {
      print("Lỗi khi lấy tên người thuê ($userId): $e");
    }
    return "ID: $userId (Lỗi)";
  }
}