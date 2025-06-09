// File: models/request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// Giả sử RoomStatus được định nghĩa trong models/room.dart
// Bạn cần import nó nếu RoomStatus được sử dụng trong hàm kiểm tra (ví dụ: kiểm tra status của phòng)
import 'package:do_an_cuoi_ki/models/room.dart'; // Đảm bảo đường dẫn này đúng


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
        return 'thue_phong'; // Giữ nguyên snake_case để nhất quán với Firestore
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

  // Hàm helper để lấy tên hiển thị đẹp hơn (tùy chọn)
  String getDisplayName() {
    switch (this) {
      case RequestType.thuePhong:
        return 'Thuê phòng';
      case RequestType.traPhong:
        return 'Trả phòng';
      case RequestType.suaChua:
        return 'Sửa chữa / Báo cáo sự cố';
    }
  }
}

/// Model đại diện cho một yêu cầu của khách
class RequestModel {
  final String id;
  final RequestType loaiRequest;
  final String moTa;
  final String roomId; // ID của phòng liên quan đến yêu cầu
  final String userKhachId; // ID của người dùng tạo yêu cầu
  final DateTime thoiGian; // Sẽ được lưu/tải dưới dạng String (ISO 8601)
  final String sdt;
  final String Name;
  final String status; // pending, approved, rejected

  RequestModel({
    required this.id,
    required this.loaiRequest,
    required this.moTa,
    required this.roomId,
    required this.userKhachId,
    required this.thoiGian,
    required this.sdt,
    required this.Name,
    this.status = 'pending', // Trạng thái mặc định là 'pending'
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    // Helper function to parse DateTime from String (ISO 8601) or Timestamp
    DateTime _parseDateTime(dynamic fieldValue) {
      if (fieldValue == null) {
        print("Warning: DateTime field 'thoi_gian' is null, defaulting to DateTime.now().");
        return DateTime.now(); // Default if null
      }
      if (fieldValue is String) {
        // Attempt to parse ISO 8601 string
        final parsedDate = DateTime.tryParse(fieldValue);
        if (parsedDate != null) {
          return parsedDate;
        } else {
          print("Warning: Could not parse DateTime string '$fieldValue' for 'thoi_gian', defaulting to DateTime.now().");
          return DateTime.now(); // Default if parsing fails
        }
      }
      if (fieldValue is Timestamp) {
        // Handle Timestamp for backward compatibility or other sources
        return fieldValue.toDate();
      }
      // Fallback for unknown types
      print("Warning: Unknown type for 'thoi_gian' field (Type: ${fieldValue.runtimeType}, Value: $fieldValue), defaulting to DateTime.now().");
      return DateTime.now();
    }

    return RequestModel(
      id: json['id'] as String? ?? json['request_id'] as String? ?? '', // Kiểm tra các tên trường có thể có cho id
      loaiRequest: RequestTypeExtension.fromJson(json['loai_request'] as String? ?? 'sua_chua'),
      moTa: json['mo_ta'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      userKhachId: json['user_khach_id'] as String? ?? '',
      thoiGian: _parseDateTime(json['thoi_gian']), // Sử dụng helper mới
      sdt: json['sdt'] as String? ?? '',
      Name: json['Name'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loai_request': loaiRequest.toJson(),
      'mo_ta': moTa,
      'room_id': roomId,
      'user_khach_id': userKhachId,
      'thoi_gian': thoiGian.toIso8601String(), // Lưu DateTime dưới dạng String (ISO 8601)
      'sdt': sdt,
      'Name': Name,
      'status': status,
    };
  }
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'approved':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Không xác định';
    }
  }
  RequestModel copyWith({
    String? id,
    RequestType? loaiRequest,
    String? moTa,
    String? roomId,
    String? userKhachId,
    DateTime? thoiGian,
    String? sdt,
    String? Name,
    String? status,
  }) {
    return RequestModel(
      id: id ?? this.id,
      loaiRequest: loaiRequest ?? this.loaiRequest,
      moTa: moTa ?? this.moTa,
      roomId: roomId ?? this.roomId,
      userKhachId: userKhachId ?? this.userKhachId,
      thoiGian: thoiGian ?? this.thoiGian,
      sdt: sdt ?? this.sdt,
      Name: Name ?? this.Name,
      status: status ?? this.status,
    );
  }
}

// --- HÀM HELPER LIÊN QUAN ĐẾN REQUEST ---

/// Kiểm tra xem người dùng có đang thuê phòng nào không.
///
/// Trả về `true` nếu người dùng đang thuê ít nhất một phòng có trạng thái 'rented',
/// ngược lại trả về `false`.
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