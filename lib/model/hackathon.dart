class Hackathon {
  final String name;
  final String description;
  final String domain;
  final int teamSize;
  final String city;
  final String location;
  final String mode;
  final List<String> rolesNeeded;
  final String educationCriteria;
  final DateTime startDate;
  final DateTime endDate;

  Hackathon({
    required this.name,
    required this.description,
    required this.domain,
    required this.teamSize,
    required this.city,
    required this.location,
    required this.mode,
    required this.rolesNeeded,
    required this.educationCriteria,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'domain': domain,
      'teamSize': teamSize,
      'city': city,
      'location': location,
      'mode': mode,
      'rolesNeeded': rolesNeeded,
      'educationCriteria': educationCriteria,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}