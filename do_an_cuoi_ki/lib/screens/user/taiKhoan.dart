import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/models/user_role.dart';
import 'package:do_an_cuoi_ki/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountScreen extends StatefulWidget {
  final UserModel? currentUser; // Thay đổi từ UserModel thành UserModel? để hỗ trợ null
  final Function(UserModel?) onUserUpdated;

  const AccountScreen({
    super.key,
    required this.currentUser,
    required this.onUserUpdated,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = false;

  // Hàm đăng xuất
  Future<void> _signOut(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      widget.onUserUpdated(null); // Cập nhật trạng thái người dùng thành null
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng xuất thành công!')),
        );
        // Không cần Navigator.pop vì BottomNavigationBar sẽ tự động chuyển tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Hàm chuyển vai trò sang tiếng Việt
  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Khách hàng';
      case UserRole.owner:
        return 'Chủ nhà trọ';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu currentUser là null, hiển thị màn hình yêu cầu đăng nhập
    if (widget.currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Vui lòng đăng nhập để xem tài khoản!',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
                if (result != null && result is UserModel) {
                  widget.onUserUpdated(result);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      );
    }

    // Giao diện chính của trang tài khoản
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần header với ảnh đại diện và tên
            Container(
              color: Colors.green.shade800,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.currentUser!.profileImageUrl ??
                            'https://via.placeholder.com/150.png?text=User',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentUser!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.currentUser!.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Phần thông tin chi tiết
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: widget.currentUser!.email,
                      ),
                      if (widget.currentUser!.phoneNumber != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'Số điện thoại',
                          value: widget.currentUser!.phoneNumber!,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        label: 'Vai trò',
                        value: _getRoleDisplayName(widget.currentUser!.role),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Ngày tạo',
                        value: DateFormat('dd/MM/yyyy')
                            .format(widget.currentUser!.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Phần hành động
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Nút chỉnh sửa hồ sơ
                  _buildActionButton(
                    context,
                    icon: Icons.edit,
                    label: 'Chỉnh sửa hồ sơ',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chức năng chỉnh sửa hồ sơ sẽ được thêm sau!'),
                        ),
                      );
                    },
                  ),
                  // Nút theo vai trò
                  if (widget.currentUser!.role == UserRole.customer)
                    _buildActionButton(
                      context,
                      icon: Icons.favorite,
                      label: 'Danh sách yêu thích',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Xem danh sách nhà trọ yêu thích!'),
                          ),
                        );
                      },
                    ),
                  if (widget.currentUser!.role == UserRole.owner)
                    _buildActionButton(
                      context,
                      icon: Icons.home_work,
                      label: 'Nhà trọ đã đăng',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Xem danh sách nhà trọ đã đăng!'),
                          ),
                        );
                      },
                    ),
                  if (widget.currentUser!.role == UserRole.admin)
                    _buildActionButton(
                      context,
                      icon: Icons.admin_panel_settings,
                      label: 'Quản trị viên',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chuyển đến trang quản trị!'),
                          ),
                        );
                      },
                    ),
                  // Nút đăng xuất
                  _buildActionButton(
                    context,
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    onPressed: _isLoading
                        ? null
                        : () {
                            _signOut(context);
                          },
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper để tạo dòng thông tin
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper để tạo nút hành động
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.green.shade600,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}