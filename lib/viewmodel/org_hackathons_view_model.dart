import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/hackathon.dart';

class OrgHackathonsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _orgId = FirebaseAuth.instance.currentUser?.uid;

  // ─── متغيرات البحث الجديدة ───
  String _searchQuery = "";

  // دالة لتحديث نص البحث من الواجهة
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners(); // مهم جداً لتحديث الشاشة فوراً
  }

  /// الهاكاثونز الحالية — endDate بعد اليوم
  Stream<List<Hackathon>> get ongoingStream {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return Stream.value([]); 
    }

    return _firestore
        .collection('hackathons')
        .where('organizationId', isEqualTo: currentUid) 
        .snapshots()
        .map((snap) {
          final now = DateTime.now();
          final list = snap.docs
              .map((d) => Hackathon.fromFirestore(d))
              .where((h) => h.endDate.isAfter(now))
              .toList();

          list.sort((a, b) => a.startDate.compareTo(b.startDate));
          return list;
        });
  }

  Stream<List<Hackathon>> get pastStream {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid; 
    if (currentUid == null) return Stream.value([]); 

    return _firestore
        .collection('hackathons')
        .where('organizationId', isEqualTo: currentUid)
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

  // ─── الـ Stream الأساسي للاستكشاف ───
  Stream<List<Hackathon>> get exploreHackathonsStream {
    return _firestore.collection('hackathons').snapshots().asyncMap((snap) async {
      final now = DateTime.now();
      List<Hackathon> list = [];

      for (var doc in snap.docs) {
        final hack = Hackathon.fromFirestore(doc);

        if (!hack.endDate.isBefore(now)) {
          try {
            final orgDoc = await _firestore
                .collection('organizations')
                .doc(hack.organizationId)
                .get();

            if (orgDoc.exists) {
              final data = orgDoc.data();
              hack.organizationName = data?['orgName'] ?? 'Unknown Organization';
              hack.organizationPhotoUrl = data?['profilePhoto'] ?? '';
            }
          } catch (e) {
            hack.organizationName = "Error fetching info";
          }
          list.add(hack);
        }
      }
      return list;
    });
  }

  // ─── الـ Stream الجديد الخاص بالبحث (Filtered) ───
  // هذا الـ Stream يعتمد على exploreHackathonsStream ويصفي النتائج
  Stream<List<Hackathon>> get filteredHackathonsStream {
    return exploreHackathonsStream.map((list) {
      if (_searchQuery.isEmpty) return list;

      return list.where((h) {
        final name = h.name.toLowerCase();
        final org = (h.organizationName ?? "").toLowerCase();
        final domain = h.domain.toLowerCase();
        
        // يبحث في الاسم، المنظم، أو المجال (Keywords)
        return name.contains(_searchQuery) || 
               org.contains(_searchQuery) || 
               domain.contains(_searchQuery);
      }).toList();
    });
  }
}