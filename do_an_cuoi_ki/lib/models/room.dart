// File: models/room.dart

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
  final String buildingId;
  final String ownerId; // ID của người chủ sở hữu (liên kết với UserModel)
  final String title; // Tiêu đề bài đăng (ví dụ: "Phòng trọ giá rẻ quận 1")
  final String description; // Mô tả chi tiết về phòng trọ
  final String address; // Địa chỉ cụ thể
  final double latitude; // Vĩ độ (để hiển thị trên bản đồ)
  final double longitude; // Kinh độ (để hiển thị trên bản đồ)
  final double price; // Giá thuê (ví dụ: tính theo tháng)
  final double area; // Diện tích (mét vuông)
  final int capacity; // Sức chứa (số người tối đa)
  final List<String> amenities; // Danh sách các tiện nghi (ví dụ: "Wifi", "Điều hòa", "Nóng lạnh")
  final List<String> imageUrls; // Danh sách URL hình ảnh của phòng trọ
  final RoomStatus status; // Trạng thái của phòng (còn trống, đã thuê,...)
  final DateTime createdAt; // Thời gian đăng tin
  final DateTime? updatedAt; // Thời gian cập nhật cuối cùng (có thể null)
  final double sodien;

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
    this.sodien=0,
  });

  /// Hàm tạo RoomModel từ một Map
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String? ?? '',
      buildingId: json['id']as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      title: json['title'] as String? ?? 'Chưa có tiêu đề',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? 'Chưa rõ địa chỉ',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0, // Chuyển đổi num sang double
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      capacity: json['capacity'] as int? ?? 1,
      // Chuyển đổi List<dynamic> thành List<String>
      amenities: List<String>.from((json['amenities'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      imageUrls: List<String>.from((json['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      status: RoomStatusExtension.fromJson(json['status'] as String? ?? 'unavailable'),
      createdAt: (json['createdAt'] != null)
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'] as String)
              // Giả sử Timestamp nếu không phải String
              // : (json['createdAt'] as Timestamp).toDate()
              : DateTime.now() // Tạm thời
            )
          : DateTime.now(),
      updatedAt: (json['updatedAt'] != null)
          ? (json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'] as String)
              // : (json['updatedAt'] as Timestamp).toDate()
              : null // Tạm thời
            )
          : null,
      sodien: json['sodien'] as double? ?? 0,

    );
  }


  /// Hàm chuyển đổi RoomModel thành một Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buildingId':buildingId,
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
      'createdAt': createdAt.toIso8601String(), // Hoặc FieldValue.serverTimestamp()
      'updatedAt': updatedAt?.toIso8601String(), // Hoặc FieldValue.serverTimestamp() nếu cập nhật
      'sodien' : sodien
    };
  }

   /// Hàm copyWith để tạo bản sao và cập nhật
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
    DateTime? updatedAt,
    double? sodien,
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
      updatedAt: updatedAt ?? this.updatedAt,
      sodien: sodien ?? this.sodien,
    );
  }
}