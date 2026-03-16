class TeamModel {
  final String id;
  final String hackathonId;
  final String teamName;
  final String? leaderId;

  final List<String> memberIds;
  final String? genderPreference;
  final List<String> rolesNeeded;

  // New: pending join requests
  final List<String> pendingRequests;

  TeamModel({
    required this.id,
    required this.hackathonId,
    required this.teamName,
    this.leaderId,
    this.memberIds = const [],
    this.genderPreference,
    this.rolesNeeded = const [],
    this.pendingRequests = const [],
  });

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
      pendingRequests: (map['pendingRequests'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
    );
  }
}