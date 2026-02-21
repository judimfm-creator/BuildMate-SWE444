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
        _showSnackBar(context, _getCleanErrorMessage(e.toString()), Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل المستخدم (المتسابق) - دمج نسخة الحفظ الفوري للصورة
  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String phone,
    required BuildContext context,
  }) async {
    _setLoading(true);
    try {
      // 1. إنشاء الحساب في Auth وتخزين البيانات الأولية
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim()
      );

      // 2. تخزين مسار الصورة لو تم اختيارها مبكراً
      String photoPath = _pickedImage?.path ?? "";

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email.trim(),
        'fullName': fullName.trim(),
        'username': username.trim(),
        'phoneNumber': phone.trim(),
        'role': 'user',
        'bio': '',
        'skills': '',
        'profilePhotoPath': photoPath,
        'linkedinUrl': '',
        'githubUrl': '',
        'profileSetupComplete': false,
      });

      if (context.mounted) {
        clearPickedImage();
        Navigator.pushReplacementNamed(context, '/completeProfile');
        _showSnackBar(context, "Account Created! Let's complete your profile 🚀", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _getCleanErrorMessage(e.toString()), Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تحديث البروفايل (دعم LinkedIn و GitHub ليتوافق مع تصميم الإنستقرام)
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
          'linkedinUrl': linkedin.trim(), // تخزين الرابط بمسمى موحد
          'githubUrl': github.trim(),
          'profileSetupComplete': true,
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

  // تسجيل الدخول
  Future<void> login(String email, String password, BuildContext context) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _showSnackBar(context, "Please enter your email and password", Colors.orange);
      return;
    }
    _setLoading(true);
    try {
      final userCredential = await _authService.signIn(email.trim(), password.trim());
      final uid = userCredential.user!.uid;

      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
          _showSnackBar(context, "Welcome Back! ✅", Colors.green);
        }
        return;
      }
      var orgDoc = await FirebaseFirestore.instance.collection('organizations').doc(uid).get();
      if (orgDoc.exists) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/orgHome');
          _showSnackBar(context, "Welcome Back, Institution! ✅", Colors.green);
        }
        return;
      }
      throw "Account not found.";
    } catch (e) {
      if (context.mounted) _showSnackBar(context, _getCleanErrorMessage(e.toString()), Colors.red);
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

  void skipProfileSetup(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
  }

  String _getCleanErrorMessage(String error) {
    if (error.contains('email-already-in-use')) return "Email already registered.";
    if (error.contains('invalid-credential') || error.contains('wrong-password')) return "Incorrect email or password.";
    if (error.contains('network-request-failed')) return "Check your internet connection.";
    return "Something went wrong. Please try again.";
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}