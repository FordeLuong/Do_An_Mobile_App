// File: screens/auth/login_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/screens/owner/owner_main_screen.dart'; // Đường dẫn đến màn hình chính của Owner
import 'package:do_an_cuoi_ki/screens/user/trang_chu.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user.dart'; // Đường dẫn đến UserModel
import '../../models/user_role.dart'; // Đường dẫn đến UserRole enum
import 'register_screen.dart'; // Import màn hình đăng ký

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
  bool _isPasswordVisible = false;

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
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentReference userRef = firestore.collection('users').doc(userCredential.user!.uid);
      final DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('User data not found in Firestore');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      userData['uid'] = userCredential.user!.uid;
      final UserModel user = UserModel.fromJson(userData);

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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  UserModel? currentUser;  
  void updateCurrentUser(UserModel? user) {
    print("MainScreen: updateCurrentUser called with user: ${user?.email}"); // Thêm log
    if (mounted) {
      setState(() {
        currentUser = user;
        print("MainScreen: currentUser updated to: ${currentUser?.email}"); // Thêm log
      });
    } else {
      print("MainScreen: updateCurrentUser called but widget is not mounted.");
    }
  }

  void _navigateBasedOnRole(UserModel user) {
    if (!mounted) return;

    if (user.role == UserRole.customer) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => TrangChu(currentUser: user, onUserUpdated: updateCurrentUser,),
        ),
        (route) => false,
      );
      if (Navigator.canPop(context)) Navigator.pop(context, user);
    } else if (user.role == UserRole.owner) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreenWithBottomNav(currentUser: user),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = 'Vai trò người dùng không được hỗ trợ.';
      });
      FirebaseAuth.instance.signOut();
    }
  }

 String _getErrorMessage(String code) {
    switch (code.toLowerCase()) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử đăng nhập. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại.';
      default:
        return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Nền xám rất nhạt hoặc trắng
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Đăng Nhập',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chào mừng bạn trở lại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 48),

                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Email của bạn',
                        hintStyle: const TextStyle(color: Color(0xFF757575)),
                        prefixIcon: Icon(Icons.alternate_email, color: Color(0xFF757575), size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 15.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.green, width: 1.5),
                        ),
                        errorStyle: const TextStyle(fontSize: 13),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Mật khẩu',
                        hintStyle: const TextStyle(color: Color(0xFF757575)),
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF757575), size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 15.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.green, width: 1.5),
                        ),
                        errorStyle: const TextStyle(fontSize: 13),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Color(0xFF757575),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
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
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : () {
                           ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chức năng Quên mật khẩu đang phát triển.'))
                            );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          foregroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Quên mật khẩu?',
                           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 14.0),
                        ),
                      ),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: Color(0xFF757575), fontSize: 15),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : () {
                            Navigator.push( // Điều hướng trực tiếp
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}