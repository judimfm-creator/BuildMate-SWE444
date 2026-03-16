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
  });

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

  factory Hackathon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Hackathon(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      domain: data['domain'] ?? '',
      teamSize: data['teamSize'] ?? 0,
      city: data['city'] ?? '',
      location: data['location'] ?? '',
      mode: data['mode'] ?? '',
      rolesNeeded: List<String>.from(data['rolesNeeded'] ?? []),
      educationCriteria: data['educationCriteria'] ?? '',

      applicationOpenDate: data['applicationOpenDate'] != null
          ? DateTime.parse(data['applicationOpenDate'])
          : DateTime.parse(data['startDate']),

      applicationDeadline: data['applicationDeadline'] != null
          ? DateTime.parse(data['applicationDeadline'])
          : DateTime.parse(data['startDate']),

      startDate: DateTime.parse(data['startDate']),
      endDate: DateTime.parse(data['endDate']),
    );
  }
}