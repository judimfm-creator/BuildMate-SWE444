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

  Future<void> registerOrg(OrgModel org, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signUpOrg(org, password.trim());
      if (context.mounted) {
<<<<<<< Updated upstream
        clearPickedImage();
        Navigator.pushReplacementNamed(context, '/orgHome'); 
=======
        Navigator.pushReplacementNamed(context, '/orgHome');
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
  Future<void> registerUser(UserModel user, String password, BuildContext context) async {
=======
  // تسجيل المتسابق - (تم التعديل لإضافة الصورة فوراً)
  Future<void> registerUser(UserModel user, String password, File? imageFile, BuildContext context) async {
>>>>>>> Stashed changes
    _setLoading(true);
    try {
      await _authService.signUpUser(user, password.trim());

      // التعديل الجديد: حفظ مسار الصورة الشخصية في المستند الخاص بالمستخدم
      if (imageFile != null) {
        final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
        if (uid.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'profilePhotoPath': imageFile.path,
          });
        }
      }

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

<<<<<<< Updated upstream
  // ✅ تحديث دالة الـ Profile لاستقبال linkedin و github بشكل منفصل
=======
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

>>>>>>> Stashed changes
  Future<void> updateProfile({
    required String bio,
    required String skills,
    required String city,
    required String gender,
    required String linkedin, // الإضافة الجديدة
    required String github,   // الإضافة الجديدة
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
<<<<<<< Updated upstream
          'linkedin': linkedin.trim(), // تخزين لينكد إن
          'github': github.trim(),     // تخزين جيت هاب
          'profileSetupComplete': true, 
=======
          'portfolio': portfolio.trim(),
          'profileSetupComplete': true,
>>>>>>> Stashed changes
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

  // ... (باقي الدوال: login, logout, skipProfileSetup تبقى كما هي)
  
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
        if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      var orgDoc = await FirebaseFirestore.instance.collection('organizations').doc(uid).get();
      if (orgDoc.exists) {
        if (context.mounted) Navigator.pushReplacementNamed(context, '/orgHome');
        return;
      }
      throw "Account not found.";
    } catch (e) {
      if (context.mounted) _showSnackBar(context, _getCleanErrorMessage(e.toString()), Colors.red);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    await _authService.signOut(); 
    if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/loginUser', (route) => false);
  }

  void skipProfileSetup(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
  }

  String _getCleanErrorMessage(String error) {
    if (error.contains('email-already-in-use')) return "Email already registered.";
    if (error.contains('invalid-credential')) return "Incorrect email or password.";
    return "Something went wrong. Please try again.";
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}