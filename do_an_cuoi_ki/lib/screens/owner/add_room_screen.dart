import 'package:do_an_cuoi_ki/models/building.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:do_an_cuoi_ki/models/user_role.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';

class CreateBuildingScreen extends StatefulWidget {
  final UserModel currentUser;

  const CreateBuildingScreen({Key? key, required this.currentUser}) : super(key: key);

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

  List<String> _imageUrls = [];
  bool _isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  void _checkAdminRole() {
    setState(() {
      _isAdmin = widget.currentUser.role == UserRole.owner;
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles != null) {
      // TODO: Implement image upload to Firebase Storage
      // For now, we'll just use the local paths
      setState(() {
        _imageUrls.addAll(pickedFiles.map((file) => file.path).toList());
      });
    }
  }

  Future<void> _saveBuilding() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bạn không có quyền tạo nhà trọ mới')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newBuilding = BuildingModel(
        buildingId: _databaseRef.push().key!,
        buildingName: _nameController.text,
        address: _addressController.text,
        totalRooms: int.parse(_totalRoomsController.text),
        managerName: widget.currentUser.name,
        managerPhone: widget.currentUser.phoneNumber,
        managerId: widget.currentUser.id ,
        imageUrls: _imageUrls,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        createdAt: DateTime.now(),
      );

      print('Thông tin nhà trọ: ${newBuilding.toJson()}');
      // await _databaseRef.child(newBuilding.buildingId).set(newBuilding.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo nhà trọ thành công!')),
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

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text('Không có quyền truy cập')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Bạn không có quyền tạo nhà trọ mới',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm nhà trọ mới'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
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
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Người tạo: ${widget.currentUser.name}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Tên nhà trọ'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Địa chỉ'),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _totalRoomsController,
                decoration: InputDecoration(labelText: 'Tổng số phòng'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập số phòng' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _managerNameController,
                decoration: InputDecoration(labelText: widget.currentUser.name),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _managerPhoneController,
                decoration: InputDecoration(labelText: widget.currentUser.phoneNumber),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: InputDecoration(labelText: 'Vĩ độ'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập vĩ độ' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: InputDecoration(labelText: 'Kinh độ'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập kinh độ' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImages,
                child: Text('Chọn hình ảnh'),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _imageUrls.map((url) => Image.network(url, width: 80, height: 80, fit: BoxFit.cover)).toList(),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBuilding,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('LƯU THÔNG TIN'),
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
    super.dispose();
  }
}