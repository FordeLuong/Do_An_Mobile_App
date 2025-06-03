import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';




class ThanhLyHopDong extends StatefulWidget {
  const ThanhLyHopDong({super.key, required this.currentUser, required this.roomId});
  final UserModel currentUser;
  final String roomId;

  @override
  _ThanhLyHopDongState createState() => _ThanhLyHopDongState();
}

class _ThanhLyHopDongState extends State<ThanhLyHopDong>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserModel currentUser;
  late String roomId;
  int _currentStep = 0;
  bool _step1Completed = false;
  bool _step2Completed = false;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    roomId=widget.roomId;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    
    // Kiểm tra điều kiện trước khi cho phép chuyển tab
    if (_tabController.index == 1 && !_step1Completed) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng hoàn thành bước 1 trước')),
      );
      return;
    }
    
    if (_tabController.index == 2 && !_step2Completed) {
      _tabController.animateTo(_step1Completed ? 1 : 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng hoàn thành bước 2 trước')),
      );
      return;
    }
    
    setState(() {
      _currentStep = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _completeStep1() {
    setState(() {
      _step1Completed = true;
      _tabController.animateTo(1); // Tự động chuyển sang tab 2 khi hoàn thành
    });
  }

  void _completeStep2() {
    setState(() {
      _step2Completed = true;
      _tabController.animateTo(2); // Tự động chuyển sang tab 3 khi hoàn thành
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trả Phòng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'Kiểm tra hiện trạng',
              icon: _step1Completed
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
            Tab(
              text: 'Đối chiếu hợp đồng',
              icon: _step2Completed
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
            Tab(
              text: 'Hoan tra cọc và Hủy hợp đồng',
            ),
          ],
          labelColor: const Color.fromARGB(255, 10, 10, 10),
          unselectedLabelColor: const Color.fromARGB(179, 131, 129, 129),
          indicatorColor: const Color.fromARGB(255, 228, 234, 54),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Ngăn vuốt chuyển tab
        children: [
          // Tab 1: Phòng chưa lập hóa đơn
          _kiemtraphong(currentUser,roomId, _completeStep1),
          
          // Tab 2: Hóa đơn chờ thanh toán
          _doichieuhopdong(_completeStep2,roomId),
          
          // Tab 3: Hóa đơn đã thanh toán
          _tracochoanthanh(),
        ],
      ),
      floatingActionButton: _currentStep == 0
          ? FloatingActionButton(
              onPressed: () {
                _showCreateBillDialog();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

 Widget _kiemtraphong(UserModel user, String roomId, VoidCallback onComplete) {
  // Danh sách các khoản bồi thường (ban đầu có 1 dòng trống)
  List<Map<String, dynamic>> compensationData = [
    {'stt': 1, 'info': '', 'cost': ''},
  ];

  // Controllers cho các ô nhập liệu
  List<TextEditingController> infoControllers = [
    TextEditingController(text: ''),
  ];
  List<TextEditingController> costControllers = [
    TextEditingController(text: ''),
  ];

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return Column(
        children: [
          // Bảng thông tin bồi thường
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 15,
              columns: const [
                DataColumn(
                  label: Text(
                    'STT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Thông tin bồi thường',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Chi phí (VND)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(''),
                ),
              ],
              rows: List<DataRow>.generate(
                compensationData.length,
                (index) {
                  return DataRow(
                    cells: [
                      DataCell(Text((index + 1).toString())),
                      DataCell(
                        SizedBox(
                          width: 150,
                          height: 30,
                          child: TextField(
                            controller: infoControllers[index],
                            decoration: const InputDecoration(
                              hintText: 'Nhập thông tin',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              compensationData[index]['info'] = value;
                            },
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: costControllers[index],
                            decoration: const InputDecoration(
                              hintText: 'Chi phí',
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              compensationData[index]['cost'] = value;
                            },
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            if (compensationData.length > 1) {
                              setState(() {
                                compensationData.removeAt(index);
                                infoControllers.removeAt(index);
                                costControllers.removeAt(index);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Nút thêm dòng mới
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Thêm dòng'),
              onPressed: () {
                setState(() {
                  compensationData.add({
                    'stt': compensationData.length + 1,
                    'info': '',
                    'cost': ''
                  });
                  infoControllers.add(TextEditingController(text: ''));
                  costControllers.add(TextEditingController(text: ''));
                });
              },
            ),
          ),

          // Nút hoàn thành bước 1
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                ContractModel? tmp = await findActiveContractByRoomId(roomId);
                bool hasErrors = false;
                List<String> errorMessages = [];

                for (int i = 0; i < compensationData.length; i++) {
                  final info = compensationData[i]['info'].toString().trim();
                  final costStr = compensationData[i]['cost'].toString().trim();

                  if (info.isNotEmpty || costStr.isNotEmpty) {
                    if (info.isEmpty) {
                      hasErrors = true;
                      errorMessages.add('Dòng ${i + 1}: Thiếu thông tin bồi thường');
                    }

                    if (costStr.isNotEmpty) {
                      final cost = double.tryParse(costStr);
                      if (cost == null) {
                        hasErrors = true;
                        errorMessages.add('Dòng ${i + 1}: Chi phí phải là số');
                      } else if (cost <= 0) {
                        hasErrors = true;
                        errorMessages.add('Dòng ${i + 1}: Chi phí phải lớn hơn 0');
                      } else {
                        compensationData[i]['cost'] = cost;
                      }
                    }
                  }
                }

                if (hasErrors) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: errorMessages
                            .map((msg) => Text(msg, style: TextStyle(color: Colors.white)))
                            .toList(),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: errorMessages.length),
                    ),
                  );
                } else {
                  try {
                    // Hiển thị loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    // Lưu dữ liệu lên Firestore
                    await saveCompensationData(compensationData,tmp!.id);

                    // Đóng loading và chuyển bước
                    Navigator.of(context).pop();
                    onComplete();
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi lưu dữ liệu: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Hoàn thành bước 1'),
            ),
          ),
        ],
      );
    },
  );
}

  Widget _doichieuhopdong(VoidCallback onComplete, String roomId) {
  return FutureBuilder<ContractModel?>(
    // Giả sử có hàm fetchContractById để lấy thông tin hợp đồng từ Firestore/API
    future: findActiveContractByRoomId(roomId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Lỗi: ${snapshot.error}'));
      }

      if (!snapshot.hasData) {
        return const Center(child: Text('Không tìm thấy hợp đồng'));
      }

      final contract = snapshot.data!;

      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildContractInfoItem('Mã hợp đồng', contract.id),
                _buildContractInfoItem('Mã phòng', contract.roomId),
                _buildContractInfoItem('Mã người thuê', contract.tenantId),
                _buildContractInfoItem('Ngày bắt đầu', 
                  DateFormat('dd/MM/yyyy').format(contract.startDate)),
                _buildContractInfoItem('Ngày kết thúc', 
                  DateFormat('dd/MM/yyyy').format(contract.endDate)),
                _buildContractInfoItem('Tiền thuê', 
                  '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(contract.rentAmount)}/tháng'),
                _buildContractInfoItem('Tiền cọc', 
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(contract.depositAmount)),
                _buildContractInfoItem('Trạng thái', 
                  contract.status.name), // Giả sử có phương thức displayName trong ContractStatus
                if (contract.termsAndConditions != null)
                  _buildContractInfoItem('Điều khoản', contract.termsAndConditions!),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  // Hiển thị loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  // Cập nhật trạng thái phòng trong Firestore
                  await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(contract.roomId) // Sử dụng roomId từ hợp đồng
                      .update({
                        'status': 'available',
                        'updatedAt': FieldValue.serverTimestamp(),
                        'ownerId':'',
                      });
                  await FirebaseFirestore.instance
                      .collection('contracts')
                      .doc(contract.id) // Sử dụng roomId từ hợp đồng
                      .update({
                        'status': 'expired',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                  // Đóng dialog loading
                  Navigator.of(context).pop();

                  // Gọi callback onComplete nếu cần
                  onComplete();

                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật trạng thái phòng thành công')),
                  );
                } catch (e) {
                  // Đóng dialog loading nếu có lỗi
                  Navigator.of(context).pop();
                  
                  // Hiển thị thông báo lỗi
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi cập nhật: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Hoàn thành'),
            ),
          ),
        ],
      );
    },
  );
}

// Widget phụ để hiển thị từng thông tin hợp đồng
Widget _buildContractInfoItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

  Widget _tracochoanthanh() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          const Text(
            'Đã hoàn thành tất cả thao tác',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Đóng giao diện hiện tại và trở về màn hình trước
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.done_all),
            label: const Text(
              'XÁC NHẬN HOÀN THÀNH',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateBillDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo hóa đơn mới'),
        content: const Text('Chức năng tạo hóa đơn mới sẽ được triển khai ở đây.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

Future<void> saveCompensationData(List<Map<String, dynamic>> compensationData, String ContactID) async {
  try {
    // Lấy user hiện tại

    // Lọc dữ liệu hợp lệ
    final validItems = compensationData.where((item) => 
      item['info'].toString().trim().isNotEmpty || 
      item['cost'].toString().trim().isNotEmpty
    ).toList();

    // Tính tổng chi phí
    final total = validItems.fold(0.0, (sum, item) {
      final cost = item['cost'] is String 
          ? double.tryParse(item['cost']) ?? 0 
          : item['cost'] as double;
      return sum + cost;
    });

    // Chuẩn bị dữ liệu
    final compensationDoc = {
      'ContactID': ContactID,
      'createdAt': FieldValue.serverTimestamp(),
      'items': validItems,
      'totalAmount': total,
      'date':DateTime.now()
    };

    // Lưu lên Firestore
    await FirebaseFirestore.instance
        .collection('compensations')
        .add(compensationDoc);

    debugPrint('Dữ liệu đã được lưu thành công');
  } catch (e) {
    debugPrint('Lỗi khi lưu dữ liệu: $e');
    rethrow;
  }
}

Future<ContractModel?> findActiveContractByRoomId(String roomId) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('contracts') // tên collection bạn dùng trong Firestore
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: ContractStatus.active.toJson())
        .limit(1) // chỉ lấy 1 bản ghi đầu tiên nếu có
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final data = querySnapshot.docs.first.data();
      return ContractModel.fromJson(data);
    } else {
      return null; // Không tìm thấy
    }
  } catch (e) {
    print('Lỗi khi tìm hợp đồng: $e');
    return null;
  }
}