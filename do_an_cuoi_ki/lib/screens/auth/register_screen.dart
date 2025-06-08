// File: screens/auth/register_screen.dart

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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  UserRole _selectedRole = UserRole.customer;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
    // ... (logic _register giữ nguyên như trước)
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      String? phoneNumber = _phoneController.text.trim();
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': phoneNumber.isEmpty ? null : phoneNumber,
        'photoUrl': null,
        'role': _selectedRole.toJson(),
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.'), backgroundColor: Colors.green),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    // ... (logic _getErrorMessage giữ nguyên)
    switch (code.toLowerCase()) {
      case 'email-already-in-use': return 'Địa chỉ email này đã được sử dụng.';
      case 'weak-password': return 'Mật khẩu quá yếu (ít nhất 6 ký tự).';
      case 'invalid-email': return 'Địa chỉ email không hợp lệ.';
      case 'operation-not-allowed': return 'Đăng ký bằng email và mật khẩu chưa được kích hoạt.';
      default: return 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }

  InputDecoration _minimalInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    required Color accentColor,
    required Color secondaryTextColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.8), fontSize: 15), // Giảm fontSize hint
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: secondaryTextColor, size: 18) : null, // Giảm size icon
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      // Giảm contentPadding
      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 15.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // Giảm bo tròn một chút
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 12, height: 1.1), // Giảm fontSize lỗi
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }


  @override
  Widget build(BuildContext context) {
    const Color primaryTextColor = Color(0xFF333333);
    const Color secondaryTextColor = Color(0xFF757575);
    const Color accentColor = Colors.green;
    const Color backgroundColor = Color(0xFFF8F9FA); // Màu nền sáng hơn một chút

    // Lấy chiều cao có sẵn trừ đi padding của SafeArea và AppBar (nếu có)
    // và viewInsets (bàn phím)
    final availableHeight = MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            MediaQuery.of(context).viewInsets.bottom - // Quan trọng khi bàn phím hiện
                            kToolbarHeight; // Chiều cao AppBar (nếu có)

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tạo Tài Khoản',
          style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500, fontSize: 18), // Giảm fontSize
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20), // Giảm size icon
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: SafeArea(
        child: LayoutBuilder( // Sử dụng LayoutBuilder để lấy constraints
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Giảm padding tổng thể
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // Form cố gắng chiếm full chiều cao có sẵn
                  maxWidth: 400,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung nếu có thể
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                       // Có thể bỏ bớt tiêu đề phụ nếu không gian quá chật
                      // const Text(
                      //   'Tham gia cùng chúng tôi',
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: primaryTextColor,),
                      // ),
                      // const SizedBox(height: 8),
                      // const Text(
                      //   'Tạo tài khoản để bắt đầu.',
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(fontSize: 14,color: secondaryTextColor,),
                      // ),
                      // const SizedBox(height: 28), // Giảm khoảng cách

                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: primaryTextColor, fontSize: 15), // Giảm fontSize
                        decoration: _minimalInputDecoration(
                          hintText: 'Họ và tên*',
                          prefixIcon: Icons.person_outline_rounded,
                          accentColor: accentColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập họ và tên.' : null,
                      ),
                      const SizedBox(height: 14), // Giảm SizedBox

                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: primaryTextColor, fontSize: 15),
                        decoration: _minimalInputDecoration(
                          hintText: 'Email*',
                          prefixIcon: Icons.alternate_email_rounded,
                          accentColor: accentColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                           if (value == null || value.isEmpty) return 'Vui lòng nhập email.';
                           if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) return 'Email không hợp lệ.';
                           return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: primaryTextColor, fontSize: 15),
                        decoration: _minimalInputDecoration(
                          hintText: 'Số điện thoại (Tùy chọn)',
                          prefixIcon: Icons.phone_outlined,
                          accentColor: accentColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<UserRole>(
                        value: _selectedRole,
                        style: const TextStyle(color: primaryTextColor, fontSize: 15),
                        decoration: _minimalInputDecoration(
                          hintText: 'Chọn vai trò*',
                          prefixIcon: Icons.people_outline_rounded,
                          accentColor: accentColor,
                          secondaryTextColor: secondaryTextColor,
                        ).copyWith(contentPadding: const EdgeInsets.fromLTRB(10.0, 14.0, 10.0, 14.0)), // Padding riêng cho dropdown
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.getDisplayName(), style: const TextStyle(color: primaryTextColor)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedRole = value);
                        },
                        validator: (value) => value == null ? 'Vui lòng chọn vai trò.' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: primaryTextColor, fontSize: 15),
                        decoration: _minimalInputDecoration(
                          hintText: 'Mật khẩu*',
                          prefixIcon: Icons.lock_outline_rounded,
                          accentColor: accentColor,
                          secondaryTextColor: secondaryTextColor,
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: secondaryTextColor, size: 20),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
                          if (value.length < 6) return 'Mật khẩu phải ít nhất 6 ký tự.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _confirmPasswordController,
                        style: const TextStyle(color: primaryTextColor, fontSize: 15),
                        decoration: _minimalInputDecoration(
                          hintText: 'Xác nhận mật khẩu*',
                          prefixIcon: Icons.lock_outline_rounded,
                          accentColor: accentColor,
                          secondaryTextColor: secondaryTextColor,
                           suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: secondaryTextColor, size: 20),
                            onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                          ),
                        ),
                        obscureText: !_isConfirmPasswordVisible,
                         validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
                          if (value != _passwordController.text) return 'Mật khẩu xác nhận không khớp.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20), // Giảm SizedBox

                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0), // Giảm padding
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13.0), // Giảm fontSize
                          ),
                        ),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16), // Giảm padding nút
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 1, // Giảm elevation
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 16), // Giảm SizedBox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text('Đã có tài khoản? ', style: TextStyle(color: secondaryTextColor, fontSize: 14)), // Giảm fontSize
                          GestureDetector(
                            onTap: _isLoading ? null : () {
                              if (Navigator.canPop(context)) { Navigator.pop(context); }
                              else { Navigator.pushReplacementNamed(context, '/login');}
                            },
                            child: const Text('Đăng nhập', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14)), // Giảm fontSize
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          ),
        ),  
    );
  }
}