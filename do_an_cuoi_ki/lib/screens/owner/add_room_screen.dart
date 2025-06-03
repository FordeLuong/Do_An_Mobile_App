import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/building.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/models/user_role.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class CreateBuildingScreen extends StatefulWidget {
  final UserModel currentUser;

  const CreateBuildingScreen({super.key, required this.currentUser});

  @override
  _CreateBuildingScreenState createState() => _CreateBuildingScreenState();
}

class _CreateBuildingScreenState extends State<CreateBuildingScreen> {
  final _formKey = GlobalKey<FormState>();
    
  final FirebaseDatabase database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://db-ql-tro-default-rtdb.firebaseio.com/',
  );
  
  DatabaseReference get _databaseRef => database.ref('buildings');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _totalRoomsController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _managerPhoneController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  final List<String> _imageUrls = [];
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _isUploadingImages = false;
  double _uploadProgress = 0;
  LatLng _selectedPosition = const LatLng(10.7769, 106.7009); // Mặc định TP.HCM
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _managerNameController.text = widget.currentUser.name;
    _managerPhoneController.text = widget.currentUser.phoneNumber ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation(); // Gọi sau khi build xong
    });
  }

  void _checkAdminRole() {
    setState(() {
      _isAdmin = widget.currentUser.role == UserRole.owner;
    });
  }
  //Lấy vị trí hiện tại khi mở tab
  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra dịch vụ định vị
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật dịch vụ định vị')),
        );
        return;
      }

      // Kiểm tra và yêu cầu quyền
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
          );
          // Hiển thị dialog yêu cầu cấp quyền
          // _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng vào cài đặt để cấp quyền.'),
          ),
        );
        return;
      }

      // Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _mapController.move(_selectedPosition, 15);
      });

      // Reverse geocoding để lấy địa chỉ
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final address = [
            placemark.street,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country,
          ].where((element) => element != null && element.isNotEmpty).join(', ');
          setState(() {
            _addressController.text = address;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy địa chỉ: ${e.toString()}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy vị trí: ${e.toString()}')),
      );
    }
  }
  // Nếu cần hiển thị dialog yêu cầu quyền truy cập vị trí, có thể sử dụng đoạn code sau:(do nó lag văng app nên em ẩn ạạ)
  // void _showPermissionDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Yêu cầu quyền truy cập vị trí'),
  //       content: const Text('Ứng dụng cần truy cập vị trí của bạn để hiển thị vị trí hiện tại trên bản đồ. Vui lòng cấp quyền.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Hủy'),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             Navigator.pop(context);
  //             LocationPermission permission = await Geolocator.requestPermission();
  //             if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
  //               _getCurrentLocation(); // Thử lại sau khi cấp quyền
  //             }
  //           },
  //           child: const Text('Cấp quyền'),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFiles.isEmpty) return;

    // Kiểm tra số lượng ảnh
    if (pickedFiles.length + _imageUrls.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 10 ảnh được phép tải lên')),
      );
      return;
    }

    setState(() {
      _isUploadingImages = true;
      _uploadProgress = 0;
    });

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
          setState(() {
            _uploadProgress = (uploadedCount + taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) / pickedFiles.length;
          });
        });

        await uploadTask;

        final downloadUrl = await fileRef.getDownloadURL();
        uploadedUrls.add(downloadUrl);
        uploadedCount++;
      }

      setState(() {
        _imageUrls.addAll(uploadedUrls);
        _isUploadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải ảnh: ${e.toString()}')),
      );
    }
  }

  // Future<void> _saveBuilding() async {
  //   if (!_formKey.currentState!.validate()) return;
  //   if (!_isAdmin) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Bạn không có quyền tạo nhà trọ mới')),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });
    
  //   try {
  //     final newBuilding = BuildingModel(
  //       buildingId: _databaseRef.push().key!,
  //       buildingName: _nameController.text,
  //       address: _addressController.text,
  //       totalRooms: int.parse(_totalRoomsController.text),
  //       managerName: widget.currentUser.name,
  //       managerPhone: widget.currentUser.phoneNumber,
  //       managerId: widget.currentUser.id,
  //       imageUrls: _imageUrls,
  //       latitude: double.parse(_latitudeController.text),
  //       longitude: double.parse(_longitudeController.text),
  //       createdAt: DateTime.now(),
  //     );

  //     await _databaseRef.child(newBuilding.buildingId).set(newBuilding.toJson());

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Tạo nhà trọ thành công!')),
  //     );
  //     Navigator.pop(context);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Lỗi khi tạo nhà trọ: ${e.toString()}')),
  //     );
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }


  Future<void> _saveBuilding() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền tạo nhà trọ mới')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final buildingId = FirebaseFirestore.instance.collection('buildings').doc().id;

      final newBuilding = BuildingModel(
        buildingId: buildingId,
        buildingName: _nameController.text,
        address: _addressController.text,
        totalRooms: int.parse(_totalRoomsController.text),
        managerName: widget.currentUser.name,
        managerPhone: widget.currentUser.phoneNumber,
        managerId: widget.currentUser.id,
        imageUrls: _imageUrls,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .set(newBuilding.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo nhà trọ thành công!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo nhà trọ: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _selectedPosition = LatLng(location.latitude, location.longitude);
          _latitudeController.text = location.latitude.toString();
          _longitudeController.text = location.longitude.toString();
          _addressController.text = query;
          _mapController.move(_selectedPosition, 15);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy địa điểm')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tìm kiếm: ${e.toString()}')),
      );
    }
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _selectedPosition = point;
      _latitudeController.text = point.latitude.toString();
      _longitudeController.text = point.longitude.toString();
    });

    // Reverse geocoding để lấy địa chỉ
    try {
      final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        setState(() {
          _addressController.text = address;
        });
      } else {
        setState(() {
          _addressController.text = 'Không xác định được địa chỉ';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy địa chỉ: ${e.toString()}')),
      );
    }
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.center,
      _mapController.zoom + 1,
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.center,
      _mapController.zoom - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không có quyền truy cập')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Bạn không có quyền tạo nhà trọ mới',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm nhà trọ mới'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: widget.currentUser.profileImageUrl != null
                  ? NetworkImage(widget.currentUser.profileImageUrl!)
                  : null,
              child: widget.currentUser.profileImageUrl == null
                  ? Text(widget.currentUser.name[0])
                  : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Người tạo: ${widget.currentUser.name}', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên nhà trọ'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalRoomsController,
                decoration: const InputDecoration(labelText: 'Tổng số phòng'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập số phòng' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _managerNameController,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Tên quản lý'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _managerPhoneController,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Số điện thoại quản lý'),
                keyboardType: TextInputType.phone,
              ),
              // const SizedBox(height: 16),
              // TextFormField(
              //   controller: _addressController,
              //   decoration: const InputDecoration(labelText: 'Địa chỉ'),
              //   validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              //   onChanged: (value) {
              //     _searchLocation(value); // Tự động tìm kiếm trên bản đồ khi nhập địa chỉ
              //   },
              // ),
              const SizedBox(height: 16),
              const Text(
                'Chọn vị trí trên bản đồ:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Địa chỉ'),
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _searchLocation(_addressController.text),
                    child: const Text('Tìm'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 400,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPosition,
                        initialZoom: 13,
                        onTap: (tapPosition, point) => _onMapTap(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedPosition,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Nhấp vào bản đồ để chọn vị trí',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          backgroundColor: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 50,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            onPressed: _zoomIn,
                            mini: true,
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            onPressed: _zoomOut,
                            mini: true,
                            child: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: 'Vĩ độ'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value!.isEmpty ? 'Vui lòng chọn vị trí' : null,
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: 'Kinh độ'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value!.isEmpty ? 'Vui lòng chọn vị trí' : null,
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploadingImages ? null : _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Chọn hình ảnh (Tối đa 10)'),
              ),
              if (_isUploadingImages) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text(
                  'Đang tải lên ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              _imageUrls.isEmpty
                  ? const Text(
                      'Chưa có hình ảnh',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_imageUrls.length, (index) {
                        return Stack(
                          children: [
                            Image.network(
                              _imageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBuilding,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('LƯU THÔNG TIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _totalRoomsController.dispose();
    _managerNameController.dispose();
    _managerPhoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}