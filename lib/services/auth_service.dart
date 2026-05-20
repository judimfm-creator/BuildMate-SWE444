import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';
import '../model/org_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<void> signUpUser(UserModel user, String password) async {

    UserCredential res = await _auth.createUserWithEmailAndPassword(
      email: user.email.trim(),
      password: password.trim(),
    );
    
    final Map<String, dynamic> userData = {
      'uid': res.user!.uid,
      'fullName': user.fullName,
      'username': user.username,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'role': 'user',
      'bio': '',
      'skills': [],
      'profilePhotoPath': user.profilePhotoPath ?? '',
      'linkedin': '',
      'github': '',
      'profileSetupComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(res.user!.uid).set(userData);
  }


  Future<void> signUpOrg(OrgModel org, String password) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(
      email: org.email.trim(),
      password: password.trim(),
    );
    
    await _db.collection('organizations').doc(res.user!.uid).set(org.toMap());
  }


  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }
}