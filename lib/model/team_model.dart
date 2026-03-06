class TeamModel {
  final String id;
  final String hackathonId;
  final String teamName;
  final String? leaderId;
  final int membersCount;

  // Additional fields for UI / requirements
  final String? genderPreference; // e.g. Any / Female / Male
  final List<String> rolesNeeded; // e.g. ["Flutter Developer", "Designer"]

  TeamModel({
    required this.id,
    required this.hackathonId,
    required this.teamName,
    this.leaderId,
    required this.membersCount,
    this.genderPreference,
    this.rolesNeeded = const [],
  });

  factory TeamModel.fromMap(String id, Map<String, dynamic> map) {
    return TeamModel(
      id: id,
      hackathonId: (map['hackathonId'] ?? '') as String,
      teamName: (map['teamName'] ?? 'Team') as String,
      leaderId: map['leaderId'] as String?,
      membersCount: (map['membersCount'] ?? 0) is int
          ? (map['membersCount'] ?? 0) as int
          : ((map['membersCount'] ?? 0) as num).toInt(),
      genderPreference: map['genderPreference'] as String?,
      rolesNeeded: (map['rolesNeeded'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
    );
  }
}