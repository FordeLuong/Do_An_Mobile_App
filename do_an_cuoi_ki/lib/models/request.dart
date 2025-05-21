// File: models/request_model.dart

/// Enum cho loại yêu cầu của khách
enum RequestType {
  thuePhong,
  traPhong,
  suaChua,
}

/// Extension để chuyển đổi enum sang String và ngược lại
extension RequestTypeExtension on RequestType {
  String toJson() {
    switch (this) {
      case RequestType.thuePhong:
        return 'thue_phong';
      case RequestType.traPhong:
        return 'tra_phong';
      case RequestType.suaChua:
        return 'sua_chua';
    }
  }

  static RequestType fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'thue_phong':
        return RequestType.thuePhong;
      case 'tra_phong':
        return RequestType.traPhong;
      case 'sua_chua':
        return RequestType.suaChua;
      default:
        print('Warning: Unknown request type "$json", defaulting to sua_chua.');
        return RequestType.suaChua;
    }
  }
}

/// Model đại diện cho một yêu cầu của khách
class RequestModel {
  final String id;
  final RequestType loaiRequest;
  final String moTa;
  final String roomId;
  final String userKhachId;
  final DateTime thoiGian;
  final String sdt;
  final String Name;

  RequestModel({
    required this.id,
    required this.loaiRequest,
    required this.moTa,
    required this.roomId,
    required this.userKhachId,
    required this.thoiGian,
    required this.sdt,
    required this.Name
  });

  /// Tạo từ JSON
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as String? ?? '',
      loaiRequest: RequestTypeExtension.fromJson(json['loai_request'] as String? ?? 'sua_chua'),
      moTa: json['mo_ta'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      userKhachId: json['user_khach_id'] as String? ?? '',
      thoiGian: json['thoi_gian'] != null
          ? DateTime.parse(json['thoi_gian'] as String)
          : DateTime.now(),
      sdt: json['sdt'] as String? ?? '',
      Name: json['Name'] as String? ?? '',
    );
  }

  /// Chuyển sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loai_request': loaiRequest.toJson(),
      'mo_ta': moTa,
      'room_id': roomId,
      'user_khach_id': userKhachId,
      'thoi_gian': thoiGian.toIso8601String(),
      'sdt': sdt,
      'Name':Name
    };
  }

  /// Tạo bản sao cập nhật (copyWith)
  RequestModel copyWith({
    String? id,
    RequestType? loaiRequest,
    String? moTa,
    String? roomId,
    String? userKhachId,
    DateTime? thoiGian,
    String? sdt,
    String? Name
  }) {
    return RequestModel(
      id: id ?? this.id,
      loaiRequest: loaiRequest ?? this.loaiRequest,
      moTa: moTa ?? this.moTa,
      roomId: roomId ?? this.roomId,
      userKhachId: userKhachId ?? this.userKhachId,
      thoiGian: thoiGian ?? this.thoiGian,
      sdt: sdt ?? this.sdt,
      Name: Name ?? this.Name
    );
  }
}
