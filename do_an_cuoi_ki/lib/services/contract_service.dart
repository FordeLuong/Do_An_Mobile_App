import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/room.dart';
import 'package:do_an_cuoi_ki/screens/owner/Contract/lap_hop_dong.dart';
import 'package:flutter/material.dart';

class ContractService {
  final FirebaseFirestore _firestore;

  ContractService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createContract({
    required BuildContext context,
    required String roomId,
    required String ownerId,
    required String tenantId,
    required DateTime startDate,
    required ContractDuration duration,
    required double rentAmount,
    required double depositAmount,
    required String terms,
    required DepositOption depositOption,
  }) async {
    try {
      final endDate = _calculateEndDate(startDate, duration);
      final newContractRef = _firestore.collection('contracts').doc();
      final contractId = newContractRef.id;

      final contractStatus = depositOption == DepositOption.payNow
          ? ContractStatus.active
          : ContractStatus.pending;

      final newContract = ContractModel(
        id: contractId,
        roomId: roomId,
        tenantId: tenantId,
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
        rentAmount: rentAmount,
        depositAmount: depositAmount,
        termsAndConditions: terms,
        status: contractStatus,
        paymentHistoryIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await newContractRef.set(newContract.toJson());

      final batch = _firestore.batch();
      final roomRef = _firestore.collection('rooms').doc(roomId);

      final roomNewStatus = contractStatus == ContractStatus.active
          ? RoomStatus.rented
          : RoomStatus.pending_payment;

      batch.update(roomRef, {
        'status': roomNewStatus.toJson(),
        'currentTenantId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hợp đồng đã được tạo với trạng thái: ${contractStatus.getDisplayName()}'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Lỗi khi tạo hợp đồng: ${e.toString()}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tạo hợp đồng: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  DateTime _calculateEndDate(DateTime startDate, ContractDuration duration) {
    int monthsToAdd = duration == ContractDuration.sixMonths ? 6 : 12;
    var newMonth = startDate.month + monthsToAdd;
    var newYear = startDate.year;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    var day = startDate.day;
    var daysInTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (day > daysInTargetMonth) {
      day = daysInTargetMonth;
    }
    return DateTime(newYear, newMonth, day, startDate.hour, startDate.minute, startDate.second);
  }
}
