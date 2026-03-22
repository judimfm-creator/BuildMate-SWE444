import 'package:cloud_firestore/cloud_firestore.dart';

class Hackathon {
  final String? id;
  final String organizationId;
  final String name;
  final String description;
  final String domain;
  final int teamSize;
  final String city;
  final String location;
  final String mode;
  final List<String> rolesNeeded;
  final String educationCriteria;

  final DateTime applicationOpenDate;
  final DateTime applicationDeadline;
  final DateTime startDate;
  final DateTime endDate;
  
  // ✅ الحقل اللي بنخزن فيه اسم المنشأة للعرض
  String? organizationName;
  String? organizationPhotoUrl;

  Hackathon({
    this.id,
    required this.organizationId,
    required this.name,
    required this.description,
    required this.domain,
    required this.teamSize,
    required this.city,
    required this.location,
    required this.mode,
    required this.rolesNeeded,
    required this.educationCriteria,
    required this.applicationOpenDate,
    required this.applicationDeadline,
    required this.startDate,
    required this.endDate,
    this.organizationName,
    this.organizationPhotoUrl,
  });

  // ميثود مساعدة لتحويل التاريخ بأمان من أي نوع (String أو Timestamp)
  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.parse(date);
    }
    return DateTime.now(); // قيمة افتراضية في حال الخطأ
  }

  factory Hackathon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Hackathon(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      domain: data['domain'] ?? '',
      teamSize: (data['teamSize'] is int) ? data['teamSize'] : int.tryParse(data['teamSize'].toString()) ?? 0,
      city: data['city'] ?? '',
      location: data['location'] ?? '',
      mode: data['mode'] ?? '',
      rolesNeeded: List<String>.from(data['rolesNeeded'] ?? []),
      educationCriteria: data['educationCriteria'] ?? '',

      // ✅ استخدام الميثود المساعدة لضمان عدم حدوث كراش في التواريخ
      applicationOpenDate: _parseDate(data['applicationOpenDate'] ?? data['startDate']),
      applicationDeadline: _parseDate(data['applicationDeadline'] ?? data['startDate']),
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'name': name,
      'description': description,
      'domain': domain,
      'teamSize': teamSize,
      'city': city,
      'location': location,
      'mode': mode,
      'rolesNeeded': rolesNeeded,
      'educationCriteria': educationCriteria,
      'applicationOpenDate': applicationOpenDate.toIso8601String(),
      'applicationDeadline': applicationDeadline.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}