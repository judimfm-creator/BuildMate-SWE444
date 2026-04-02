import 'package:cloud_firestore/cloud_firestore.dart';

class TeamPostModel {
  final String? id;
  final String hackathonId;
  final String createdBy;
  final String teamName;
  final String genderPreference;
  final String myRole;
  final String idea; // ✅ أضفنا فكرة المشروع
  final List<String> members; // ✅ أضفنا قائمة الأعضاء
  final DateTime createdAt;

  TeamPostModel({
    this.id,
    required this.hackathonId,
    required this.createdBy,
    required this.teamName,
    required this.genderPreference,
    required this.myRole,
    required this.idea, // ✅
    required this.members, // ✅
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'hackathonId': hackathonId,
      'createdBy': createdBy,
      'teamName': teamName,
      'genderPreference': genderPreference,
      'myRole': myRole,
      'idea': idea, // ✅
      'members': members, // ✅
      'createdAt': FieldValue.serverTimestamp(), // ✅ تعديل مهم
    };
  }

  factory TeamPostModel.fromMap(String id, Map<String, dynamic> map) {
    return TeamPostModel(
      id: id,
      hackathonId: map['hackathonId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      teamName: map['teamName'] ?? '',
      genderPreference: map['genderPreference'] ?? '',
      myRole: map['myRole'] ?? '',
      idea: map['idea'] ?? map['projectIdea'] ?? '',      members: List<String>.from(map['members'] ?? []), // ✅ تحويل آمن لقائمة الأعضاء
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // fallback
    );
  }
}