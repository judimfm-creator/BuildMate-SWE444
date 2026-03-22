import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/hackathon.dart';

class OrgHackathonsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _orgId = FirebaseAuth.instance.currentUser?.uid;

  /// الهاكاثونز الحالية — endDate بعد اليوم
  Stream<List<Hackathon>> get ongoingStream {
    // 1. التعديل الأهم: جلب الـ ID الحالي داخل الـ Stream نفسه لضمان تحديثه
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    // 2. إذا لم يجد ID، نعيد قائمة فارغة واضحة بدل Stream.empty المحيّر
    if (currentUid == null) {
      return Stream.value([]); 
    }

    return _firestore
        .collection('hackathons')
        // 3. التأكد من مطابقة اسم الحقل 'organizationId' كما هو في قاعدة البيانات
        .where('organizationId', isEqualTo: currentUid) 
        .snapshots()
        .map((snap) {
          final now = DateTime.now();
          
          // تحويل البيانات من Firestore إلى قائمة Hackathon
          final list = snap.docs
              .map((d) => Hackathon.fromFirestore(d))
              .where((h) => h.endDate.isAfter(now))
              .toList();

          // ترتيب الهكاثونات حسب تاريخ البداية
          list.sort((a, b) => a.startDate.compareTo(b.startDate));
          
          return list;
        });
  }

 Stream<List<Hackathon>> get pastStream {
  final String? currentUid = FirebaseAuth.instance.currentUser?.uid; // التعديل هنا أيضاً
  if (currentUid == null) return Stream.value([]); 

  return _firestore
      .collection('hackathons')
      .where('organizationId', isEqualTo: currentUid)
      .snapshots()
      .map((snap) {
        final now = DateTime.now();
        return snap.docs
            .map((d) => Hackathon.fromFirestore(d))
            .where((h) => !h.endDate.isAfter(now)) // الهكاثونات المنتهية
            .toList()
          ..sort((a, b) => b.endDate.compareTo(a.endDate));
      });
}

  /// حذف هاكاثون
  Future<void> deleteHackathon(String id) async {
    await _firestore.collection('hackathons').doc(id).delete();
  }
Stream<List<Hackathon>> get exploreHackathonsStream {
  return _firestore.collection('hackathons').snapshots().asyncMap((snap) async {
    final now = DateTime.now();
    List<Hackathon> list = [];

    for (var doc in snap.docs) {
      final hack = Hackathon.fromFirestore(doc);

      // Change: Hackathon stays until the END DATE passes
      if (!hack.endDate.isBefore(now)) {
        try {
          final orgDoc = await _firestore
              .collection('organizations')
              .doc(hack.organizationId)
              .get();

         // Inside your ViewModel loop:
if (orgDoc.exists) {
  final data = orgDoc.data();
  hack.organizationName = data?['orgName'] ?? 'Unknown Organization';
  
  // MATCH THE SCREENSHOT: 'profilePhoto'
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

}