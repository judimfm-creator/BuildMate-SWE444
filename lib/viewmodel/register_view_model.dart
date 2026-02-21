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

  Future<void> registerUser(UserModel user, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signUpUser(user, password.trim());
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
          'linkedin': linkedin.trim(),
          'github': github.trim(),
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

  // ✅✅✅ هنا الإصلاح الحقيقي
  Future<void> login(String email, String password, BuildContext context) async {
    final cleanEmail = email.trim();
    final cleanPassword = password; // لا نقصه

    if (cleanEmail.isEmpty || cleanPassword.trim().isEmpty) {
      _showSnackBar(context, "Please enter your email and password", Colors.orange);
      return;
    }

    _setLoading(true);
    try {
      final userCredential = await _authService.signIn(cleanEmail, cleanPassword);
      final uid = userCredential.user?.uid;

      if (uid == null) {
        throw "User session not found.";
      }

      final firestore = FirebaseFirestore.instance;

      // 1) شيك organizations
      final orgDoc = await firestore.collection('organizations').doc(uid).get();
      if (orgDoc.exists) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/orgHome');
        }
        return;
      }

      // 2) شيك users
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final bool setupDone = (data?['profileSetupComplete'] == true);

        if (context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            setupDone ? '/home' : '/completeProfile',
          );
        }
        return;
      }

      // 3) ✅ Auth نجح لكن ما فيه Document -> ننشئ placeholder ونوديه يكمل بروفايله
      await firestore.collection('users').doc(uid).set({
        'email': cleanEmail,
        'profileSetupComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/completeProfile');
        _showSnackBar(context, "Welcome! Please complete your profile 🚀", Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("LOGIN ERROR CODE: ${e.code}");
      debugPrint("LOGIN ERROR MESSAGE: ${e.message}");
      if (context.mounted) {
        _showSnackBar(context, _getCleanErrorMessage(e), Colors.red);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _getCleanErrorMessage(e), Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    await _authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/loginUser', (route) => false);
    }
  }

  void skipProfileSetup(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
  }

  String _getCleanErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return "Email already registered.";
        case 'invalid-email':
          return "Enter a valid email.";
        case 'user-not-found':
          return "No user found for this email.";
        case 'wrong-password':
          return "Wrong password.";
        case 'invalid-credential':
          return "Incorrect email or password.";
        case 'user-disabled':
          return "This account is disabled.";
        case 'too-many-requests':
          return "Too many attempts. Try again later.";
        case 'network-request-failed':
          return "Network error. Check your connection.";
        case 'operation-not-allowed':
          return "Email/Password sign-in is not enabled in Firebase.";
        default:
          return "Login failed: ${error.code}";
      }
    }

    final msg = error.toString();
    if (msg.contains('email-already-in-use')) return "Email already registered.";
    if (msg.contains('invalid-credential')) return "Incorrect email or password.";
    if (msg.contains('wrong-password')) return "Wrong password.";
    if (msg.contains('user-not-found')) return "No user found for this email.";
    if (msg.contains('too-many-requests')) return "Too many attempts. Try later.";
    return "Something went wrong. Please try again.";
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}