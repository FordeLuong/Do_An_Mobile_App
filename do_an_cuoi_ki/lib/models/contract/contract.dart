// File: models/contract/contract.dart

// KHÔNG CẦN import 'package:cloud_firestore/cloud_firestore.dart'; nữa nếu không dùng Timestamp ở đâu khác
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'contract_status.dart';

/// Class đại diện cho thông tin một hợp đồng thuê trọ
class ContractModel {
  final String id;
  final String roomId;
  final String tenantId;
  final String ownerId;
  final DateTime startDate; // Vẫn là DateTime trong Dart model
  final DateTime endDate;   // Vẫn là DateTime trong Dart model
  final double rentAmount;
  final double depositAmount;
  final String? termsAndConditions;
  final ContractStatus status;
  final List<String>? paymentHistoryIds;
  final DateTime createdAt; // Vẫn là DateTime trong Dart model
  final DateTime? updatedAt; // Vẫn là DateTime trong Dart model

  ContractModel({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    required this.depositAmount,
    this.termsAndConditions,
    required this.status,
    this.paymentHistoryIds,
    required this.createdAt,
    this.updatedAt,
  });

  /// Hàm tạo ContractModel từ một Map
  factory ContractModel.fromJson(Map<String, dynamic> json) {
    // Helper function để parse DateTime từ String (ISO 8601)
    // Vẫn có thể xử lý Timestamp từ dữ liệu cũ nếu cần
    DateTime _parseDateTimeFromStringOrTimestamp(dynamic fieldValue, {required DateTime defaultValue}) {
      if (fieldValue == null) return defaultValue;
      if (fieldValue is String) { // Ưu tiên parse String
        final parsedDate = DateTime.tryParse(fieldValue);
        if (parsedDate != null) return parsedDate;
        print("Warning: Could not parse DateTime string '$fieldValue', using default.");
        return defaultValue;
      }
      // Xử lý Timestamp từ dữ liệu cũ (nếu có)
      if (fieldValue is /* Timestamp */ Map && fieldValue.containsKey('_seconds')) { // Kiểm tra cấu trúc Timestamp thủ công
          try {
            return DateTime.fromMillisecondsSinceEpoch(fieldValue['_seconds'] * 1000 + (fieldValue['_nanoseconds'] ?? 0) ~/ 1000000, isUtc: false).toLocal();
          } catch (e) {
             print("Warning: Could not parse Timestamp-like map $fieldValue, using default. Error: $e");
            return defaultValue;
          }
      }
      // Fallback nếu không phải là Timestamp của Firebase (nếu bạn không import cloud_firestore)
      // Hoặc nếu bạn có Timestamp từ nguồn khác.
      // Nếu bạn chắc chắn chỉ có String hoặc Firebase Timestamp (và bạn đã import cloud_firestore):
      // if (fieldValue is Timestamp) return fieldValue.toDate();

      print("Warning: Unknown type for DateTime field ('${fieldValue.runtimeType}'), using default.");
      return defaultValue;
    }

    DateTime? _parseNullableDateTimeFromStringOrTimestamp(dynamic fieldValue) {
        if (fieldValue == null) return null;
        if (fieldValue is String) {
             final parsedDate = DateTime.tryParse(fieldValue);
             if (parsedDate != null) return parsedDate;
             print("Warning: Could not parse nullable DateTime string '$fieldValue'.");
             return null;
        }
        if (fieldValue is /* Timestamp */ Map && fieldValue.containsKey('_seconds')) {
            try {
              return DateTime.fromMillisecondsSinceEpoch(fieldValue['_seconds'] * 1000 + (fieldValue['_nanoseconds'] ?? 0) ~/ 1000000, isUtc: false).toLocal();
            } catch (e) {
              print("Warning: Could not parse nullable Timestamp-like map $fieldValue. Error: $e");
              return null;
            }
        }
        // if (fieldValue is Timestamp) return fieldValue.toDate();

        print("Warning: Unknown type for nullable DateTime field ('${fieldValue.runtimeType}').");
        return null;
    }

    return ContractModel(
      id: json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      startDate: _parseDateTimeFromStringOrTimestamp(json['startDate'], defaultValue: DateTime.now()),
      endDate: _parseDateTimeFromStringOrTimestamp(json['endDate'], defaultValue: DateTime.now().add(const Duration(days: 30))),
      rentAmount: (json['rentAmount'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      termsAndConditions: json['termsAndConditions'] as String?,
      status: ContractStatusExtension.fromJson(json['status'] as String? ?? 'pending'),
      paymentHistoryIds: (json['paymentHistoryIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      createdAt: _parseDateTimeFromStringOrTimestamp(json['createdAt'], defaultValue: DateTime.now()),
      updatedAt: _parseNullableDateTimeFromStringOrTimestamp(json['updatedAt']),
    );
  }

  /// Hàm chuyển đổi ContractModel thành một Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'tenantId': tenantId,
      'ownerId': ownerId,
      'startDate': startDate.toIso8601String(), // LƯU LÀ STRING ISO 8601
      'endDate': endDate.toIso8601String(),     // LƯU LÀ STRING ISO 8601
      'rentAmount': rentAmount,
      'depositAmount': depositAmount,
      'termsAndConditions': termsAndConditions,
      'status': status.toJson(),
      'paymentHistoryIds': paymentHistoryIds,
      'createdAt': createdAt.toIso8601String(), // LƯU LÀ STRING ISO 8601
      'updatedAt': updatedAt?.toIso8601String(), // LƯU LÀ STRING ISO 8601 (nếu không null)
    };
  }

  // copyWith giữ nguyên
  ContractModel copyWith({
    String? id,
    String? roomId,
    String? tenantId,
    String? ownerId,
    DateTime? startDate,
    DateTime? endDate,
    double? rentAmount,
    double? depositAmount,
    String? termsAndConditions,
    ContractStatus? status,
    List<String>? paymentHistoryIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool setUpdatedAtToNull = false,
  }) {
    return ContractModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      tenantId: tenantId ?? this.tenantId,
      ownerId: ownerId ?? this.ownerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rentAmount: rentAmount ?? this.rentAmount,
      depositAmount: depositAmount ?? this.depositAmount,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      status: status ?? this.status,
      paymentHistoryIds: paymentHistoryIds ?? this.paymentHistoryIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: setUpdatedAtToNull ? null : (updatedAt ?? this.updatedAt),
    );
  }
}