import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/screens/auth/login_screen.dart';
import 'package:do_an_cuoi_ki/screens/auth/register_screen.dart';

import 'package:do_an_cuoi_ki/screens/user/room_list_screen_user.dart';
import 'package:do_an_cuoi_ki/screens/user/trang_chu.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
class BuildingListScreen extends StatefulWidget {
  const BuildingListScreen({super.key});
  @override
  State<BuildingListScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<BuildingListScreen> {
  UserModel? currentUser;
  int _currentIndex = 0;

  // Hàm cập nhật currentUser từ các widget con
  void updateCurrentUser(UserModel? user) {
    setState(() {
      currentUser = user;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    // Các màn hình với callback để cập nhật currentUser
    final List<Widget> screens = [
      TrangChu(
        currentUser: currentUser,
        onUserUpdated: updateCurrentUser,
      ),
      PlaceholderWidget(
        icon: Icons.map,
        title: 'Bản đồ',
        currentUser: currentUser,
      ),
      PlaceholderWidget(
        icon: Icons.star,
        title: 'Nổi bật',
        currentUser: currentUser,
      ),
      PlaceholderWidget(
        icon: Icons.person,
        title: 'Tài khoản',
        currentUser: currentUser,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 186, 203, 91),
        backgroundColor: Colors.green.shade800,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Nổi bật'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
class PlaceholderWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final UserModel? currentUser;

  const PlaceholderWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 24, color: Colors.grey)),
          if (currentUser != null) 
            Text('Xin chào: ${currentUser!.name}', 
                 style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}