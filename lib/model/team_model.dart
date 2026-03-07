class TeamModel {
  final String id;
  final String hackathonId;
  final String teamName;
  final String? leaderId;

  // قائمة الأعضاء
  final List<String> memberIds;

  // Additional fields for UI
  final String? genderPreference;
  final List<String> rolesNeeded;

  TeamModel({
    required this.id,
    required this.hackathonId,
    required this.teamName,
    this.leaderId,
    this.memberIds = const [],
    this.genderPreference,
    this.rolesNeeded = const [],
  });

  // نحسب عدد الأعضاء تلقائياً
  int get membersCount => memberIds.length;

  factory TeamModel.fromMap(String id, Map<String, dynamic> map) {
    return TeamModel(
      id: id,
      hackathonId: (map['hackathonId'] ?? '') as String,
      teamName: (map['teamName'] ?? 'Team') as String,
      leaderId: map['leaderId'] as String?,

      memberIds: (map['memberIds'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],

      genderPreference: map['genderPreference'] as String?,
      rolesNeeded: (map['rolesNeeded'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
    );
  }
}