import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/screens/auth/login_screen.dart';
import 'package:do_an_cuoi_ki/screens/auth/register_screen.dart';

import 'package:do_an_cuoi_ki/screens/user/room_list_screen_user.dart';
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
  String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.shade800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20,),
                // Ngày + nút đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: currentUser == null 
                              ? () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginPage()),
                                  );
                                  if (result != null && result is UserModel) {
                                    setState(() {
                                      currentUser = result;
                                    });
                                  }
                                }
                              : null, // Vô hiệu hóa khi có user
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                          child: currentUser == null
                              ? const Text('Đăng nhập', style: TextStyle(color: Colors.black))
                              : Text(
                                  'Xin chào, ${currentUser!.name}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                        ),
                        if (currentUser == null) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              // Xử lý đăng ký ở đây
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                            ),
                            child: const Text("Đăng kí", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                // Tìm kiếm + yêu thích
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Tìm kiếm",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // PHẦN TAB FILTER NGANG
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("Xe vé gần tôi"),
                _buildFilterChip("Pickleball gần tôi"),
                _buildFilterChip("Cầu lông gần tôi"),
              ],
            ),
          ),

          // DANH MỤC THỂ THAO
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildSportIcon("Pickleball", Icons.sports_tennis),
                _buildSportIcon("Cầu lông", Icons.sports),
                _buildSportIcon("Bóng đá", Icons.sports_soccer),
                _buildSportIcon("Tennis", Icons.sports_tennis_outlined),
                _buildSportIcon("B.Chuyền", Icons.sports_volleyball),
                _buildSportIcon("Bóng rổ", Icons.sports_basketball),
              ],
            ),
          ),

          // DÒNG GỢI Ý THÊM BỘ LỌC
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Bạn muốn tìm kiếm nhiều hơn",
                  style: TextStyle(color: Colors.red),
                ),
                Icon(Icons.tune, color: Colors.green),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('buildings')
                // .where('managerId', isEqualTo: currentUser.id) // Lọc theo managerId
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Không có dữ liệu."));
              }

              final buildings = snapshot.data!.docs;

              return ListView.builder(
                itemCount: buildings.length,
                itemBuilder: (context, index) {
                  final data = buildings[index].data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: data['imageUrls']?[0] ?? '',
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: const Icon(Icons.favorite_border),
                                    onPressed: () {},
                                  ),
                                ),
                              )
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['buildingName'] ?? 'Tên không xác định',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['address'] ?? '',
                                        style: const TextStyle(color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text("05:00 - 22:00"),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () {
                                        // xử lý đặt lịch
                                            if (currentUser == null) {
                                              // Hiển thị thông báo nếu user null
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Vui lòng đăng nhập trước khi xem danh sách phòng')),
                                              );
                                              return;
                                            }
                                            
                                        
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RoomListScreen_User(buildingId: buildings[index].id,  userId: currentUser!.id,    sdt: currentUser!.phoneNumber ?? 'Chưa có SĐT',),
                                          ),
                                        );
                                      },
                                      
                                      child: Text('Xem danh sách phòng'),
                                    ),
                                    
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
      
      ),
      bottomNavigationBar: BottomNavigationBar(
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
Widget _buildFilterChip(String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Chip(
      label: Text(label),
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

Widget _buildSportIcon(String label, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.green.shade800),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}