class OrgModel {
  final String orgName;
  final String username;
  final String email;
  final String phoneNumber;
  final String location;
  final String biography;
  final String? profilePhotoPath;

  OrgModel({
    required this.orgName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.biography,
    this.profilePhotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'orgName': orgName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'biography': biography,
      'profilePhotoPath': profilePhotoPath,
      'role': 'organization', // إضافة الدور لتمييزه في الفايربيس
    };
  }
}