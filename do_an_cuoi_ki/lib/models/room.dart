// File: models/room.dart

// import 'package:cloud_firestore/cloud_firestore.dart'; // Có thể không cần nếu chỉ dùng String
import 'package:flutter/foundation.dart';

enum RoomStatus {
  available,
  rented,
  unavailable,
  pending_payment
}

extension RoomStatusExtension on RoomStatus {
  String toJson() {
    switch (this) {
      case RoomStatus.available: return 'available';
      case RoomStatus.rented: return 'rented';
      case RoomStatus.unavailable: return 'unavailable';
      case RoomStatus.pending_payment: return 'pending_payment';
    }
  }

  static RoomStatus fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'available': return RoomStatus.available;
      case 'rented': return RoomStatus.rented;
      case 'unavailable': return RoomStatus.unavailable;
      case 'pending_payment': return RoomStatus.pending_payment;
      default:
        print('Warning: Invalid RoomStatus string "$json", defaulting to unavailable.');
        return RoomStatus.unavailable;
    }
  }
  String getDisplayName() {
    switch (this) {
      case RoomStatus.available: return 'Còn trống';
      case RoomStatus.rented: return 'Đã cho thuê';
      case RoomStatus.unavailable: return 'Không khả dụng';
      case RoomStatus.pending_payment: return 'Chờ thanh toán cọc';
    }
  }
}

class RoomModel {
  final String id;
  final String buildingId;
  final String ownerId;
  final String title;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final double price;
  final double area;
  final int capacity;
  final List<String> amenities;
  final List<String> imageUrls;
  final RoomStatus status;
  final DateTime createdAt;   // Vẫn là DateTime
  final DateTime? updatedAt;  // Vẫn là DateTime
  final double sodien;
  final String? currentTenantId;
  final DateTime? rentStartDate; // Vẫn là DateTime

  RoomModel({
    required this.id,
    required this.buildingId,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.area,
    required this.capacity,
    required this.amenities,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.sodien = 0,
    this.currentTenantId,
    this.rentStartDate,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Sử dụng lại hàm helper từ ContractModel hoặc định nghĩa tương tự ở đây
    DateTime _parseDateTimeFromStringOrTimestamp(dynamic fieldValue, {required DateTime defaultValue}) {
      if (fieldValue == null) return defaultValue;
      if (fieldValue is String) {
        final parsedDate = DateTime.tryParse(fieldValue);
        if (parsedDate != null) return parsedDate;
        print("Warning (RoomModel): Could not parse DateTime string '$fieldValue', using default.");
        return defaultValue;
      }
      if (fieldValue is /* Timestamp */ Map && fieldValue.containsKey('_seconds')) {
          try {
            return DateTime.fromMillisecondsSinceEpoch(fieldValue['_seconds'] * 1000 + (fieldValue['_nanoseconds'] ?? 0) ~/ 1000000, isUtc: false).toLocal();
          } catch (e) {
             print("Warning (RoomModel): Could not parse Timestamp-like map $fieldValue, using default. Error: $e");
            return defaultValue;
          }
      }
      // if (fieldValue is Timestamp) return fieldValue.toDate();
      print("Warning (RoomModel): Unknown type for DateTime field ('${fieldValue.runtimeType}'), using default.");
      return defaultValue;
    }

    DateTime? _parseNullableDateTimeFromStringOrTimestamp(dynamic fieldValue) {
        if (fieldValue == null) return null;
        if (fieldValue is String) {
             final parsedDate = DateTime.tryParse(fieldValue);
             if (parsedDate != null) return parsedDate;
             print("Warning (RoomModel): Could not parse nullable DateTime string '$fieldValue'.");
             return null;
        }
        if (fieldValue is /* Timestamp */ Map && fieldValue.containsKey('_seconds')) {
            try {
              return DateTime.fromMillisecondsSinceEpoch(fieldValue['_seconds'] * 1000 + (fieldValue['_nanoseconds'] ?? 0) ~/ 1000000, isUtc: false).toLocal();
            } catch (e) {
              print("Warning (RoomModel): Could not parse nullable Timestamp-like map $fieldValue. Error: $e");
              return null;
            }
        }
        // if (fieldValue is Timestamp) return fieldValue.toDate();
        print("Warning (RoomModel): Unknown type for nullable DateTime field ('${fieldValue.runtimeType}').");
        return null;
    }

    return RoomModel(
      id: json['id'] as String? ?? '',
      buildingId: json['buildingId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      title: json['title'] as String? ?? 'Chưa có tiêu đề',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? 'Chưa rõ địa chỉ',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      capacity: json['capacity'] as int? ?? 1,
      amenities: List<String>.from((json['amenities'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      imageUrls: List<String>.from((json['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      status: RoomStatusExtension.fromJson(json['status'] as String? ?? 'unavailable'),
      createdAt: _parseDateTimeFromStringOrTimestamp(json['createdAt'], defaultValue: DateTime.now()),
      updatedAt: _parseNullableDateTimeFromStringOrTimestamp(json['updatedAt']),
      sodien: (json['sodien'] as num?)?.toDouble() ?? 0.0,
      currentTenantId: json['currentTenantId'] as String?,
      rentStartDate: _parseNullableDateTimeFromStringOrTimestamp(json['rentStartDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buildingId': buildingId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'area': area,
      'capacity': capacity,
      'amenities': amenities,
      'imageUrls': imageUrls,
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),   // LƯU LÀ STRING ISO 8601
      'updatedAt': updatedAt?.toIso8601String(), // LƯU LÀ STRING ISO 8601
      'sodien': sodien,
      'currentTenantId': currentTenantId,
      'rentStartDate': rentStartDate?.toIso8601String(), // LƯU LÀ STRING ISO 8601
    };
  }

  // copyWith giữ nguyên
  RoomModel copyWith({
    String? id,
    String? buildingId,
    String? ownerId,
    String? title,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    double? price,
    double? area,
    int? capacity,
    List<String>? amenities,
    List<String>? imageUrls,
    RoomStatus? status,
    DateTime? createdAt,
    ValueGetter<DateTime?>? updatedAt,
    double? sodien,
    ValueGetter<String?>? currentTenantId,
    ValueGetter<DateTime?>? rentStartDate,
  }) {
    return RoomModel(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      price: price ?? this.price,
      area: area ?? this.area,
      capacity: capacity ?? this.capacity,
      amenities: amenities ?? this.amenities,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
      sodien: sodien ?? this.sodien,
      currentTenantId: currentTenantId != null ? currentTenantId() : this.currentTenantId,
      rentStartDate: rentStartDate != null ? rentStartDate() : this.rentStartDate,
    );
  }
}