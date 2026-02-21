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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully! ✅")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update Failed: $e ❌")));
    }
  }
}