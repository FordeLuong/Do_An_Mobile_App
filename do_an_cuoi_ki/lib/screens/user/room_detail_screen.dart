import 'package:flutter/material.dart';
import '/models/room.dart';

class RoomDetailScreen extends StatelessWidget {
  final RoomModel room;

  const RoomDetailScreen({Key? key, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room.title),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 250,
            child: PageView.builder(
              itemCount: room.imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  room.imageUrls[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          ListTile(
            title: const Text('Địa chỉ'),
            subtitle: Text(room.address),
          ),
          ListTile(
            title: const Text('Giá thuê'),
            subtitle: Text('${room.price.toStringAsFixed(0)} VNĐ / tháng'),
          ),
          ListTile(
            title: const Text('Diện tích'),
            subtitle: Text('${room.area} m²'),
          ),
          ListTile(
            title: const Text('Sức chứa'),
            subtitle: Text('${room.capacity} người'),
          ),
          ListTile(
            title: const Text('Tiện nghi'),
            subtitle: Text(room.amenities.join(', ')),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text('Gọi cho chủ trọ'),
              onPressed: () {
                // Thêm logic gọi điện tại đây
              },
            ),
          ),
        ],
      ),
    );
  }
}
