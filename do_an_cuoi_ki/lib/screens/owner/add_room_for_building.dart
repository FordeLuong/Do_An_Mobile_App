import 'dart:io';

import 'package:do_an_cuoi_ki/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';




class CreateRoomPage extends StatefulWidget {
  final String buildingId;
  const CreateRoomPage({super.key, required this.buildingId});
  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final List<File> _images = [];
  final RoomService _roomService = RoomService();

  // Form fields
  String title = '';
  String description = '';
  String address = '';
  double price = 0;
  double area = 0;
  int capacity = 1;
  List<String> amenities = [];

  bool isUploading = false;

  Future<void> pickImages() async {
    final images = await _roomService.pickImages();
    setState(() {
      _images.addAll(images);
    });
  }

  // 

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => isUploading = true);

    // final roomId = const Uuid().v4();
    // final ownerId = FirebaseFirestore.instance.app.options.projectId; // Hoặc FirebaseAuth nếu có

    try {
     await _roomService.createRoom(
        context: context,
        buildingId: widget.buildingId,
        title: title,
        description: description,
        address: address,
        price: price,
        area: area,
        capacity: capacity,
        amenities: amenities,
        images: _images,
        // ownerId: currentUser?.id, // Thêm nếu có thông tin user
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tạo phòng thành công!")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xảy ra lỗi khi tạo phòng.")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo phòng mới")),
      body: isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Tiêu đề"),
                      onSaved: (value) => title = value ?? '',
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Mô tả"),
                      maxLines: 3,
                      onSaved: (value) => description = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Địa chỉ"),
                      onSaved: (value) => address = value ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Giá thuê"),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => price = double.tryParse(value ?? '0') ?? 0,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Diện tích (m²)"),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => area = double.tryParse(value ?? '0') ?? 0,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Sức chứa"),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => capacity = int.tryParse(value ?? '1') ?? 1,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Tiện nghi (cách nhau bởi dấu phẩy)"),
                      onSaved: (value) =>
                          amenities = value?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._images.map((img) => Image.file(img, width: 100, height: 100, fit: BoxFit.cover)),
                        InkWell(
                          onTap: pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.add),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submit,
                      child: const Text("Tạo phòng"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
