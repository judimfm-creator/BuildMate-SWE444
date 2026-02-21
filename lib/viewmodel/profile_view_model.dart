import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/model/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<UserModel?> get userDataStream {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isEmpty) return Stream.value(null);

    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!);
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
        notifyListeners(); 

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  // ✅ الدالة المحدثة لاستقبال كافة المعاملات وحل الإيرور
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String bio,
    required String city,
    required String linkedin,
    required String github,
    required String gender,
    required BuildContext context,
  }) async {
    _setLoading(true);
    try {
      String uid = _auth.currentUser?.uid ?? "";
      if (uid.isNotEmpty) {
        // تحديث كافة الحقول في فايربيز لضمان ظهور الروابط والبيانات
        await _firestore.collection('users').doc(uid).update({
          'fullName': name.trim(),
          'phoneNumber': phone.trim(),
          'bio': bio.trim(),
          'city': city.trim(),
          'linkedin': linkedin.trim(), // تم توحيد الاسم مع الفايربيز
          'github': github.trim(),     // تم توحيد الاسم مع الفايربيز
          'gender': gender,
        });
        
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully! ✅'),
              backgroundColor: Colors.green,
            ),
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}