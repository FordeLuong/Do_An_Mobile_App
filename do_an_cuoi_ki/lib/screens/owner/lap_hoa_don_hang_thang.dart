import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/bill/bill.dart';
import 'package:do_an_cuoi_ki/models/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class BillManagementScreen extends StatefulWidget {
  const BillManagementScreen({super.key,required this.currentUser,required this.buildingId});
  final UserModel currentUser;
  final String buildingId;

  @override
  _BillManagementScreenState createState() => _BillManagementScreenState();
}

class _BillManagementScreenState extends State<BillManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserModel currentUser;
  late String buildingId;
  
  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser; 
    buildingId = widget.buildingId;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Hóa Đơn'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chưa Lập HĐ'),
            Tab(text: 'Chờ Thanh Toán'),
            Tab(text: 'Đã Thanh Toán'),
          ],
          labelColor: const Color.fromARGB(255, 10, 10, 10),
          unselectedLabelColor: const Color.fromARGB(179, 131, 129, 129),
          indicatorColor: const Color.fromARGB(255, 228, 234, 54),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Phòng chưa lập hóa đơn
          _buildUnbilledRoomsTab(currentUser, buildingId),
          
          // Tab 2: Hóa đơn chờ thanh toán
          _buildPendingBillsTab(buildingId),
          
          // Tab 3: Hóa đơn đã thanh toán
          _buildPaidBillsTab(buildingId),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Thêm chức năng tạo hóa đơn mới
          _showCreateBillDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUnbilledRoomsTab(UserModel currentUser, String buildingId) {
  final now = DateTime.now();
  final currentMonthYear = '${now.month.toString().padLeft(2, '0')}/${now.year}';

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('rooms').where('buildingId', isEqualTo: buildingId).where('status',isEqualTo: 'rented').snapshots(),
    builder: (context, roomsSnapshot) {
      if (roomsSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!roomsSnapshot.hasData || roomsSnapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Không có phòng nào'));
      }

      // Lấy danh sách tất cả các phòng
      final allRooms = roomsSnapshot.data!.docs;

      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('bills')
            .where('thangNam', isEqualTo: currentMonthYear)
            .get(),
        builder: (context, billsSnapshot) {
          if (billsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lấy danh sách các phòng đã có hóa đơn trong tháng này
          final billedRoomIds = billsSnapshot.data?.docs
                  .map((bill) => bill['roomId'] as String)
                  .toSet() ??
              <String>{};

          // Lọc ra các phòng chưa có hóa đơn
          final unbilledRooms = allRooms
              .where((room) => !billedRoomIds.contains(room.id))
              .toList();

          if (unbilledRooms.isEmpty) {
            return const Center(child: Text('Tất cả phòng đã có hóa đơn tháng này'));
          }

          return ListView.builder(
            itemCount: unbilledRooms.length,
            itemBuilder: (context, index) {
              final room = unbilledRooms[index].data() as Map<String, dynamic>;
              final roomId = unbilledRooms[index].id;
              final ownerId = room['ownerId'] as String? ?? '';
              final sodien = (room['sodien'] as num?)?.toInt() ?? 0;
              final songuoi = (room['capacity'] as num?)?.toInt() ?? 0;
              final roomPrice = (room['price'] as num?)?.toDouble() ?? 0.0;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(room['title'] ?? 'Phòng không tên'),
                  subtitle: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('bills')
                        .where('roomId', isEqualTo: roomId)
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .get(),
                    builder: (context, lastBillSnapshot) {
                      if (lastBillSnapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Đang tải...');
                      }

                      String lastBilledText = 'Chưa có hóa đơn';
                      if (lastBillSnapshot.hasData && 
                          lastBillSnapshot.data!.docs.isNotEmpty) {
                        final lastBill = lastBillSnapshot.data!.docs.first;
                        final lastBillDate = (lastBill['date'] as Timestamp).toDate();
                        lastBilledText = 'Lần cuối: ${DateFormat('MM/yyyy').format(lastBillDate)}';
                      }
                      return Text(lastBilledText);
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.receipt),
                    onPressed: () => _createBillForRoom(roomId,currentUser.id,ownerId,sodien,songuoi,roomPrice),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

  Widget _buildPendingBillsTab(String? selectedBuildingId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('bills')
        .where('status', isEqualTo: 'pending') // Lọc các hóa đơn chờ thanh toán
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Không có hóa đơn chờ thanh toán'));
      }

      // Lọc bills ngay trong builder thay vì trong stream
      return FutureBuilder<List<DocumentSnapshot>>(
        future: _filterBillsByBuilding(snapshot.data!.docs, selectedBuildingId),
        builder: (context, filteredSnapshot) {
          if (filteredSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingBills = filteredSnapshot.data!.map((doc) {
            return BillModel.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();

          if (pendingBills.isEmpty) {
            return const Center(child: Text('Không có hóa đơn chờ thanh toán cho tòa nhà này'));
          }

          return ListView.builder(
            itemCount: pendingBills.length,
            itemBuilder: (context, index) {
              final bill = pendingBills[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: FutureBuilder<String?>(
                    future: getRoomTitleById(bill.roomId),
                    builder: (context, roomSnapshot) {
                      if (roomSnapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Đang tải tên phòng...');
                      }
                      return Text('HĐ ${bill.thangNam} - Phòng ${roomSnapshot.data ?? 'Không xác định'}');
                    },
                  ),
                  subtitle: Text('Tổng: ${NumberFormat.currency(locale: 'vi').format(bill.sumPrice)}'),
                  children: [
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ExpansionTile(
                        title: Text('Hóa Đơn'),
                        subtitle: Text('Thông tin hóa đơn:'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildBillDetailRow('Tiền điện:', bill.tienDien),
                                _buildBillDetailRow('Tiền nước:', bill.tienNuoc),
                                _buildBillDetailRow('Tiền phòng:', bill.priceRoom),
                                _buildBillDetailRow('Tiện ích khác:', bill.amenitiesPrice),
                                const Divider(),
                                _buildBillDetailRow('Tổng cộng:', bill.sumPrice, isTotal: true),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _updateBillStatus(bill.id, PaymentStatus.paid),
                                      child: const Text('Đánh dấu đã thanh toán'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
// Hàm cập nhật trạng thái hóa đơn
void _updateBillStatus(String billId, PaymentStatus status) async {
  try {
    await FirebaseFirestore.instance
        .collection('bills')
        .doc(billId)
        .update({
          'status': status.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật trạng thái thành ${_getStatusText(status)}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi khi cập nhật: ${e.toString()}')),
    );
  }
}

String _getStatusText(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
      return 'Đã thanh toán';
    case PaymentStatus.pending:
      return 'Chờ thanh toán';
    case PaymentStatus.overdue:
      return 'Quá hạn';
  }
}

 Widget _buildPaidBillsTab(String? selectedBuildingId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('bills')
        .where('status', isEqualTo: 'paid')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Không có hóa đơn đã thanh toán'));
      }

      // Lọc bills ngay trong builder thay vì trong stream
      return FutureBuilder<List<DocumentSnapshot>>(
        future: _filterBillsByBuilding(snapshot.data!.docs, selectedBuildingId),
        builder: (context, filteredSnapshot) {
          if (filteredSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final paidBills = filteredSnapshot.data!.map((doc) {
            return BillModel.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();

          if (paidBills.isEmpty) {
            return const Center(child: Text('Không có hóa đơn đã thanh toán cho tòa nhà này'));
          }

          return ListView.builder(
            itemCount: paidBills.length,
            itemBuilder: (context, index) {
              final bill = paidBills[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: FutureBuilder<String?>(
                    future: getRoomTitleById(bill.roomId),
                    builder: (context, roomSnapshot) {
                      if (roomSnapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Đang tải tên phòng...');
                      }
                      return Text('HĐ ${bill.thangNam} - Phòng ${roomSnapshot.data ?? 'Không xác định'}');
                    },
                  ),
                  // ... Phần còn lại giữ nguyên
                   subtitle: Text('Tổng: ${NumberFormat.currency(locale: 'vi').format(bill.sumPrice)}'),
                    children: [
                      // ... các widget con khác
                      Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ExpansionTile( 
                          title: Text('Hóa Đơn'),
                          subtitle: Text('Thông tin hóa đơn :'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildBillDetailRow('Tiền điện:', bill.tienDien),
                                  _buildBillDetailRow('Tiền nước:', bill.tienNuoc),
                                  _buildBillDetailRow('Tiền phòng:', bill.priceRoom),
                                  _buildBillDetailRow('Tiện ích khác:', bill.amenitiesPrice),
                                  const Divider(),
                                  _buildBillDetailRow('Tổng cộng:', bill.sumPrice, isTotal: true),
                                  const SizedBox(height: 10),
                                  
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

  Widget _buildBillDetailRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
          Text(
            NumberFormat.currency(locale: 'vi').format(value),
            style: isTotal
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }

void _createBillForRoom(String roomId,String owneridForbill, String tenantidForbill ,int sodien, int songuoi, double price) {
  final now = DateTime.now();
  final currentMonthYear = '${now.month.toString().padLeft(2, '0')}/${now.year}';
  
  // Sử dụng các biến state để theo dõi thay đổi
  int sodienCu = sodien;
  int sodienMoi = 0;
  int soNguoi = songuoi;
  double priceRoom = price;
  double priceDien = 3500;
  double priceWater = 50000;
  double amenitiesPrice = 0;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Hàm tính tổng tiền
          double calculateTotal() {
            return (sodienMoi - sodienCu) * priceDien + 
                   priceWater * soNguoi + 
                   priceRoom + 
                   amenitiesPrice;
          }

          return AlertDialog(
            title: const Text('Tạo hóa đơn mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tháng: $currentMonthYear', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Số điện
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Số điện cũ (kWh)'),
                          keyboardType: TextInputType.number,
                          initialValue:sodienCu.toString(),
                          onChanged: (value) {
                            setState(() {
                              sodienCu = int.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Số điện mới (kwh)'),
                          keyboardType: TextInputType.number,
                          
                          onChanged: (value) {
                            setState(() {
                              sodienMoi = int.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Số người và giá nước
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Số người'),
                          keyboardType: TextInputType.number,
                          initialValue: songuoi.toString(),
                          onChanged: (value) {
                            setState(() {
                              soNguoi = int.tryParse(value) ?? 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Giá nước/người'),
                          keyboardType: TextInputType.number,
                          initialValue: '50000',
                          onChanged: (value) {
                            setState(() {
                              priceWater = double.tryParse(value) ?? 50000;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Giá phòng và tiện ích
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Giá phòng'),
                    keyboardType: TextInputType.number,
                    initialValue: price.toString(),
                    onChanged: (value) {
                      setState(() {
                        priceRoom = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Tiện ích khác'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        amenitiesPrice = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  
                  // Tóm tắt - Sẽ tự động cập nhật khi có thay đổi
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          _buildSummaryRow('Tiền điện:', '${(sodienMoi - sodienCu) * priceDien} đ'),
                          _buildSummaryRow('Tiền nước:', '${priceWater * soNguoi} đ'),
                          _buildSummaryRow('Tiền phòng:', '$priceRoom đ'),
                          _buildSummaryRow('Tiện ích:', '$amenitiesPrice đ'),
                          const Divider(),
                          _buildSummaryRow(
                            'Tổng cộng:',
                            '${calculateTotal()} đ',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Tạo và lưu hóa đơn
                  final newBill = BillModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    roomId: roomId,
                    ownerId: owneridForbill, // Thay bằng ownerId thực tế
                    khachThueId: tenantidForbill, // Thay bằng tenantId thực tế
                    sodienCu: sodienCu,
                    sodienMoi: sodienMoi,
                    soNguoi: soNguoi,
                    priceRoom: priceRoom,
                    priceDien: priceDien,
                    priceWater: priceWater,
                    amenitiesPrice: amenitiesPrice,
                    date: now,
                    thangNam: currentMonthYear,
                    sumPrice: calculateTotal(),
                    status: PaymentStatus.pending,
                  );
                  final batch = FirebaseFirestore.instance.batch();
                  final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
                  batch.update(roomRef, {
                    'sodien': sodienMoi, // Cập nhật số điện mới
                    'updatedAt': FieldValue.serverTimestamp(), // Thêm thời gian cập nhật
                  });
                  FirebaseFirestore.instance
                      .collection('bills')
                      .doc(newBill.id)
                      .set(newBill.toJson())
                      .then((_) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã tạo hóa đơn thành công!')),
                    );
                  });
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      );
    },
  );
}
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(value, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }


  void _showCreateBillDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tạo hóa đơn mới'),
          content: const Text('Chọn phòng để lập hóa đơn:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Chuyển đến màn hình tạo hóa đơn
              },
              child: const Text('Tiếp tục'),
            ),
          ],
        );
      },
    );
  }

}
Future<String?> getRoomTitleById(String roomId) async {
  try {
    final DocumentSnapshot roomSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .get();

    if (roomSnapshot.exists) {
      final data = roomSnapshot.data() as Map<String, dynamic>;
      return data['title'] as String?; // Trả về trực tiếp giá trị title
    }
    return null; // Trả về null nếu phòng không tồn tại
  } catch (e) {
    print('Error fetching room title: $e');
    return null; // Trả về null nếu có lỗi
  }
}



Future<List<DocumentSnapshot>> _filterBillsByBuilding(
    List<DocumentSnapshot> bills, String? buildingId) async {
  if (buildingId == null) return bills;

  // Lấy tất cả phòng thuộc building
  final roomsQuery = await FirebaseFirestore.instance
      .collection('rooms')
      .where('buildingId', isEqualTo: buildingId)
      .get();

  if (roomsQuery.docs.isEmpty) return [];

  final roomIds = roomsQuery.docs.map((doc) => doc.id).toList();
  
  // Lọc bills chỉ giữ lại những bill có roomId thuộc building
  return bills.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return roomIds.contains(data['roomId']);
  }).toList();
}