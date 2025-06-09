// compensation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CompensationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lưu dữ liệu bồi thường
  Future<void> saveCompensationData(
    List<Map<String, dynamic>> compensationData, 
    String contactID, 
    List<String> violationTerms
  ) async {
    try {
      // Lọc dữ liệu hợp lệ
      final validItems = compensationData.where((item) => 
        item['info'].toString().trim().isNotEmpty || 
        item['cost'].toString().trim().isNotEmpty
      ).toList();

      // Tính tổng chi phí
      final total = validItems.fold(0.0, (sum, item) {
        final cost = item['cost'] is String 
            ? double.tryParse(item['cost']) ?? 0 
            : item['cost'] as double;
        return sum + cost;
      });

      // Chuẩn bị dữ liệu
      final compensationDoc = {
        'ContactID': contactID,
        'createdAt': FieldValue.serverTimestamp(),
        'items': validItems,
        'totalAmount': total,
        'date': DateTime.now(),
        'violationTerms': violationTerms
      };

      // Lưu lên Firestore
      await _firestore
          .collection('compensations')
          .add(compensationDoc);

      debugPrint('Dữ liệu đã được lưu thành công');
    } catch (e) {
      debugPrint('Lỗi khi lưu dữ liệu: $e');
      rethrow;
    }
  }
}