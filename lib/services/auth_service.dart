import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';
import '../model/org_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. تسجيل مستخدم جديد (Participant)
  Future<void> signUpUser(UserModel user, String password) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(
      email: user.email.trim(), // تم إضافة التريم هنا
      password: password.trim(), // تم إضافة التريم هنا
    );
    await _db.collection('users').doc(res.user!.uid).set(user.toMap());
  }

  // 2. تسجيل منظمة جديدة (Organization)
  Future<void> signUpOrg(OrgModel org, String password) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(
      email: org.email.trim(), // تم إضافة التريم هنا
      password: password.trim(), // تم إضافة التريم هنا
    );
    await _db.collection('organizations').doc(res.user!.uid).set(org.toMap());
  }

  // 3. دالة تسجيل الدخول
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),    // يحذف المسافات من الإيميل
      password: password.trim(), // يحذف المسافات من الباسورد
    );
  }

  // 4. دالة تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }
}