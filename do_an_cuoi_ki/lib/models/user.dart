// File: models/user.dart

import 'user_role.dart'; // Import enum UserRole

/// Class đại diện cho thông tin người dùng
class UserModel {
  final String id; // ID duy nhất của người dùng (ví dụ: Firebase Auth UID)
  final String name; // Tên người dùng
  final String email; // Email đăng nhập
  final String? phoneNumber; // Số điện thoại (có thể có hoặc không)
  final UserRole role; // Vai trò của người dùng
  final String? profileImageUrl; // URL ảnh đại diện (có thể có hoặc không)
  final DateTime createdAt; // Thời gian tạo tài khoản

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
  });

  /// Hàm tạo UserModel từ một Map (thường dùng khi đọc dữ liệu từ Firestore/API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Sử dụng ?? '' để tránh lỗi null nếu trường 'id' không tồn tại
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Người dùng', // Cung cấp giá trị mặc định
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      // Chuyển đổi String từ JSON thành enum UserRole
      role: UserRoleExtension.fromJson(json['role'] as String? ?? 'customer'),
      profileImageUrl: json['profileImageUrl'] as String?,
      // Chuyển đổi Timestamp (Firestore) hoặc String (ISO 8601) thành DateTime
      createdAt: (json['createdAt'] != null)
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'] as String)
              // Giả sử nếu không phải String thì là Timestamp (ví dụ: Firestore)
              // Cần import 'package:cloud_firestore/cloud_firestore.dart'; nếu dùng Timestamp
              // : (json['createdAt'] as Timestamp).toDate()
              // Tạm thời dùng DateTime.now() nếu không phải String
              : DateTime.now()
            )
          : DateTime.now(), // Cung cấp giá trị mặc định nếu null
    );
  }


  /// Hàm chuyển đổi UserModel thành một Map (thường dùng khi ghi dữ liệu lên Firestore/API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      // Chuyển đổi enum UserRole thành String
      'role': role.toJson(),
      'profileImageUrl': profileImageUrl,
      // Chuyển đổi DateTime thành String dạng ISO 8601 (chuẩn chung)
      // Hoặc dùng FieldValue.serverTimestamp() nếu dùng Firestore
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Hàm copyWith để tạo bản sao của đối tượng với một vài thuộc tính được thay đổi
  /// Rất hữu ích trong quản lý state (ví dụ: với Provider, Riverpod, Bloc)
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      // Cho phép đặt phoneNumber thành null
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      // Cho phép đặt profileImageUrl thành null
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}