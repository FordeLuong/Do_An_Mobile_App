// File: models/building.dart

/// Class đại diện cho thông tin một nhà trọ
class BuildingModel {
  final String buildingId; // ID duy nhất của nhà trọ
  final String buildingName; // Tên nhà trọ
  final String address; // Địa chỉ nhà trọ
  final int totalRooms; // Tổng số phòng
  final String? managerName; // Tên người quản lý
  final String? managerPhone; // Số điện thoại người quản lý
  final String? managerId; // ID của người quản lý
  final List<String> imageUrls; // Danh sách URL hình ảnh của nhà trọ
  final double latitude; // Vĩ độ (để hiển thị trên bản đồ)
  final double longitude; // Kinh độ (để hiển thị trên bản đồ)
  final DateTime createdAt; // Thời gian tạo

  BuildingModel({
    required this.buildingId,
    required this.buildingName,
    required this.address,
    required this.totalRooms,
    this.managerName,
    this.managerPhone,
    this.managerId, // Thêm vào đâys
    required this.imageUrls,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  /// Hàm tạo BuildingModel từ một Map
  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      buildingId: json['buildingId'] as String? ?? '',
      buildingName: json['buildingName'] as String? ?? 'Chưa có tên',
      address: json['address'] as String? ?? 'Chưa rõ địa chỉ',
      totalRooms: json['totalRooms'] as int? ?? 0,
      managerName: json['managerName'] as String?,
      managerPhone: json['managerPhone'] as String?,
      managerId: json['managerId'] as String?, // Thêm vào đây
      imageUrls: List<String>.from((json['image_urls'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['createdAt'] != null)
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now())
          : DateTime.now(),
    );
  }

  /// Hàm chuyển đổi BuildingModel thành một Map
  Map<String, dynamic> toJson() {
    return {
      'buildingId': buildingId,
      'buildingName': buildingName,
      'address': address,
      'totalRooms': totalRooms,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'managerId': managerId, // Thêm vào đây
      'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Hàm copyWith để tạo bản sao và cập nhật
  BuildingModel copyWith({
    String? buildingId,
    String? buildingName,
    String? address,
    int? totalRooms,
    String? managerName,
    String? managerPhone,
    String? managerId, // Thêm vào đây
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return BuildingModel(
      buildingId: buildingId ?? this.buildingId,
      buildingName: buildingName ?? this.buildingName,
      address: address ?? this.address,
      totalRooms: totalRooms ?? this.totalRooms,
      managerName: managerName ?? this.managerName,
      managerPhone: managerPhone ?? this.managerPhone,
      managerId: managerId ?? this.managerId, // Thêm vào đây
      imageUrls: imageUrls ?? this.imageUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Getter để kiểm tra xem tọa độ có hợp lệ không
  bool get hasValidCoordinates {
    return latitude != 0.0 && longitude != 0.0;
  }

  /// Getter để kiểm tra xem có hình ảnh không
  bool get hasImages {
    return imageUrls.isNotEmpty;
  }
}
