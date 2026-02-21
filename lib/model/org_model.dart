class OrgModel {
  final String orgName;
  final String email;
  final String phoneNumber;
  final String? profilePhotoPath;
  final String? biography;
  final String? location;
  final String? username;

  OrgModel({
    required this.orgName,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoPath,
    this.biography,
    this.location,
    this.username,
  });

  factory OrgModel.fromMap(Map<String, dynamic> map) {
    return OrgModel(
      orgName: map['orgName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePhotoPath: map['profilePhotoPath'],
      biography: map['biography'],
      location: map['location'],
      username: map['username'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgName': orgName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePhotoPath': profilePhotoPath,
      'biography': biography,
      'location': location,
      'username': username,
    };
  }
}