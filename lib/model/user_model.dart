class UserModel {
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String? profilePhotoPath;
  final String? bio;
  final String? city;
  final String? gender;
  final String? linkedinUrl;
  final String? githubUrl;

  UserModel({
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoPath,
    this.bio,
    this.city,
    this.gender,
    this.linkedinUrl,
    this.githubUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePhotoPath: map['profilePhotoPath'],
      bio: map['bio'],
      city: map['city'],
      gender: map['gender'],
      linkedinUrl: map['linkedinUrl'],
      githubUrl: map['githubUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePhotoPath': profilePhotoPath,
      'bio': bio,
      'city': city,
      'gender': gender,
      'linkedinUrl': linkedinUrl,
      'githubUrl': githubUrl,
    };
  }
}