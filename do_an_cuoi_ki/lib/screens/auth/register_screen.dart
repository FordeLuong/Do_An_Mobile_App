import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/user.dart';
import '../../models/user_role.dart' show UserRole, UserRoleExtension;

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

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
          // 1. Tạo tài khoản Auth
      final UserCredential userCredential = 
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Khởi tạo Realtime Database với URL của bạn
      // final FirebaseDatabase database = FirebaseDatabase.instanceFor(
      //   app: Firebase.app(), // Sử dụng app Firebase mặc định
      //   databaseURL: 'https://db-ql-tro-default-rtdb.firebaseio.com/', // Thay bằng URL của bạn
      // );

      // // 3. Lưu thông tin vào Realtime Database
      // await database.ref('users/${userCredential.user!.uid}').set({
      //   'createdAt': DateTime.now().toIso8601String(),
      //   'email': _emailController.text.trim(),
      //   'id': userCredential.user!.uid,
      //   'name': _nameController.text.trim(),
      //   'phoneNumber': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      //   'profileImageUrl': null,
      //   'role': _selectedRole.toJson(),
      // });

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'createdAt': DateTime.now().toIso8601String(),
        'email': _emailController.text.trim(),
        'id': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'profileImageUrl': null,
        'role': _selectedRole.toJson(), // đảm bảo role của bạn có .toJson()
      });


      // 3. Hiển thị thông báo và chuyển hướng
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 6 ký tự';
      case 'invalid-email':
        return 'Email không hợp lệ';
      default:
        return 'Đăng ký thất bại';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên*',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email*',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => !value!.contains('@') ? 'Email không hợp lệ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                items: UserRole.values.map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(
                      role == UserRole.customer ? 'Khách hàng' :
                      role == UserRole.owner ? 'Chủ nhà trọ' : 'Quản trị viên',
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
                decoration: const InputDecoration(
                  labelText: 'Vai trò*',
                  prefixIcon: Icon(Icons.people),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu*',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Mật khẩu quá ngắn' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu*',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('ĐĂNG KÝ'),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Đã có tài khoản? Đăng nhập ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}