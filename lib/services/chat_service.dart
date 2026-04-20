import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // جلب بيانات المستخدم الحالي من Firestore
  Future<UserModel?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  // إرسال رسالة
  Future<void> sendMessage({
    required String teamPostId,
    required String text,
    required String senderId,
    required String senderName,
  }) async {

    final teamDoc = await _firestore
        .collection('team_posts')
        .doc(teamPostId)
        .get();

    final members = List<String>.from(teamDoc.data()?['members'] ?? []);

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

  // real-time
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(
      String teamPostId) {
    return _firestore
        .collection('team_posts')
        .doc(teamPostId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}