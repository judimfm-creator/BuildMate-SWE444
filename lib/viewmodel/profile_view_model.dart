import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/model/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser; // متغير داخلي لحفظ بيانات المستخدم
  UserModel? get currentUser => _currentUser; // ✅ الـ Getter الذي تحتاجه الواجهة

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<UserModel?> get userDataStream {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return Stream.value(null);

    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // تحديث المتغير المحلي وتنبيه الواجهات
        _currentUser = UserModel.fromMap(snapshot.data()!);
        notifyListeners();
        return _currentUser;
      }
      return null;
    });
  }

  Future<void> uploadProfilePhoto(File imageFile, BuildContext context) async {
    _setLoading(true);
    try {
      String uid = _auth.currentUser?.uid ?? "";
      if (uid.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update({
          'profilePhotoPath': imageFile.path,
        });
        // لا نحتاج notifyListeners هنا لأن الـ Stream سيقوم بالتحديث تلقائياً

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    required String name,
    required String username,
    required String phone,
    required String bio,
    required String city,
    required String skills,
    required String linkedin,
    required String github,
    required String gender,
    required BuildContext context,
  }) async {
    _setLoading(true);
    try {
      String uid = _auth.currentUser?.uid ?? "";
      if (uid.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update({
          'fullName': name.trim(),
          'username': username.trim(),
          'phoneNumber': phone.trim(),
          'bio': bio.trim(),
          'city': city.trim(),
          'skills': skills.trim(), // ✅ تأكدنا من إضافة المهارات هنا للحفظ
          'linkedin': linkedin.trim(),
          'github': github.trim(),
          'gender': gender,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully! ✅'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount(BuildContext context, String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      String uid = user.uid;
      await _firestore.collection('users').doc(uid).delete();
      await user.delete();
      await _auth.signOut();
      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/loginUser', (route) => false);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  Future<void> DeleteAccount(
    BuildContext context,
    String email,
    String password,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. إعادة التحقق من الهوية (ضروري قبل الحذف)
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);

      String uid = user.uid;

      // 2. الحذف الفعلي من Firestore 
      // (تأكدي من تغيير 'users' إلى 'organizations' إذا كنتِ في مودل المنظمة)
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // 3. حذف الحساب من Authentication
      await user.delete();

      // 4. تسجيل الخروج
      await FirebaseAuth.instance.signOut();

      // 5. التوجيه لصفحة تسجيل الدخول مباشرة (بدون رسالة نجاح)
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/loginUser', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      // إظهار رسالة في حال الخطأ فقط (مثل كلمة مرور خاطئة)
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
  }
}