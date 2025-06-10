import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_role.dart' show UserRole, UserRoleExtension;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- TẤT CẢ BIẾN VÀ LOGIC ĐƯỢC GIỮ NGUYÊN ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Mật khẩu không khớp');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'createdAt': DateTime.now().toIso8601String(),
        'email': _emailController.text.trim(),
        'id': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'profileImageUrl': null,
        'role': _selectedRole.toJson(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi không xác định: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 6 ký tự.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      default:
        return 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }

  // --- GIAO DIỆN MỚI VỚI TÔNG MÀU XANH ĐẬM ---
  @override
  Widget build(BuildContext context) {
    // --- Bảng màu tùy chỉnh ---
    const Color primaryGreen = Color(0xFF276749); // Xanh đậm, chuyên nghiệp (từ ảnh của bạn)
    const Color backgroundLight = Color(0xFFF8F9FA); // Nền xám rất nhạt, sạch sẽ
    const Color textDark = Color(0xFF1A202C);      // Màu đen tuyền cho chữ
    const Color textFaded = Color(0xFF718096);     // Màu xám cho chữ phụ

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text('Tạo tài khoản', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 // --- Header ---
                Icon(
                  Icons.app_registration_rounded,
                  size: 60,
                  color: primaryGreen,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bắt đầu ngay',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                 const Text(
                  'Điền thông tin để tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textFaded,
                  ),
                ),
                const SizedBox(height: 32),
                
                // --- Form ---
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(
                            labelText: 'Họ và tên*',
                            prefixIcon: Icons.person_outline_rounded),
                        validator: (value) =>
                            value!.isEmpty ? 'Vui lòng nhập họ và tên' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: _buildInputDecoration(
                            labelText: 'Email*',
                            prefixIcon: Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value == null || !value.contains('@'))
                            ? 'Vui lòng nhập email hợp lệ'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: _buildInputDecoration(
                            labelText: 'Số điện thoại (Tùy chọn)',
                            prefixIcon: Icons.phone_outlined),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        value: _selectedRole,
                        items: UserRole.values.where((role) => role != UserRole.admin).map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(
                              role == UserRole.customer ? 'Tôi là Khách thuê' : 'Tôi là Chủ nhà',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedRole = value!),
                        decoration: _buildInputDecoration(
                          labelText: 'Bạn là ai?*',
                          prefixIcon: Icons.people_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: _buildInputDecoration(
                            labelText: 'Mật khẩu*',
                            prefixIcon: Icons.lock_outline_rounded),
                        obscureText: true,
                        validator: (value) => (value == null || value.length < 6)
                            ? 'Mật khẩu phải có ít nhất 6 ký tự'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: _buildInputDecoration(
                            labelText: 'Xác nhận mật khẩu*',
                            prefixIcon: Icons.lock_person_outlined),
                        obscureText: true,
                         validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu';
                          }
                          if (value != _passwordController.text) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Error Message ---
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ),

                // --- Register Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'TẠO TÀI KHOẢN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // --- Login Link ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản?', style: TextStyle(color: textFaded)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: primaryGreen),
                      child: const Text('Đăng nhập ngay',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method để tạo InputDecoration nhất quán
  InputDecoration _buildInputDecoration({required String labelText, required IconData prefixIcon}) {
    const Color primaryGreen = Color(0xFF276749);
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
    );
  }
}