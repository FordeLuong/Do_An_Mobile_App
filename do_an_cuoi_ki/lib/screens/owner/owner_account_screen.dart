// lib/screens/owner/owner_account_screen.dart

import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:flutter/material.dart';
import 'contract/owner_contract_list_screen.dart';
import 'package:do_an_cuoi_ki/screens/user/taikhoan.dart';
// Import các màn hình quản lý tương ứng (bạn cần tạo các màn hình này)
// import 'package:do_an_cuoi_ki/screens/owner/manage_buildings_screen.dart';
// import 'package:do_an_cuoi_ki/screens/owner/manage_invoices_screen.dart';
// import 'package:do_an_cuoi_ki/screens/owner/manage_utilities_screen.dart'; // Điện nước
// import 'package:do_an_cuoi_ki/screens/owner/manage_repair_requests_screen.dart'; // Phiếu sửa chữa
// import 'package:do_an_cuoi_ki/screens/owner/manage_contracts_screen.dart'; // Hợp đồng
import 'package:do_an_cuoi_ki/services/auth_service.dart';
// Model cho một mục quản lý trên lưới
class ManagementItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap; // Hành động khi nhấn vào

  ManagementItem({required this.title, required this.icon, required this.onTap});
}

class OwnerAccountScreen extends StatelessWidget {
  final UserModel currentUser;

  const OwnerAccountScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // Danh sách các mục quản lý
    final List<ManagementItem> managementItems = [
      ManagementItem(
        title: 'Quản lý nhà trọ',
        icon: Icons.home_work_outlined,
        onTap: () {
          // TODO: Điều hướng đến màn hình quản lý nhà trọ
          print('Navigate to Manage Buildings');
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ManageBuildingsScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng Quản lý nhà trọ đang được phát triển.'))
          );
        },
      ),
      ManagementItem(
        title: 'Quản lý hóa đơn',
        icon: Icons.receipt_long_outlined,
        onTap: () {
          // TODO: Điều hướng đến màn hình quản lý hóa đơn
          print('Navigate to Manage Invoices');
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng Quản lý hóa đơn đang được phát triển.'))
          );
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ManageInvoicesScreen()));
        },
      ),
      ManagementItem(
        title: 'Quản lý điện nước',
        icon: Icons.electrical_services_outlined,
        onTap: () {
          // TODO: Điều hướng đến màn hình quản lý điện nước
          print('Navigate to Manage Utilities');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng Quản lý điện nước đang được phát triển.'))
          );
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ManageUtilitiesScreen()));
        },
      ),
      ManagementItem(
        title: 'Quản lý sửa chữa', // Đổi tên từ "phiếu sửa chữa" cho gọn
        icon: Icons.build_circle_outlined,
        onTap: () {
          // TODO: Điều hướng đến màn hình quản lý phiếu sửa chữa
          print('Navigate to Manage Repair Requests');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng Quản lý sửa chữa đang được phát triển.'))
          );
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ManageRepairRequestsScreen()));
        },
      ),
      ManagementItem(
        title: 'Quản lý hợp đồng',
        icon: Icons.description_outlined,
        onTap: () {
          print('Navigate to Manage Contracts');
          Navigator.push(
            context,
            MaterialPageRoute(
              // Điều hướng đến OwnerContractListScreen và truyền currentUser
              builder: (_) => OwnerContractListScreen(currentUser: currentUser),
            ),
          );
        },
      ),
      // Bạn có thể thêm mục "Đăng xuất" hoặc các mục khác ở đây
      ManagementItem(
        title: 'Đăng xuất',
        icon: Icons.logout_outlined,
        onTap: () {
          // Gọi AuthService.signOut
          AuthService.signOut(context, (UserModel? user) {
            // Callback rỗng vì AuthService.signOut đã xử lý chuyển hướng
          });
        },
      ),
    ];

    return Scaffold(
      // AppBar có thể không cần thiết nếu màn hình này là một tab của BottomNavigationBar
      // appBar: AppBar(
      //   title: const Text('Tài Khoản Chủ Trọ'),
      //   backgroundColor: Colors.green.shade700,
      //   automaticallyImplyLeading: false, // Ẩn nút back nếu không cần
      // ),
      body: SingleChildScrollView( // Cho phép cuộn nếu nội dung dài
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lời chào mừng
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green.shade700,
                    // child: Text( // Hiển thị chữ cái đầu của tên nếu không có ảnh
                    //   currentUser.userName.isNotEmpty ? currentUser.userName[0].toUpperCase() : '?',
                    //   style: const TextStyle(fontSize: 24, color: Colors.white),
                    // ),
                    // Hoặc hiển thị ảnh đại diện nếu có
                    
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào mừng Chủ trọ,',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                        Text(
                          currentUser.name.isNotEmpty ? currentUser.name : 'Chủ trọ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Lưới các mục quản lý
            Text(
              'Bảng điều khiển',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              crossAxisCount: 2, // 2 cột
              shrinkWrap: true, // Để GridView chỉ chiếm không gian cần thiết
              physics: const NeverScrollableScrollPhysics(), // Tắt cuộn của GridView vì đã có SingleChildScrollView
              crossAxisSpacing: 16.0, // Khoảng cách ngang
              mainAxisSpacing: 16.0,  // Khoảng cách dọc
              children: managementItems.map((item) {
                return _buildManagementCard(context, item);
              }).toList(),
            ),
            const SizedBox(height: 20), // Khoảng trống ở cuối
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(BuildContext context, ManagementItem item) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Giảm padding một chút
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade100.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 36.0, // Kích thước icon
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0, // Kích thước chữ
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}