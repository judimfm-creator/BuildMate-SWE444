import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

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

  Future<void> sendMessage({
    required String teamPostId,
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    final teamDoc =
        await _firestore.collection('team_posts').doc(teamPostId).get();

    final members = List<String>.from(teamDoc.data()?['members'] ?? []);

    // حماية: المطرود لا يقدر يرسل
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

  // إعادة عضو مطرود — يُحذف من removedMembers ويُضاف لـ memberJoinedAt
  Future<void> restoreMember({
    required String teamPostId,
    required String memberId,
    required String desiredRole,
  }) async {
    await _firestore.collection('team_posts').doc(teamPostId).update({
      'members': FieldValue.arrayUnion([memberId]),
      'memberRoles.$memberId': desiredRole,
      'removedMembers': FieldValue.arrayRemove([memberId]),
      // وقت الانضمام الجديد — نفلتر الرسائل القديمة للعضو الراجع
      'memberJoinedAt.$memberId': FieldValue.serverTimestamp(),
    });
  }

  // حذف رسالة واحدة — للمرسل فقط
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
}
