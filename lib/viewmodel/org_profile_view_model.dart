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
  Future<void> DeleteAccount(
    BuildContext context,
    String email,
    String password,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. إعادة التحقق من الهوية (Re-authenticate)
      // ضروري جداً لتأكيد أن الشخص هو صاحب الحساب قبل الحذف النهائي
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);

      String uid = user.uid;

      // 2. الحذف الفعلي لبيانات المنشأة من Firestore
      // ✅ هنا نتأكد من اسم الكولكشن 'organizations'
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(uid)
          .delete();

      // 3. حذف الحساب من قائمة المستخدمين في Firebase Auth
      await user.delete();

      // 4. تسجيل الخروج
      await FirebaseAuth.instance.signOut();

      // 5. التوجيه لصفحة تسجيل الدخول (بدون رسالة نجاح)
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/loginUser', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      // إظهار تنبيه فقط في حال حدوث خطأ (مثل كلمة مرور خاطئة)
      if (context.mounted) {
        String message = "Deletion failed";
        if (e.code == 'wrong-password') message = "Incorrect password";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$message: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }}