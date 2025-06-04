// File: main_screen.dart (hoặc tên file bạn đặt cho BuildingListScreen)
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/screens/user/taikhoan.dart';
import 'package:do_an_cuoi_ki/screens/user/trang_chu.dart';
import 'package:do_an_cuoi_ki/screens/user/my_room_screen.dart'; // THÊM IMPORT
import 'package:flutter/material.dart';

class BuildingListScreen extends StatefulWidget { // Tên class này là BuildingListScreen theo code của bạn
  const BuildingListScreen({super.key});
  @override
  State<BuildingListScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<BuildingListScreen> {
  UserModel? currentUser;
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      TrangChu(
        currentUser: currentUser,
        onUserUpdated: updateCurrentUser,
      ),
      PlaceholderWidget( // Giữ lại Placeholder cho Bản đồ hoặc thay thế nếu có màn hình
        icon: Icons.map,
        title: 'Bản đồ',
        currentUser: currentUser,
      ),
      MyRoomScreen(currentUser: currentUser), // THAY THẾ Ở ĐÂY
      AccountScreen(
        currentUser: currentUser,
        onUserUpdated: updateCurrentUser,
      ),
    ];

    return Scaffold(
      body: IndexedStack( // Sử dụng IndexedStack để giữ trạng thái của các tab
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (mounted) { // Thêm kiểm tra mounted
             setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 186, 203, 91), // Màu bạn chọn
        unselectedItemColor: Colors.white70, // Thêm màu cho item không được chọn
        backgroundColor: Colors.green.shade800,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
          BottomNavigationBarItem(icon: Icon(Icons.night_shelter), label: 'Trọ của tôi'), // ĐỔI LABEL
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

// PlaceholderWidget giữ nguyên
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
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('(Dành cho người dùng: ${currentUser!.name})',
                   style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}