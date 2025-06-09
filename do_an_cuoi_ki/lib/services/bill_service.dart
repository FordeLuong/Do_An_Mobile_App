import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/bill/bill.dart';
import 'package:flutter/material.dart';
import 'package:do_an_cuoi_ki/models/phieu_sua_chua.dart';
class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy tất cả hóa đơn trong tháng hiện tại
  Future<QuerySnapshot> getBillsForCurrentMonth() {
    final now = DateTime.now();
    final currentMonthYear = '${now.month.toString().padLeft(2, '0')}/${now.year}';
    
    return _firestore
        .collection('bills')
        .where('thangNam', isEqualTo: currentMonthYear)
        .get();
  }

 


  Stream<QuerySnapshot> getPendingBills() {
    return _firestore
        .collection('bills')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Lọc hóa đơn theo tòa nhà
  Future<List<DocumentSnapshot>> filterBillsByBuilding(
    List<DocumentSnapshot> bills,
    String? buildingId,
  ) async {
    if (buildingId == null || buildingId.isEmpty) {
      return bills;
    }

    final filteredBills = <DocumentSnapshot>[];
    for (final bill in bills) {
      final roomId = bill['roomId'] as String;
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (roomDoc.exists && roomDoc['buildingId'] == buildingId) {
        filteredBills.add(bill);
      }
    }
    return filteredBills;
  }


  // Cập nhật trạng thái hóa đơn
  Future<void> updateBillStatus(String billId, PaymentStatus status) async {
    await _firestore.collection('bills').doc(billId).update({
      'status': status.toString().split('.').last,
      'paidAt': Timestamp.now(),
    });
  }

  // Helper method để tạo BillModel từ DocumentSnapshot
  BillModel billFromSnapshot(DocumentSnapshot doc) {
    return BillModel.fromJson(doc.data() as Map<String, dynamic>);
  }


    Future<bool> updateBillStatus2({
    required String billId, 
    required PaymentStatus status,

  }) async {
    try {
      await _firestore.collection('bills').doc(billId).update({
        'status': status.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Thêm trường paidAt nếu trạng thái là paid
        if (status == PaymentStatus.paid) 'paidAt': FieldValue.serverTimestamp(),
      });

      // Hiển thị thông báo thành công
     
      
      return true;
    } catch (e) {
      // Hiển thị thông báo lỗi
    
      return false;
    }
  }


  Stream<QuerySnapshot> getPaidBillsStream() {
    return _firestore
        .collection('bills')
        .where('status', isEqualTo: PaymentStatus.paid.toJson())
        .snapshots();
  }



   Future<void> createBill({
    required String roomId,
    required String ownerId,
    required String tenantId,
    required int oldElectricity,
    required int newElectricity,
    required int numberOfPeople,
    required double roomPrice,
    required double electricityPrice,
    required double waterPrice,
    required double amenitiesPrice,
    required DateTime date,
    required String monthYear,
    required double totalPrice,
  }) async {
<<<<<<< Updated upstream
  try {
    // Tính phí sửa chữa
    double repairCost = 0.0;
    final phieuSnapshot = await _firestore
        .collection('phieu_sua')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: RepairStatus.completed.name)
        .where('faultSource', isEqualTo: FaultSource.tenant.name)
        .get();

    for (var doc in phieuSnapshot.docs) {
      final phieu = PhieuSuaChua.fromFirestore(doc, null);
      repairCost += phieu.tongTien;
    }
    // Kiểm tra xem hóa đơn đã tồn tại hay chưa
    final newBill = BillModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      ownerId: ownerId, // Thay bằng ownerId thực tế
      khachThueId: tenantId, // Thay bằng tenantId thực tế
      sodienCu: oldElectricity,
      sodienMoi: newElectricity,
      soNguoi: numberOfPeople,
      priceRoom: roomPrice,
      priceDien: electricityPrice,
      priceWater: waterPrice,
      amenitiesPrice: amenitiesPrice,
      date: date,
      thangNam: monthYear,
      sumPrice: totalPrice,
      status: PaymentStatus.pending,
    );
    final batch = FirebaseFirestore.instance.batch();
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    batch.update(roomRef, {
      'sodien': newElectricity, // Cập nhật số điện mới
      'updatedAt': FieldValue.serverTimestamp(), // Thêm thời gian cập nhật
    });
    FirebaseFirestore.instance
        .collection('bills')
        .doc(newBill.id)
        .set(newBill.toJson());
  } catch (e) {
    // Handle the error, e.g., print or log it
    print('Error creating bill: $e');
=======
 
      final newBill = BillModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    roomId: roomId,
                    ownerId: ownerId, // Thay bằng ownerId thực tế
                    khachThueId: tenantId, // Thay bằng tenantId thực tế
                    sodienCu: oldElectricity,
                    sodienMoi: newElectricity,
                    soNguoi: numberOfPeople,
                    priceRoom: roomPrice,
                    priceDien: electricityPrice,
                    priceWater: waterPrice,
                    amenitiesPrice: amenitiesPrice,
                    date: date,
                    thangNam: monthYear,
                    sumPrice: totalPrice,
                    status: PaymentStatus.pending,
                  );
                  final batch = FirebaseFirestore.instance.batch();
                  final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
                  batch.update(roomRef, {
                    'sodien': newElectricity, // Cập nhật số điện mới
                    'updatedAt': FieldValue.serverTimestamp(), // Thêm thời gian cập nhật
                  });
                  batch.commit();
                  FirebaseFirestore.instance
                      .collection('bills')
                      .doc(newBill.id)
                      .set(newBill.toJson()
                     
                  );
   
>>>>>>> Stashed changes
  }
}
}