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
    required String phone, // ✅ أضفنا هذا المتغير
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
        // ✅ تحديث الحقول في Firestore لتشمل رقم الجوال الجديد
        await _firestore.collection('users').doc(uid).update({
          'fullName': name.trim(),
          'username': username.trim(),
          'phoneNumber': phone.trim(), // ✅ حفظ رقم الجوال
          'bio': bio.trim(),
          'city': city.trim(),
          'skills': skills.trim(),
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


  Future<void> deleteAccount(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;

    await _firestore.collection('users').doc(uid).delete();
    await user.delete();
    await _auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ✅ دالة جديدة لفحص هل رقم الجوال مستخدم مسبقاً
  Future<bool> isPhoneNumberAlreadyExists(String phone) async {
    // نتحقق في مجموعة المستخدمين
    final userQuery = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phone.trim())
        .get();

    if (userQuery.docs.isNotEmpty) return true;

    // نتحقق أيضاً في مجموعة المنشآت لضمان عدم التكرار في النظام كاملاً
    final orgQuery = await _firestore
        .collection('organizations')
        .where('phoneNumber', isEqualTo: phone.trim())
        .get();

    return orgQuery.docs.isNotEmpty;
  }
}