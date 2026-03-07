import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/team_model.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TeamModel>> getTeamsByHackathon(String hackathonId) {
    return _firestore
        .collection('teams')
        .where('hackathonId', isEqualTo: hackathonId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<TeamModel>> getTeamsByMember(String userId) {
    return _firestore
        .collection('teams')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}