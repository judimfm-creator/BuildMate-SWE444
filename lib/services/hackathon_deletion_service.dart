import 'package:cloud_firestore/cloud_firestore.dart';

class HackathonDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteHackathonCompletely(String hackathonId) async {
    final hackathonRef = _firestore.collection('hackathons').doc(hackathonId);
    final hackathonSnapshot = await hackathonRef.get();

    if (!hackathonSnapshot.exists) {
      throw Exception('Hackathon not found.');
    }

    final hackathonData = hackathonSnapshot.data() as Map<String, dynamic>;
    final String hackathonName =
        (hackathonData['name'] ?? 'The hackathon').toString();

    final teamPostsSnapshot = await _firestore
        .collection('team_posts')
        .where('hackathonId', isEqualTo: hackathonId)
        .get();

    final joinRequestsSnapshot = await _firestore
        .collection('join_requests')
        .where('hackathonId', isEqualTo: hackathonId)
        .get();

    final registrationsSnapshot = await _firestore
        .collection('registrations')
        .where('hackathonId', isEqualTo: hackathonId)
        .get();

    final Set<String> affectedUserIds = {};

    for (final doc in teamPostsSnapshot.docs) {
      final data = doc.data();

      final createdBy = data['createdBy'];
      if (createdBy is String && createdBy.isNotEmpty) {
        affectedUserIds.add(createdBy);
      }

      final leaderId = data['leaderId'];
      if (leaderId is String && leaderId.isNotEmpty) {
        affectedUserIds.add(leaderId);
      }

      final members = data['members'];
      if (members is List) {
        for (final member in members) {
          if (member is String && member.isNotEmpty) {
            affectedUserIds.add(member);
          }
        }
      }
    }

    for (final doc in joinRequestsSnapshot.docs) {
      final data = doc.data();

      final userId = data['userId'];
      if (userId is String && userId.isNotEmpty) {
        affectedUserIds.add(userId);
      }

      final senderId = data['senderId'];
      if (senderId is String && senderId.isNotEmpty) {
        affectedUserIds.add(senderId);
      }

      final requesterId = data['requesterId'];
      if (requesterId is String && requesterId.isNotEmpty) {
        affectedUserIds.add(requesterId);
      }
    }

    for (final doc in registrationsSnapshot.docs) {
      final data = doc.data();

      final userId = data['userId'];
      if (userId is String && userId.isNotEmpty) {
        affectedUserIds.add(userId);
      }

      final leaderId = data['leaderId'];
      if (leaderId is String && leaderId.isNotEmpty) {
        affectedUserIds.add(leaderId);
      }

      final memberIds = data['memberIds'];
      if (memberIds is List) {
        for (final memberId in memberIds) {
          if (memberId is String && memberId.isNotEmpty) {
            affectedUserIds.add(memberId);
          }
        }
      }
    }

    for (final userId in affectedUserIds) {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Hackathon Deleted',
        'message': 'The hackathon "$hackathonName" has been deleted.',
        'hackathonId': hackathonId,
        'type': 'hackathon_deleted',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final batch = _firestore.batch();

    for (final doc in teamPostsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in joinRequestsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in registrationsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(hackathonRef);

    await batch.commit();
  }
}