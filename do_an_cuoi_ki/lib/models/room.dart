// File: models/room.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Quan trọng để sử dụng Timestamp
import 'package:flutter/foundation.dart';

/// Enum định nghĩa trạng thái của phòng trọ
enum RoomStatus {
  available, // Còn trống
  rented,    // Đã cho thuê
  unavailable // Không khả dụng (ví dụ: đang sửa chữa)
}

// Helper extension cho RoomStatus
extension RoomStatusExtension on RoomStatus {
  String toJson() {
    switch (this) {
      case RoomStatus.available:
        return 'available';
      case RoomStatus.rented:
        return 'rented';
      case RoomStatus.unavailable:
        return 'unavailable';
    }
  }

  static RoomStatus fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'available':
        return RoomStatus.available;
      case 'rented':
        return RoomStatus.rented;
      case 'unavailable':
        return RoomStatus.unavailable;
      default:
        print('Warning: Invalid RoomStatus string "$json", defaulting to unavailable.');
        return RoomStatus.unavailable;
    }
  }
}


/// Class đại diện cho thông tin một phòng trọ/nhà trọ
class RoomModel {
  final String id; // ID duy nhất của phòng trọ
  final String buildingId; // ID của tòa nhà chứa phòng này
  final String ownerId; // ID của người chủ sở hữu (liên kết với UserModel)
  final String title; // Tiêu đề bài đăng (ví dụ: "Phòng trọ giá rẻ quận 1")
  final String description; // Mô tả chi tiết về phòng trọ
  final String address; // Địa chỉ cụ thể
  final double latitude; // Vĩ độ (để hiển thị trên bản đồ)
  final double longitude; // Kinh độ (để hiển thị trên bản đồ)
  final double price; // Giá thuê (ví dụ: tính theo tháng)
  final double area; // Diện tích (mét vuông)
  final int capacity; // Sức chứa (số người tối đa)
  final List<String> amenities; // Danh sách các tiện nghi
  final List<String> imageUrls; // Danh sách URL hình ảnh của phòng trọ
  final RoomStatus status; // Trạng thái của phòng
  final DateTime createdAt; // Thời gian đăng tin/tạo phòng
  final DateTime? updatedAt; // Thời gian cập nhật cuối cùng (có thể null)
  final double sodien; // Số điện (có thể là chỉ số công tơ)
  final String? currentTenantId; // ID của người dùng đang thuê phòng (có thể null)
  final DateTime? rentStartDate;   // Ngày bắt đầu thuê (có thể null)

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

  /// Hàm tạo RoomModel từ một Map (thường là dữ liệu từ Firestore)
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Helper function để parse DateTime một cách an toàn từ Timestamp hoặc String
    DateTime? _parseFirestoreDateTime(dynamic fieldValue) {
      if (fieldValue == null) return null;
      if (fieldValue is Timestamp) return fieldValue.toDate();
      if (fieldValue is String) return DateTime.tryParse(fieldValue);
      return null; // Hoặc throw một lỗi nếu kiểu không mong muốn
    }

    return RoomModel(
      id: json['id'] as String? ?? '',
      buildingId: json['buildingId'] as String? ?? '', // Sửa lỗi: Lấy từ 'buildingId'
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
      createdAt: _parseFirestoreDateTime(json['createdAt']) ?? DateTime.now(), // Mặc định là now nếu null hoặc parse lỗi
      updatedAt: _parseFirestoreDateTime(json['updatedAt']),
      sodien: (json['sodien'] as num?)?.toDouble() ?? 0.0,
      currentTenantId: json['currentTenantId'] as String?,
      rentStartDate: _parseFirestoreDateTime(json['rentStartDate']),
    );
  }


  /// Hàm chuyển đổi RoomModel thành một Map (để lưu vào Firestore)
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
      'createdAt': Timestamp.fromDate(createdAt), // Lưu dưới dạng Timestamp của Firestore
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null, // Lưu dưới dạng Timestamp
      'sodien': sodien,
      'currentTenantId': currentTenantId,
      'rentStartDate': rentStartDate != null ? Timestamp.fromDate(rentStartDate!) : null, // Lưu dưới dạng Timestamp
    };
  }

   /// Hàm copyWith để tạo bản sao và cập nhật các trường một cách dễ dàng
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
    // Sử dụng ValueGetter để cho phép truyền null một cách rõ ràng để xóa giá trị
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