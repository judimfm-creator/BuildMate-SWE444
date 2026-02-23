class UserModel {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String? profilePhotoPath;
  final String? bio;
  final String? city;
  final String? gender;
  final dynamic skills; // ✅ يدعم المصفوفة والنص
  final String? linkedin; 
  final String? github;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoPath,
    this.bio,
    this.city,
    this.gender,
    this.skills,
    this.linkedin,
    this.github,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePhotoPath: map['profilePhotoPath'],
      bio: map['bio'],
      city: map['city'],
      gender: map['gender'],
      skills: map['skills'], // ✅ يقرأ المصفوفة مباشرة
      linkedin: map['linkedin'], 
      github: map['github'],
    );
  }
}