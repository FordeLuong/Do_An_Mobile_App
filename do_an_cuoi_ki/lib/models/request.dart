// File: models/request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
// Giả sử RoomStatus được định nghĩa trong models/room.dart
// Bạn cần import nó nếu RoomStatus được sử dụng trong hàm kiểm tra (ví dụ: kiểm tra status của phòng)
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
  // Hàm helper để lấy tên hiển thị đẹp hơn (tùy chọn)
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
  final String roomId; // ID của phòng liên quan đến yêu cầu
  final String userKhachId; // ID của người dùng tạo yêu cầu
  final DateTime thoiGian;
=======
  final String roomId;
  final String userKhachId;
  final DateTime thoiGian; // Vẫn là DateTime trong model Dart
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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

  factory RequestModel.fromJson(Map<String, dynamic> json) {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
  DateTime _parseFirestoreDateTime(dynamic fieldValue) {
    if (fieldValue == null) return DateTime.now(); // Hoặc xử lý null theo cách khác
    if (fieldValue is Timestamp) return fieldValue.toDate(); // QUAN TRỌNG
    if (fieldValue is String) return DateTime.tryParse(fieldValue) ?? DateTime.now();
    print("Warning: Unknown type for DateTime field, defaulting to now. Value: $fieldValue, Type: ${fieldValue.runtimeType}");
    return DateTime.now();
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    DateTime _parseDateTimeFromString(dynamic fieldValue) {
      if (fieldValue == null) {
        print("Warning: DateTime field 'thoi_gian' is null, defaulting to now.");
        return DateTime.now();
      }
      if (fieldValue is String) {
        // Cố gắng parse String, nếu không được thì trả về DateTime.now()
        // Bạn có thể muốn xử lý lỗi parse chặt chẽ hơn ở đây nếu cần
        DateTime? parsedDate = DateTime.tryParse(fieldValue);
        if (parsedDate == null) {
          print("Warning: Could not parse DateTime string '$fieldValue', defaulting to now.");
          return DateTime.now();
        }
        return parsedDate;
      }
      // Nếu không phải String (và cũng không phải null), đó là kiểu không mong đợi
      print("Warning: Expected String for DateTime field 'thoi_gian' but got ${fieldValue.runtimeType}. Value: $fieldValue. Defaulting to now.");
      return DateTime.now();
    }

    return RequestModel(
      id: json['id'] as String? ?? json['request_id'] as String? ?? '',
      loaiRequest: RequestTypeExtension.fromJson(json['loai_request'] as String? ?? 'sua_chua'),
      moTa: json['mo_ta'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      userKhachId: json['user_khach_id'] as String? ?? '',
      thoiGian: _parseDateTimeFromString(json['thoi_gian']), // CHỈ XỬ LÝ STRING
      sdt: json['sdt'] as String? ?? '',
      Name: json['Name'] as String? ?? '',
    );
>>>>>>> Stashed changes
  }

  return RequestModel(
    id: json['id'] as String? ?? json['request_id'] as String? ?? '', // Kiểm tra các tên trường có thể có cho id
    loaiRequest: RequestTypeExtension.fromJson(json['loai_request'] as String? ?? 'sua_chua'),
    moTa: json['mo_ta'] as String? ?? '',
    roomId: json['room_id'] as String? ?? '',
    userKhachId: json['user_khach_id'] as String? ?? '',
    thoiGian: _parseFirestoreDateTime(json['thoi_gian']), // ĐÃ SỬA
    sdt: json['sdt'] as String? ?? '',
    Name: json['Name'] as String? ?? '',
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loai_request': loaiRequest.toJson(),
      'mo_ta': moTa,
      'room_id': roomId,
      'user_khach_id': userKhachId,
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
      'thoi_gian': Timestamp.fromDate(thoiGian), // Lưu là Timestamp
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
=======
      'thoi_gian': thoiGian.toIso8601String(), // Vẫn lưu là String ISO 8601
>>>>>>> Stashed changes
      'sdt': sdt,
      'Name': Name
    };
  }

  RequestModel copyWith({
    // ... (copyWith giữ nguyên)
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

// --- HÀM HELPER LIÊN QUAN ĐẾN REQUEST ---
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream

/// Kiểm tra xem người dùng có đang thuê phòng nào không.
///
/// Trả về `true` nếu người dùng đang thuê ít nhất một phòng có trạng thái 'rented',
/// ngược lại trả về `false`.
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
=======
Future<bool> checkIfUserIsCurrentlyRenting(String userId) async {
  // ... (checkIfUserIsCurrentlyRenting giữ nguyên)
>>>>>>> Stashed changes
  if (userId.isEmpty) {
    print("checkIfUserIsCurrentlyRenting: userId is empty, returning false.");
    return false;
  }
  try {
    final querySnapshot = await FirebaseFirestore.instance
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        .collection('rooms') // Tên collection chứa thông tin phòng
        .where('currentTenantId', isEqualTo: userId)
        .where('status', isEqualTo: RoomStatus.rented.toJson()) // Sử dụng RoomStatus từ model phòng
        .limit(1) // Chỉ cần tìm một phòng là đủ
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        .collection('rooms')
        .where('currentTenantId', isEqualTo: userId)
        .where('status', isEqualTo: RoomStatus.rented.toJson())
        .limit(1)
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        .get();
    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    print("Lỗi khi kiểm tra trạng thái thuê phòng của người dùng $userId: $e");
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    return false; // Mặc định là chưa thuê nếu có lỗi xảy ra
=======
    return false;
>>>>>>> Stashed changes
=======
    return false;
>>>>>>> Stashed changes
=======
    return false;
>>>>>>> Stashed changes
=======
    return false;
>>>>>>> Stashed changes
=======
    return false;
>>>>>>> Stashed changes
=======
    return false;
>>>>>>> Stashed changes
=======
    return false;
>>>>>>> Stashed changes
=======
    return false;
>>>>>>> Stashed changes
=======
    return false;
>>>>>>> Stashed changes
  }
}