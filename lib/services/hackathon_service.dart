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
          .timeout(const Duration(seconds: 12)); // test save

      return docRef;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Hackathon>> getHackathonsByIds(List<String> hackathonIds) async {
    if (hackathonIds.isEmpty) return [];

    final uniqueIds = hackathonIds.toSet().toList();
    List<Hackathon> result = [];

    for (int i = 0; i < uniqueIds.length; i += 10) {
      final batch = uniqueIds.skip(i).take(10).toList();

      final snapshot = await _firestore
          .collection('hackathons')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      result.addAll(snapshot.docs.map((doc) => Hackathon.fromFirestore(doc)));
    }

    return result;
  }
}