
// Firestore Service for PhieuSuaChua (Repair Ticket)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/phieu_sua_chua.dart';

class PhieuSuaChuaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addPhieuSuaChua(PhieuSuaChua phieuSuaChua) async {
    try {
      await _firestore
          .collection('phieuSuaChua')
          .add(phieuSuaChua.toFirestore());
    } catch (e) {
      throw Exception('Failed to save repair ticket: $e');
    }
  }

  Future<List<PhieuSuaChua>> getPhieuSuaChuaByRoom(String roomId) async {
    try {
      final querySnapshot = await _firestore
          .collection('phieuSuaChua')
          .where('roomId', isEqualTo: roomId)
          .get();
      return querySnapshot.docs
          .map((doc) => PhieuSuaChua.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair tickets: $e');
    }
  }

  Future<void> savePhieuSuaChua(PhieuSuaChua phieu) async {
    try {
      if (phieu.id == null) {
        await _firestore.collection('phieuSuaChua').add(phieu.toFirestore());
      } else {
        await _firestore
            .collection('phieuSuaChua')
            .doc(phieu.id)
            .update(phieu.toFirestore());
      }
    } catch (e) {
      throw Exception('Failed to save repair ticket: $e');
    }
  }

  Future<void> deletePhieuSuaChua(String phieuId) async {
    try {
      await _firestore.collection('phieuSuaChua').doc(phieuId).delete();
    } catch (e) {
      throw Exception('Failed to delete repair ticket: $e');
    }
  }
}