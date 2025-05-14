import 'package:flutter/material.dart';
import '/models/room.dart';
import 'dart:math';

class NearbyRoomsScreen extends StatefulWidget {
  final List<RoomModel> allRooms;
  final double userLat;
  final double userLng;

  const NearbyRoomsScreen({
    Key? key,
    required this.allRooms,
    required this.userLat,
    required this.userLng,
  }) : super(key: key);

  @override
  _NearbyRoomsScreenState createState() => _NearbyRoomsScreenState();
}

class _NearbyRoomsScreenState extends State<NearbyRoomsScreen> {
  late List<RoomModel> availableRooms;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeRooms();
  }

  /// Khởi tạo danh sách phòng và sắp xếp theo khoảng cách
  void _initializeRooms() {
    // Lọc những phòng còn trống
    availableRooms = widget.allRooms.where((room) => room.status == RoomStatus.available).toList();

    // Sắp xếp theo khoảng cách gần nhất
    availableRooms.sort((a, b) {
      final distA = calculateDistance(widget.userLat, widget.userLng, a.latitude, a.longitude);
      final distB = calculateDistance(widget.userLat, widget.userLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    // Tắt trạng thái loading sau khi xử lý xong
    setState(() {
      _isLoading = false;
    });
  }

  /// Làm mới danh sách phòng (có thể gọi khi cần)
  void _refreshRooms() {
    setState(() {
      _isLoading = true;
    });
    _initializeRooms();
  }

  /// Tính khoảng cách theo công thức Haversine
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng trọ gần bạn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRooms, // Nút làm mới danh sách phòng
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Hiển thị loading
          : availableRooms.isEmpty
              ? const Center(child: Text('Không có phòng trọ nào gần bạn'))
              : ListView.builder(
                  itemCount: availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = availableRooms[index];
                    final distance =
                        calculateDistance(widget.userLat, widget.userLng, room.latitude, room.longitude);

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: room.imageUrls.isNotEmpty
                            ? Image.network(room.imageUrls[0], width: 60, fit: BoxFit.cover)
                            : const Icon(Icons.home),
                        title: Text(room.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Giá: ${room.price.toStringAsFixed(0)} VNĐ'),
                            Text('Cách bạn: ${distance.toStringAsFixed(2)} km'),
                            Text('Địa chỉ: ${room.address}'),
                          ],
                        ),
                        onTap: () {
                          // Mở chi tiết phòng (nếu có màn chi tiết)
                        },
                      ),
                    );
                  },
                ),
    );
  }
}