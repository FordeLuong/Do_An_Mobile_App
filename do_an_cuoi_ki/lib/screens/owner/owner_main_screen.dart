import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/screens/owner/add_room_for_building.dart';
import 'package:do_an_cuoi_ki/screens/owner/add_room_screen.dart';
import 'package:do_an_cuoi_ki/screens/owner/room_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'building_list.dart';



class HomeScreenWithBottomNav extends StatefulWidget {
  final UserModel currentUser;
  const HomeScreenWithBottomNav({super.key, required this.currentUser});

  @override
  State<HomeScreenWithBottomNav> createState() => _HomeScreenWithBottomNavState();
}

class _HomeScreenWithBottomNavState extends State<HomeScreenWithBottomNav> {
  int _selectedIndex = 0;

  // Danh sách các widget tương ứng với từng tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      BuildingListScreen_2(currentUser: widget.currentUser),
      const Center(child: Text('Bản đồ')),
      CreateBuildingScreen(currentUser: widget.currentUser),
      const Center(child: Text('Tài khoản')),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // Nếu nhấn vào tab 'Tạo trọ mới', chuyển màn hình
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateBuildingScreen(currentUser: widget.currentUser),
          ),
        );
        // Không chuyển body mà giữ nguyên tab cũ
        _selectedIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 186, 203, 91),
        backgroundColor: Colors.green.shade800,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Tạo trọ mới'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
