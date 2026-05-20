import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:math';


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> sendFileMessage({
    required String teamPostId,
    required String senderId,
    required String senderName,
    required File file,
    required String fileName,
    required String fileType,
  }) async {
    final teamDoc = await _firestore.collection('team_posts').doc(teamPostId).get();
    final members = List<String>.from(teamDoc.data()?['members'] ?? []);
    final removedList = List<String>.from(teamDoc.data()?['removedMembers'] ?? []);
    if (removedList.contains(senderId) || !members.contains(senderId)) return;

    final safeFileName = "${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\.]'), '_')}";

    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_files/$teamPostId/$safeFileName');

    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    await _firestore
        .collection('team_posts')
        .doc(teamPostId)
        .collection('messages')
        .add({
      'text': '',
      'fileUrl': downloadUrl,
      'fileName': fileName,
      'fileType': fileType,
      'senderId': senderId,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [],
    });
  }

  Future<void> sendMessage({
    required String teamPostId,
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    final teamDoc =
        await _firestore.collection('team_posts').doc(teamPostId).get();

    final members = List<String>.from(teamDoc.data()?['members'] ?? []);


    final removedList =
        List<String>.from(teamDoc.data()?['removedMembers'] ?? []);
    if (removedList.contains(senderId)) return;

    if (!members.contains(senderId)) return;
    if (text.trim().isEmpty) return;

    await _firestore
        .collection('team_posts')
        .doc(teamPostId)
        .collection('messages')
        .add({
      'text': text.trim(),
      'senderId': senderId,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [],
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(
      String teamPostId) {
    return _firestore
        .collection('team_posts')
        .doc(teamPostId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }


  Future<void> restoreMember({
    required String teamPostId,
    required String memberId,
    required String desiredRole,
  }) async {
    await _firestore.collection('team_posts').doc(teamPostId).update({
      'members': FieldValue.arrayUnion([memberId]),
      'memberRoles.$memberId': desiredRole,
      'removedMembers': FieldValue.arrayRemove([memberId]),
      'memberJoinedAt.$memberId': FieldValue.serverTimestamp(),
    });
  }


  Future<void> deleteMessage({
    required String teamPostId,
    required String messageId,
  }) async {
    await _firestore
        .collection('team_posts')
        .doc(teamPostId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }


  Future<void> initiateLeaderVote({
    required String teamPostId,
    required String leavingLeaderId,
    required List<String> eligibleVoters,
  }) async {

    final expiresAt = DateTime.now().add(const Duration(hours: 1));

    final teamRef = _firestore.collection('team_posts').doc(teamPostId);
    final batch = _firestore.batch();

    batch.update(teamRef, {
      'members': FieldValue.arrayRemove([leavingLeaderId]),
      'memberRoles.$leavingLeaderId': FieldValue.delete(),
      'removedMembers': FieldValue.arrayUnion([leavingLeaderId]),
      'removedAt.$leavingLeaderId': FieldValue.serverTimestamp(),
      'createdBy': '',
      'leaderId': '',
      'leaderVote': {
        'active': true,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'votes': <String, String>{},
        'eligibleVoters': eligibleVoters,
        'leavingLeaderId': leavingLeaderId,
      },
    });


    final msgRef = teamRef.collection('messages').doc();
    batch.set(msgRef, {
      'text': 'The team leader has left. Please vote for a new leader. ',
      'senderId': 'system',
      'senderName': 'System',
      'type': 'vote_prompt',
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [],
    });

    await batch.commit();
  }


  Future<void> castLeaderVote({
    required String teamPostId,
    required String voterId,
    required String votedForId,
  }) async {

    await _firestore.collection('team_posts').doc(teamPostId).update({
      'leaderVote.votes.$voterId': votedForId,
    });


    final doc =
        await _firestore.collection('team_posts').doc(teamPostId).get();
    final voteData =
        doc.data()?['leaderVote'] as Map<String, dynamic>?;
    if (voteData == null || voteData['active'] != true) return;

    final eligibleVoters =
        List<String>.from(voteData['eligibleVoters'] ?? []);
    final votes = Map<String, dynamic>.from(voteData['votes'] ?? {});

    final allVoted = eligibleVoters.isNotEmpty &&
        eligibleVoters.every((v) => votes.containsKey(v));

    if (allVoted) {
      await resolveLeaderVote(teamPostId: teamPostId);
    }
  }


  Future<void> resolveLeaderVote({required String teamPostId}) async {
    await _firestore.runTransaction((transaction) async {
      final teamRef =
          _firestore.collection('team_posts').doc(teamPostId);
      final snap = await transaction.get(teamRef);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final voteData = data['leaderVote'] as Map<String, dynamic>?;

      if (voteData == null || voteData['active'] != true) return;

      final votes =
          Map<String, dynamic>.from(voteData['votes'] ?? {});
      final currentMembers = List<String>.from(data['members'] ?? []);

      final Map<String, int> tally = {};
      for (final votedFor in votes.values) {
        final key = votedFor.toString();
        if (currentMembers.contains(key)) {
          tally[key] = (tally[key] ?? 0) + 1;
        }
      }

      String? newLeaderId;

      if (tally.isEmpty) {
        newLeaderId = currentMembers.isNotEmpty ? currentMembers.first : null;
      } else {
        final maxVotes = tally.values.reduce((a, b) => a > b ? a : b);
        final topCandidates = tally.entries
            .where((e) => e.value == maxVotes)
            .map((e) => e.key)
            .toList();

        if (topCandidates.length == 1) {
          newLeaderId = topCandidates.first;
        } else {

          topCandidates.shuffle(Random());
          newLeaderId = topCandidates.first;
        }
      }

      if (newLeaderId == null) return;

      transaction.update(teamRef, {
        'createdBy': newLeaderId,
        'leaderId': newLeaderId,
        'leaderVote.active': false,
        'leaderVote.resolvedAt': FieldValue.serverTimestamp(),
        'leaderVote.winner': newLeaderId,
      });
    });


    final snap =
        await _firestore.collection('team_posts').doc(teamPostId).get();
    final winner = snap.data()?['leaderVote']?['winner'] as String?;
    if (winner == null) return;

    final userDoc =
        await _firestore.collection('users').doc(winner).get();
    final winnerName = userDoc.data()?['fullName'] ?? 'leader';

    final existing = await _firestore
        .collection('team_posts')
        .doc(teamPostId)
        .collection('messages')
        .where('type', isEqualTo: 'vote_result')
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await _firestore
          .collection('team_posts')
          .doc(teamPostId)
          .collection('messages')
          .add({
        'text': '🎉 The new leader is $winnerName ! ',
        'senderId': 'system',
        'senderName': 'System',
        'type': 'vote_result',
        'winnerId': winner,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
      });
    }
  }
}
