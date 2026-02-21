import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/model/org_model.dart';

class OrgProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // جلب بيانات المنظمة (Stream) لتحويلها لـ OrgModel
  Stream<OrgModel?> get orgDataStream {
    String uid = _auth.currentUser?.uid ?? "";
    return _firestore.collection('organizations').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return OrgModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // دالة رفع الصورة (Logo) وتحديث المسار
  Future<void> uploadOrgPhoto(File imageFile, BuildContext context) async {
    try {
      String uid = _auth.currentUser?.uid ?? "";
      await _firestore.collection('organizations').doc(uid).update({
        'profilePhotoPath': imageFile.path,
      });
      notifyListeners();
      _showSnackBar(context, "Logo updated successfully!", Colors.green);
    } catch (e) {
      _showSnackBar(context, "Error updating logo: $e", Colors.red);
    }
  }

  // دالة تحديث البيانات الأساسية (تستخدم نفس مسميات الـ OrgModel في Firestore)
  Future<void> updateOrgProfile({
    required String name,
    required String phone,
    required String location,
    required String bio,
    required BuildContext context,
  }) async {
    try {
      String uid = _auth.currentUser?.uid ?? "";
      await _firestore.collection('organizations').doc(uid).update({
        'orgName': name,
        'phoneNumber': phone,
        'location': location,
        'biography': bio,
      });
      notifyListeners();
      _showSnackBar(context, "Profile updated successfully!", Colors.green);
    } catch (e) {
      _showSnackBar(context, "Error updating profile: $e", Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}