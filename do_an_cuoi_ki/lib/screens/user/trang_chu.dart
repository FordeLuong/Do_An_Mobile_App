import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/screens/auth/login_screen.dart';
import 'package:do_an_cuoi_ki/screens/auth/register_screen.dart';
// import 'package:do_an_cuoi_ki/screens/auth/register_screen.dart'; // Bạn có thể thêm lại nếu cần màn hình đăng ký riêng

import 'package:do_an_cuoi_ki/screens/user/room_list_screen_user.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class TrangChu extends StatelessWidget {
  UserModel? currentUser;
  final Function(UserModel?) onUserUpdated;
  TrangChu({super.key, required this.currentUser, required this.onUserUpdated});
  String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

  // Các biến trạng thái cho bộ lọc (ví dụ)
  // Bạn sẽ cần quản lý trạng thái này thực tế hơn (ví dụ dùng StatefulWidget hoặc State Management)
  final String _selectedKhuVuc = 'Toàn quốc';
  final String _selectedLoaiHinh = 'Phòng trọ';
  final String _selectedMucGia = 'Tất cả';
  final String _selectedSapXep = 'Tin mới trước';


  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền tổng thể nhẹ nhàng hơn
      body: Column(
        children: [
          // PHẦN TOP BAR (GIỮ NGUYÊN NHƯ TRONG CODE CỦA BẠN)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.shade800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 5), // An toàn với tai thỏ
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
                                    onUserUpdated(result);
                                  }
                                }
                              : null, // Vô hiệu hóa khi có user
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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
                            onPressed: currentUser == null
                              ? () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => RegisterPage()),
                                  );
                                  if (result != null && result is UserModel) {
                                    onUserUpdated(result);
                                  }
                                }
                              : null,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                            ),
                            child: const Text("Đăng kí", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Tìm kiếm nhà trọ...",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                        icon: Icon(Icons.favorite_border, color: Colors.green.shade800,),
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Xem danh sách yêu thích!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                 const SizedBox(height: 10),
              ],
            ),
          ),

          // PHẦN BỘ LỌC MỚI (DỰA THEO ẢNH THAM KHẢO)
          Container(
            color: Colors.white, // Nền trắng cho phần bộ lọc
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                // Dòng Khu vực
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      const Text("Khu vực:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedKhuVuc,
                            items: <String>['Toàn quốc', 'TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              // setState(() { _selectedKhuVuc = newValue!; }); // Cần StatefulWidget
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã chọn khu vực: $newValue')),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dòng Lọc chính
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list_alt, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text("Lọc", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _buildFilterChip("Loại hình", _selectedLoaiHinh, ['Phòng trọ', 'Chung cư mini', 'Nhà nguyên căn'], (val) {
                        // setState(() { _selectedLoaiHinh = val; });
                      }),
                      _buildFilterChip("Mức giá", _selectedMucGia, ['Tất cả', 'Dưới 2 triệu', '2 - 4 triệu', 'Trên 4 triệu'], (val) {
                        // setState(() { _selectedMucGia = val; });
                      }),
                      _buildFilterChip("Tiện ích", "Tất cả", ['Có gác', 'Điều hòa', 'An ninh tốt', 'WC riêng'], (val) {
                        // Handle selection
                      }),
                      // Thêm các chip lọc khác nếu cần
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1,),
                // Dòng Tất cả, Cá nhân, Môi giới và Sắp xếp
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: (){
                          // Hiển thị dialog sắp xếp
                        },
                        child: Row(
                          children: [
                            Text(_selectedSapXep, style: TextStyle(color: Colors.green.shade700)),
                            Icon(Icons.swap_vert, color: Colors.green.shade700),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            )
          ),


          // DANH SÁCH NHÀ TRỌ DẠNG GRID
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('buildings')
                  // .where('managerId', isEqualTo: currentUser.id) // Lọc theo managerId (nếu cần)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Không có nhà trọ nào."));
                }

                final buildings = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 item mỗi hàng
                    crossAxisSpacing: 8.0, // Khoảng cách ngang giữa các item
                    mainAxisSpacing: 8.0, // Khoảng cách dọc giữa các item
                    childAspectRatio: 0.7, // Tỷ lệ của item (width / height), điều chỉnh cho phù hợp
                  ),
                  itemCount: buildings.length,
                  itemBuilder: (context, index) {
                    final data = buildings[index].data() as Map<String, dynamic>;
                    final buildingId = buildings[index].id;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      clipBehavior: Clip.antiAlias, // Để ClipRRect hoạt động đúng với Card
                      child: InkWell( // Để có hiệu ứng khi nhấn
                        onTap: () {
                           if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng đăng nhập để xem chi tiết')),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoomListScreen_User(
                                  buildingId: buildingId,
                                  userId: currentUser!.id,
                                  sdt: currentUser!.phoneNumber ?? 'Chưa có SĐT',
                                  userName: currentUser!.name,
                                ),
                              ),
                            );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9, // Tỷ lệ cho ảnh
                                  child: CachedNetworkImage(
                                    imageUrl: data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty
                                        ? data['imageUrls'][0]
                                        : 'https://via.placeholder.com/300x200.png?text=No+Image', // Ảnh mặc định
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0,)),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40, color: Colors.grey,),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.black.withOpacity(0.4),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.favorite_border, color: Colors.white, size: 18,),
                                      onPressed: () {
                                         ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Thêm vào yêu thích!')),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['buildingName'] ?? 'N/A',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          data['address'] ?? 'N/A',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                   const SizedBox(height: 2),
                                  Text(
                                      "Giá từ: ${NumberFormat.compactCurrency(locale: 'vi_VN', symbol: 'đ').format(data['minPrice'] ?? 0)}", // Ví dụ, bạn cần có trường minPrice trong data
                                      style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                    ),
                                  // Không còn nút "Xem danh sách phòng" ở đây nữa vì cả card đã có thể nhấn
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
    );
  }

  // Helper widget cho các chip filter có dropdown
  Widget _buildFilterChip(String label, String currentValue, List<String> options, Function(String) onSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          return options.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
        child: Chip(
          backgroundColor: Colors.orange.shade100,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
              Text(": $currentValue", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
              Icon(Icons.arrow_drop_down, size: 16, color: Colors.orange.shade800),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.orange.shade300)
          ),
        ),
      ),
    );
  }

  // Helper widget cho các icon danh mục
  Widget _buildCategoryIcon(String label, IconData icon, VoidCallback onTap) {
    List<String> labelParts = label.split('\n');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10)
              ),
              child: Icon(icon, color: Colors.green.shade700, size: 28),
            ),
            const SizedBox(height: 4),
            if (labelParts.length == 1)
              Text(labelParts[0], style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
            if (labelParts.length > 1)
              Column(
                children: labelParts.map((part) => Text(part, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)).toList(),
              )
          ],
        ),
      ),
    );
  }
}