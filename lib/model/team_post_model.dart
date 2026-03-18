import 'package:cloud_firestore/cloud_firestore.dart';

class TeamPostModel {
  final String? id;
  final String hackathonId;
  final String createdBy;
  final String teamName;
  final String genderPreference;
  final String myRole;
  final DateTime createdAt;

  TeamPostModel({
    this.id,
    required this.hackathonId,
    required this.createdBy,
    required this.teamName,
    required this.genderPreference,
    required this.myRole,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'hackathonId': hackathonId,
      'createdBy': createdBy,
      'teamName': teamName,
      'genderPreference': genderPreference,
      'myRole': myRole,
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
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // fallback
    );
  }
}