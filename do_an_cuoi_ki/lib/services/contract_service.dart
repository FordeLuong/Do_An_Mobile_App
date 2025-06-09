import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/contract/contract.dart';
import 'package:do_an_cuoi_ki/models/contract/contract_status.dart';
import 'package:do_an_cuoi_ki/models/room.dart';

class ContractService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createContract(ContractModel contract) async {
    await _firestore.collection('contracts').doc(contract.id).set(contract.toJson());
  }

  Future<void> updateRoomStatusAfterContract(
    String roomId, 
    String tenantId, 
    RoomStatus newStatus,
  ) async {
    final batch = _firestore.batch();
    final roomRef = _firestore.collection('rooms').doc(roomId);
    
    batch.update(roomRef, {
      'status': newStatus.toJson(),
      'ownerId': tenantId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    await batch.commit();
  }


    Stream<QuerySnapshot> getContractsByOwner(String ownerId) {
    return _firestore
        .collection('contracts')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Cập nhật trạng thái hợp đồng
  Future<void> updateContractStatus({
    required String contractId,
    required ContractStatus newStatus,
  }) async {
    await _firestore.collection('contracts').doc(contractId).update({
      'status': newStatus.toJson(),
      'updatedAt': Timestamp.now(),
    });
  }

  // Chuyển đổi DocumentSnapshot thành ContractModel
  ContractModel parseContractDocument(DocumentSnapshot contractDoc) {
    Map<String, dynamic> data = contractDoc.data() as Map<String, dynamic>;
    if (!data.containsKey('id') || (data['id'] as String? ?? '').isEmpty) {
      data['id'] = contractDoc.id;
    }
    return ContractModel.fromJson(data);
  }


   Future<ContractModel?> findActiveContractByRoomId(String roomId) async {
    try {
      final querySnapshot = await _firestore
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

  /// Cập nhật trạng thái hợp đồng
  Future<void> updateContractStatus1(String contractId, ContractStatus status) async {
    try {
      await _firestore
          .collection('contracts')
          .doc(contractId)
          .update({
            'status': status.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Lỗi khi cập nhật hợp đồng: $e');
      rethrow;
    }
  }
   Future<ContractModel?> getActiveContractForTenant(String tenantId) async {
    try {
      final contractsSnapshot = await _firestore
          .collection('contracts')
          .where('tenantId', isEqualTo: tenantId)
          .where('status', isEqualTo: ContractStatus.active.toJson())
          .limit(1)
          .get();

      if (contractsSnapshot.docs.isNotEmpty) {
        final contractData = contractsSnapshot.docs.first.data();
        if (!contractData.containsKey('id')) {
          contractData['id'] = contractsSnapshot.docs.first.id;
        }
        return ContractModel.fromJson(contractData);
      }
      return null;
    } catch (e) {
      print("Error getting active contract: $e");
      return null;
    }
  }
}