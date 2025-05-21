import 'dart:io';
import 'package:do_an_cuoi_ki/models/room.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



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
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  Future<List<String>> uploadImages(String roomId) async {
    List<String> urls = [];

    for (int i = 0; i < _images.length; i++) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('rooms')
          .child(roomId)
          .child('img_$i.jpg');

      await ref.putFile(_images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => isUploading = true);

    final roomId = const Uuid().v4();
    final ownerId = FirebaseFirestore.instance.app.options.projectId; // Hoặc FirebaseAuth nếu có

    try {
      final imageUrls = await uploadImages(roomId);

      final room = RoomModel(
        id: roomId,
        buildingId: widget.buildingId,
        ownerId: '',
        title: title,
        description: description,
        address: address,
        latitude: 0,
        longitude: 0,
        price: price,
        area: area,
        capacity: capacity,
        amenities: amenities,
        imageUrls: imageUrls,
        status: RoomStatus.available,
        createdAt: DateTime.now(),
        updatedAt: null,
        sodien: 0,
      );

      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set(room.toJson());

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
