import '../model/hackathon.dart';
import '../services/hackathon_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateHackathonController {
  final HackathonService _service = HackathonService();

  Future<String> submit(Hackathon hackathon) async {
    final docRef = await _service.createHackathon(hackathon);
    return docRef.id;
  }

  Future<void> update(Hackathon hackathon) async {
    await FirebaseFirestore.instance
        .collection('hackathons')
        .doc(hackathon.id)
        .update(hackathon.toMap());
  }

}