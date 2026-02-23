import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/model/org_model.dart';

class OrgProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<OrgModel?> get orgDataStream {
    String uid = _auth.currentUser?.uid ?? "";
    return _firestore.collection('organizations').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return OrgModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

 Future<void> updateOrgProfile({
    required String name,
    required String phone,
    required String location,
    required String bio,
    String? image, // ✅ أضفنا حقل الصورة هنا
    required BuildContext context,
  }) async {
    try {
      String uid = _auth.currentUser?.uid ?? "";
      await _firestore.collection('organizations').doc(uid).update({
        'orgName': name,
        'phoneNumber': phone,
        'location': location,
        'biography': bio,
        'profilePhotoPath': image, // ✅ الحين فايربيز بيمسح الصورة لو أرسلنا نص فارغ
      });
      // شلنا السناك بار من هنا عشان نتحكم فيه في الصفحة زي اليوزر
    } catch (e) {
      debugPrint("Update Failed: $e");
    }
  }

  Future<void> deleteAccount(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. إعادة التحقق من الهوية
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;

    // 2. حذف بيانات المنشأة من Firestore
    await _firestore.collection('organizations').doc(uid).delete();

    // 3. حذف الحساب من Firebase Auth
    await user.delete();

    // 4. تسجيل الخروج
    await _auth.signOut();
  }
    }