class UserModel {
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String? profilePhotoPath;

  UserModel({
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.profilePhotoPath,
  });

  // تحويل البيانات لخريطة لتخزينها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePhoto': profilePhotoPath,
      'role': 'participant', // لتمييزه كمتسابق عند اللوجن
    };
  }
}