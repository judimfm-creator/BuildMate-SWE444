import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/hackathon.dart';

class HackathonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentReference<Map<String, dynamic>>> createHackathon(Hackathon hackathon) async {
    try {
      final docRef = await _firestore
          .collection('hackathons')
          .add({
        ...hackathon.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      })
          .timeout(const Duration(seconds: 12));// test save

      return docRef;
    } catch (e) {
      rethrow;
    }
  }
}