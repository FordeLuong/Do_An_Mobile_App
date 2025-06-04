import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/screens/owner/add_room_screen.dart';
import 'package:do_an_cuoi_ki/screens/owner/bando.dart';
import 'package:flutter/material.dart';
import 'building_list.dart';
import 'owner_account_screen.dart';
import 'package:do_an_cuoi_ki/screens/user/taikhoan.dart';

class HomeScreenWithBottomNav extends StatefulWidget {
  final UserModel currentUser;
  const HomeScreenWithBottomNav({super.key, required this.currentUser});
  // Hàm cập nhật currentUser từ các widget con

  @override
  State<HomeScreenWithBottomNav> createState() => _HomeScreenWithBottomNavState();
}

class _HomeScreenWithBottomNavState extends State<HomeScreenWithBottomNav> {
  int _selectedIndex = 0;
  UserModel? currentUser;

  late final List<Widget> _screens;
  void updateCurrentUser(UserModel? user) {
    setState(() {
      currentUser = user;
    });
  }
  @override
  void initState() {
    super.initState();
    _screens = [
      BuildingListScreen_2(currentUser: widget.currentUser),
      MapScreen(currentUser: widget.currentUser),
      CreateBuildingScreen(currentUser: widget.currentUser),
      OwnerAccountScreen(currentUser: widget.currentUser),
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