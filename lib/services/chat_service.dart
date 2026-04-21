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

    if (!teamDoc.exists) return;

    final data = teamDoc.data() ?? {};
    final members = List<String>.from(data['members'] ?? []);
    
    // 🔴 التعديل الجوهري للأمان:
    // نتحقق أن المستخدم موجود في قائمة الأعضاء النشطين (members)
    // وليس في قائمة المطرودين (removedMembers)
    if (!members.contains(senderId)) {
      print("Access Denied: User is not an active member of this team.");
      return; 
    }

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
      'readBy': [senderId], // أضفنا المرسل لقائمة القراء تلقائياً عند الإرسال
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