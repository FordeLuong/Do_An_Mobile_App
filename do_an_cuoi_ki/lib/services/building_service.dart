import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
class BuildingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  // Lấy stream tất cả các tòa nhà
  Stream<QuerySnapshot> getAllBuildingsStream() {
    return _firestore.collection('buildings').snapshots();
  }
  Stream<QuerySnapshot> getBuildingsByManagerStream(String managerId) {
    return _firestore
        .collection('buildings')
        .where('managerId', isEqualTo: managerId)
        .snapshots();
  }
  Future<String> createBuilding({
    required BuildContext context,
    required bool isAdmin,
    required String buildingName,
    required String address,
    required int totalRooms,
    required String managerName,
    required String managerPhone,
    required String managerId,
    required List<String> imageUrls,
    required double latitude,
    required double longitude,
  }) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền tạo nhà trọ mới')),
      );
      return 'Bạn không có quyền tạo nhà trọ mới';
    }

    try {
      final buildingId = _firestore.collection('buildings').doc().id;

      final newBuilding = {
        'buildingId': buildingId,
        'buildingName': buildingName,
        'address': address,
        'totalRooms': totalRooms,
        'managerName': managerName,
        'managerPhone': managerPhone,
        'managerId': managerId,
        'imageUrls': imageUrls,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': DateTime.now(),
      };

      await _firestore
          .collection('buildings')
          .doc(buildingId)
          .set(newBuilding);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo nhà trọ thành công!')),
      );
      return buildingId; // Trả về ID của building vừa tạo
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo nhà trọ: ${e.toString()}')),
      );
      rethrow; // Ném lại exception để xử lý ở nơi gọi
    }
  }
 
  Future<List<String>> uploadBuildingImages({
    required BuildContext context,
    required List<String> existingUrls,
    int maxImages = 10,
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 85,
    void Function(double)? onProgress,
  }) async {
    // Chọn ảnh từ thiết bị
    final pickedFiles = await _picker.pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (pickedFiles.isEmpty) return existingUrls;

    // Kiểm tra số lượng ảnh
    if (pickedFiles.length + existingUrls.length > maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 10 ảnh được phép tải lên')),
      );
      return existingUrls;
    }

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final List<String> uploadedUrls = [];
      int uploadedCount = 0;

      for (final pickedFile in pickedFiles) {
        final String fileName = 'buildings/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        final fileRef = storageRef.child(fileName);

        // Upload với theo dõi tiến trình
        final uploadTask = fileRef.putFile(File(pickedFile.path));

        uploadTask.snapshotEvents.listen((taskSnapshot) {
          final progress = (uploadedCount + taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) / 
                         pickedFiles.length;
          onProgress?.call(progress);
        });

        await uploadTask;
        final downloadUrl = await fileRef.getDownloadURL();
        uploadedUrls.add(downloadUrl);
        uploadedCount++;
      }

      return [...existingUrls, ...uploadedUrls];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải ảnh: ${e.toString()}')),
      );
      return existingUrls;
    }
  }
 
}