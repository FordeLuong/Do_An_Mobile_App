// Firestore Service for DonViSuaChua (Repair Service Provider)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_cuoi_ki/models/DVSC.dart';

class DonViSuaChuaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DonViSuaChua>> getDonViSuaChuaList() async {
    try {
      final querySnapshot = await _firestore.collection('DonViSuaChuas').get();
      return querySnapshot.docs
          .map((doc) => DonViSuaChua.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair service providers: $e');
    }
  }
}

