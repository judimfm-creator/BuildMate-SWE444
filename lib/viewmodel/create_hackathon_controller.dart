import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/hackathon.dart';
import '../services/hackathon_service.dart';

class CreateHackathonController {
  final HackathonService _service = HackathonService();

  Future<String> submit(Hackathon hackathon) async {
    final docRef = await _service.createHackathon(hackathon);
    return docRef.id;
  }
}