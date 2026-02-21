import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../model/org_model.dart';
import '../model/user_model.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  File? _pickedImage;
  File? get pickedImage => _pickedImage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearPickedImage() {
    _pickedImage = null;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  // تسجيل المنظمات
  Future<void> registerOrg(OrgModel org, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signUpOrg(org, password.trim());
      if (context.mounted) {
        clearPickedImage();
        Navigator.pushReplacementNamed(context, '/orgHome');
        _showSnackBar(context, "Welcome! Organization Registered ✅", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _getCleanErrorMessage(e), Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل المستخدم (المتسابق)
  Future<void> registerUser(UserModel user, String password, BuildContext context) async {
    _setLoading(true);
    try {
      // إنشاء الحساب في Auth
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: user.email.trim(),
          password: password.trim()
      );

      // تخزين مسار الصورة لو تم اختيارها
      String photoPath = _pickedImage?.path ?? "";

      // حفظ البيانات في Firestore باستخدام المسميات الموحدة
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': user.email.trim(),
        'fullName': user.fullName.trim(),
        'username': user.username.trim(),
        'phoneNumber': user.phoneNumber.trim(),
        'role': 'user',
        'bio': '',
        'skills': '',
        'profilePhotoPath': photoPath,
        'linkedinUrl': '', // مسمى موحد
        'githubUrl': '',   // مسمى موحد
        'profileSetupComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        clearPickedImage();
        Navigator.pushReplacementNamed(context, '/completeProfile');
        _showSnackBar(context, "Account Created! Let's complete your profile 🚀", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _getCleanErrorMessage(e), Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تحديث البروفايل (دعم LinkedIn و GitHub ليتوافق مع التصميم)
  Future<void> updateProfile({
    required String bio,
    required String skills,
    required String city,
    required String gender,
    required String linkedin,
    required String github,
    required BuildContext context,
  }) async {
    _setLoading(true);
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'bio': bio.trim(),
          'skills': skills.trim(),
          'city': city.trim(),
          'gender': gender,
          'linkedinUrl': linkedin.trim(),
          'githubUrl': github.trim(),
          'profileSetupComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
          _showSnackBar(context, "Profile updated successfully! 🚀", Colors.green);
        }
      } else {
        throw "User session not found.";
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Update failed: ${e.toString()}", Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الدخول مع فحص الوجهة (Organization vs User)
  Future<void> login(String email, String password, BuildContext context) async {
    final cleanEmail = email.trim();
    final cleanPassword = password;

    if (cleanEmail.isEmpty || cleanPassword.trim().isEmpty) {
      _showSnackBar(context, "Please enter your email and password", Colors.orange);
      return;
    }

    _setLoading(true);
    try {
      final userCredential = await _authService.signIn(cleanEmail, cleanPassword);
      final uid = userCredential.user?.uid;

      if (uid == null) throw "User session not found.";

      final firestore = FirebaseFirestore.instance;

      // 1) فحص هل هو منظم (Organization)
      final orgDoc = await firestore.collection('organizations').doc(uid).get();
      if (orgDoc.exists) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/orgHome');
          _showSnackBar(context, "Welcome Back, Institution! ✅", Colors.green);
        }
        return;
      }

      // 2) فحص هل هو متسابق (User) وهل أكمل بياناته
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final bool setupDone = (data?['profileSetupComplete'] == true);

        if (context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            setupDone ? '/home' : '/completeProfile',
          );
          _showSnackBar(context, "Welcome Back! ✅", Colors.green);
        }
        return;
      }

      // 3) لو نجح الـ Auth وما فيه Document (حالة نادرة) ننشئ واحد جديد
      await firestore.collection('users').doc(uid).set({
        'email': cleanEmail,
        'profileSetupComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/completeProfile');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _getCleanErrorMessage(e), Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الخروج
  Future<void> logout(BuildContext context) async {
    await _authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/loginUser', (route) => false);
      _showSnackBar(context, "Logged out successfully! 👋", Colors.blue);
    }
  }

  String _getCleanErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use': return "Email already registered.";
        case 'invalid-credential': return "Incorrect email or password.";
        case 'too-many-requests': return "Too many attempts. Try later.";
        case 'network-request-failed': return "Check your internet connection.";
        default: return "Error: ${error.code}";
      }
    }
    return "Something went wrong. Please try again.";
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}