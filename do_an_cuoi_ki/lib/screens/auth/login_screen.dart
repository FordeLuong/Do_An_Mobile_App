import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:do_an_cuoi_ki/screens/owner/owner_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Đăng nhập với Firebase Auth
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('Đăng nhập thành công: ${userCredential.user!.uid}');
      

      // Lấy thông tin user từ Realtime Database
      // final FirebaseDatabase database = FirebaseDatabase.instanceFor(
      //   app: Firebase.app(),
      //   databaseURL: 'https://db-ql-tro-default-rtdb.firebaseio.com/',
      // );
      // final DatabaseReference userRef = database.ref('users/${userCredential.user!.uid}');
      // final DatabaseEvent event = await userRef.once();
      // final Map<dynamic, dynamic>? userData =
      //     event.snapshot.value as Map<dynamic, dynamic>?;

      // if (userData == null) {
      //   throw Exception('User data not found');
      // }

      // // Chuyển đổi thành UserModel
      // final UserModel user = UserModel.fromJson(Map<String, dynamic>.from(userData));



      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentReference userRef = firestore.collection('users').doc(userCredential.user!.uid);

      final DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      // Chuyển đổi thành UserModel
      final userData = userDoc.data() as Map<String, dynamic>;
      // Điều hướng dựa trên role
      final UserModel user = UserModel.fromJson(userData);



      // Điều hướng dựa trên role
      _navigateBasedOnRole(user);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateBasedOnRole(UserModel user) {
    switch (user.role) {
      case UserRole.customer:

      Navigator.pop(context, user); // trả dữ liệu về
      break;
      case UserRole.owner:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreenWithBottomNav(
              currentUser: user, // Truyền vào UserModel hiện tại
            ),
          ),
        );
        break;
      default:
        Navigator.pushReplacementNamed(context, '/login'); // Quay lại login nếu role không hợp lệ
        break;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      default:
        return 'Đăng nhập thất bại';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('ĐĂNG NHẬP'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: const Text('Quên mật khẩu?'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Đăng ký ngay'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}