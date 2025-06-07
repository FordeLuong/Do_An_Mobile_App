// File: models/user_role.dart

/// Enum định nghĩa các vai trò người dùng trong ứng dụng
enum UserRole {
  customer, // Khách hàng tìm trọ
  owner,    // Chủ nhà trọ
  admin     // Quản trị viên
}

// Helper extension để chuyển đổi String sang UserRole và ngược lại
// Rất hữu ích khi làm việc với dữ liệu từ API hoặc Firestore
extension UserRoleExtension on UserRole {
  String toJson() {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.owner:
        return 'owner';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      default:
        // Mặc định là customer nếu giá trị không hợp lệ
        print('Warning: Invalid UserRole string "$json", defaulting to customer.');
        return UserRole.customer;
    }
  }
  String getDisplayName() {
    switch (this) {
      case UserRole.customer:
        return 'Khách hàng';
      case UserRole.owner:
        return 'Chủ nhà trọ';
      case UserRole.admin:
        return 'Quản trị viên';
      default: // Mặc dù với enum thì default ít khi xảy ra nếu tất cả case đã được xử lý
        return toString().split('.').last; // Trả về tên enum nếu không khớp
    }
  }
}