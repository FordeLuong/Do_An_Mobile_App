import 'package:do_an_cuoi_ki/screens/user/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:do_an_cuoi_ki/screens/auth/login_screen.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthService {
  static Future<void> signOut(BuildContext context, Function(UserModel?) onUserUpdated) async {
    try {
      // Debug: Kiểm tra trạng thái người dùng trước khi đăng xuất
      print('Before sign out: Current user = ${FirebaseAuth.instance.currentUser?.uid}');

      // Xóa dữ liệu cục bộ trong SharedPreferences (nếu có)
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences keys before clear: ${prefs.getKeys()}');
      await prefs.clear();
      print('SharedPreferences cleared');

      // Đăng xuất Firebase Authentication
      await FirebaseAuth.instance.signOut();

      // Đảm bảo trạng thái người dùng là null
      if (FirebaseAuth.instance.currentUser == null) {
        print('After sign out: Current user = null');
        onUserUpdated(null); // Cập nhật trạng thái người dùng thành null
      } else {
        print('After sign out: Current user = ${FirebaseAuth.instance.currentUser?.uid}');
        throw Exception('Failed to sign out: User still authenticated');
      }

      // Kiểm tra context.mounted trước khi thực hiện UI updates
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng xuất thành công!')),
        );
        // Chuyển hướng về màn hình đăng nhập và xóa stack điều hướng
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => BuildingListScreen()),
          (route) => false,
        );
      } else {
        print('Context not mounted, cannot show SnackBar or navigate');
      }
    } catch (e) {
      print('Sign out error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    }
  }
}