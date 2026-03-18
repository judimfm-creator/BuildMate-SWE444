import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/team_model.dart';
import '../model/team_post_model.dart';

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

  Future<void> sendJoinRequest({
    required String teamId,
    required String userId,
    required int teamSize,
  }) async {
    final teamRef = _firestore.collection('teams').doc(teamId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(teamRef);

      if (!snapshot.exists) {
        throw Exception("Team not found");
      }

      final data = snapshot.data() as Map<String, dynamic>;

      final memberIds = (data['memberIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final pendingRequests = (data['pendingRequests'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (memberIds.contains(userId)) {
        throw Exception("You are already a member of this team");
      }

      if (pendingRequests.contains(userId)) {
        throw Exception("You already sent a request");
      }

      if (memberIds.length >= teamSize) {
        throw Exception("This team is full");
      }

      transaction.update(teamRef, {
        'pendingRequests': FieldValue.arrayUnion([userId]),
      });
    });
  }

  Future<DocumentReference> createTeamPost(TeamPostModel post) async {
    return await _firestore.collection('team_posts').add(post.toMap());
  }
}