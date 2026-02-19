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

  // اختيار الصورة
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  // تسجيل المنظمة
  Future<void> registerOrg(OrgModel org, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signUpOrg(org, password.trim());
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/orgHome'); 
        _showSnackBar(context, "Welcome! Organization Registered ✅", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        String errorMsg = _getCleanErrorMessage(e.toString());
        _showSnackBar(context, errorMsg, Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل المتسابق
  Future<void> registerUser(UserModel user, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signUpUser(user, password.trim());
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/completeProfile');
        _showSnackBar(context, "Account Created! Let's complete your profile 🚀", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        String errorMsg = _getCleanErrorMessage(e.toString());
        _showSnackBar(context, errorMsg, Colors.red);
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

      // التأكد من اسم المجموعة 'users' (تأكدي أنه بالصغير في فايربيز)
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

      throw "Account not found in database.";
    } catch (e) {
      if (context.mounted) {
        String errorMsg = _getCleanErrorMessage(e.toString());
        _showSnackBar(context, errorMsg, Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الخروج
  Future<void> logout(BuildContext context) async {
    try {
      await _authService.signOut(); 
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/loginUser', (route) => false);
        _showSnackBar(context, "Logged out successfully! 👋", Colors.blue);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Error: ${e.toString()}", Colors.red);
      }
    }
  }

  String _getCleanErrorMessage(String error) {
    if (error.contains('invalid-credential') || error.contains('wrong-password')) {
      return "Incorrect email or password.";
    } else if (error.contains('user-not-found')) {
      return "No account found for this email.";
    } else if (error.contains('email-already-in-use')) {
      return "This email is already registered.";
    } else if (error.contains('network-request-failed')) {
      return "Check your internet connection.";
    } else if (error.contains('invalid-email')) {
      return "The email format is incorrect.";
    } else if (error.contains('weak-password')) {
      return "The password is too weak.";
    }
    return "Something went wrong. Please try again.";
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ==========================================
  // الإضافات الجديدة والمعدلة (Set مع Merge)
  // ==========================================

  Future<void> updateProfile({
    required String bio,
    required String skills,
    required String city,
    required String gender,
    required String portfolio,
    required BuildContext context,
  }) async {
    _setLoading(true);
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      
      if (uid != null) {
        // استخدام set مع SetOptions(merge: true) لضمان الكتابة حتى لو المستند غير موجود
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'bio': bio.trim(),
          'skills': skills.trim(),
          'city': city.trim(),
          'gender': gender,
          'portfolio': portfolio.trim(),
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
      debugPrint("Firestore Error: $e");
      if (context.mounted) {
        _showSnackBar(context, "Update failed: ${e.toString()}", Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  void skipProfileSetup(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
    _showSnackBar(context, "You can complete your profile later!", Colors.blue);
  }
}