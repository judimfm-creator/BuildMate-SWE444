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
    String? image, 
    required BuildContext context,
  }) async {
    try {
      String uid = _auth.currentUser?.uid ?? "";
      
      // نجهز البيانات الأساسية
      Map<String, dynamic> data = {
        'orgName': name,
        'phoneNumber': phone,
        'location': location,
        'biography': bio,
      };

      // الحل هنا: لا نرسل حقل الصورة للفايربيز إلا لو كان فيه قيمة (تحديث أو حذف متعمد)
      if (image != null) {
        data['profilePhotoPath'] = image;
      }

      await _firestore.collection('organizations').doc(uid).update(data);
      
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