import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';
import '../model/org_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. تسجيل مستخدم جديد (Participant)
  Future<void> signUpUser(UserModel user, String password) async {
    // إنشاء الحساب في Authentication
    UserCredential res = await _auth.createUserWithEmailAndPassword(
      email: user.email.trim(),
      password: password.trim(),
    );
    
    // ✅ الحل النهائي: تحويل البيانات لخريطة (Map) يدوياً لتجنب أي إيرور في النوع
    // هذا يضمن توافق المهارات (Skills) كـ Array فارغ
    final Map<String, dynamic> userData = {
      'uid': res.user!.uid,
      'fullName': user.fullName,
      'username': user.username,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'role': 'user',
      'bio': '',
      'skills': [], // مصفوفة فارغة لتجنب تعليق البروفايل
      'profilePhotoPath': user.profilePhotoPath ?? '',
      'linkedin': '',
      'github': '',
      'profileSetupComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(res.user!.uid).set(userData);
  }

  // 2. تسجيل منظمة جديدة (Organization)
  Future<void> signUpOrg(OrgModel org, String password) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(
      email: org.email.trim(),
      password: password.trim(),
    );
    
    await _db.collection('organizations').doc(res.user!.uid).set(org.toMap());
  }

  // 3. دالة تسجيل الدخول
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // 4. دالة تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }
}