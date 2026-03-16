import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/hackathon.dart';

class OrgHackathonsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _orgId = FirebaseAuth.instance.currentUser?.uid;

  /// الهاكاثونز الحالية — endDate بعد اليوم
  Stream<List<Hackathon>> get ongoingStream {
    if (_orgId == null) return const Stream.empty();
    return _firestore
        .collection('hackathons')
        .where('organizationId', isEqualTo: _orgId)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map((d) => Hackathon.fromFirestore(d))
          .where((h) => h.endDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
    });
  }

  /// الهاكاثونز المنتهية — endDate قبل أو يساوي اليوم
  Stream<List<Hackathon>> get pastStream {
    if (_orgId == null) return const Stream.empty();
    return _firestore
        .collection('hackathons')
        .where('organizationId', isEqualTo: _orgId)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map((d) => Hackathon.fromFirestore(d))
          .where((h) => !h.endDate.isAfter(now))
          .toList()
        ..sort((a, b) => b.endDate.compareTo(a.endDate));
    });
  }

  /// حذف هاكاثون
  Future<void> deleteHackathon(String id) async {
    await _firestore.collection('hackathons').doc(id).delete();
  }
}