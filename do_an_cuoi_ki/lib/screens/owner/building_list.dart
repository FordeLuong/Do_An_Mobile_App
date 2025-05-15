import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/screens/owner/add_room_for_building.dart';
import 'package:do_an_cuoi_ki/screens/owner/room_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class BuildingListScreen_2 extends StatelessWidget {
  const BuildingListScreen_2({super.key, required this.currentUser});
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: const Text("Sân gần bạn"),
      //   backgroundColor: Colors.green.shade800,
      //   actions: [
      //     IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
      //   ],
      // ),
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
                      currentUser.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    
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
                    
                  ],
                ),
              ],
            ),
          ),


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
                .where('managerId', isEqualTo: currentUser.id) // Lọc theo managerId
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
                                        
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RoomListScreen(buildingId: buildings[index].id),
                                          ),
                                        );
                                      },
                                      
                                      child: Text('Xem danh sách phòng'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      onPressed: () {
                                        // xử lý đặt lịch
                                        
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CreateRoomPage(buildingId: buildings[index].id),
                                          ),
                                        );
                                      },
                                      
                                      child: Text('Tạo Phòng'),
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
      // bottomNavigationBar: BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color.fromARGB(255, 186, 203, 91),
      //   backgroundColor: Colors.green.shade800,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
      //     BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Bản đồ'),
      //     BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Tạo trọ mới'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
      //   ],
      // ),
    );
  }
}

