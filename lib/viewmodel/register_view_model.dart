import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
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

  Future<void> registerOrg(
    OrgModel org,
    String password,
    BuildContext context,
  ) async {
    _setLoading(true);
    try {
      final bool exists = await _isPhoneNumberAlreadyExists(org.phoneNumber);

      if (exists) {
        if (context.mounted) {
          _showSnackBar(
            context,
            "This phone number is already registered",
            Colors.red,
          );
        }
        _setLoading(false);
        return;
      }

      await _authService.signUpOrg(org, password.trim());

      if (context.mounted) {
        clearPickedImage();
        Navigator.pushReplacementNamed(context, '/orgHome');
        _showSnackBar(
          context,
          "Welcome! Organization Registered ✅",
          Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _getCleanErrorMessage(e), Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerUser(
    UserModel user,
    String password,
    BuildContext context,
  ) async {
    _setLoading(true);
    try {
      final bool phoneExists = await _isPhoneNumberAlreadyExists(
        user.phoneNumber,
      );
      if (phoneExists) {
        _showSnackBar(
          context,
          "This phone number is already registered",
          Colors.red,
        );
        _setLoading(false);
        return;
      }

      final bool usernameExists = await isUsernameAlreadyExists(user.username);
      if (usernameExists) {
        _showSnackBar(
          context,
          "Username is already taken, try another one",
          Colors.red,
        );
        _setLoading(false);
        return;
      }

      final UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email.trim(),
        password: password.trim(),
      );

      final String photoPath = _pickedImage?.path ?? "";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'email': user.email.trim(),
        'fullName': user.fullName.trim(),
        'username': user.username.trim(),
        'phoneNumber': user.phoneNumber.trim(),
        'role': 'user',
        'bio': '',
        'skills': [],
        'profilePhotoPath': photoPath,
        'linkedin': '',
        'github': '',
        'profileSetupComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/completeProfile');
        _showSnackBar(
          context,
          "Account Created! Let's complete your profile 🚀",
          Colors.green,
        );
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
    String? name,
    String? username,
    String? phone,
    required String bio,
    required dynamic skills,
    required String city,
    required String gender,
    required String linkedin,
    required String github,
    required BuildContext context,
    bool isDemoMode = false,
    bool deletePhoto = false,
  }) async {
    _setLoading(true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showSnackBar(context, "User not logged in ❌", Colors.red);
        _setLoading(false);
        return;
      }

      final Map<String, dynamic> dataToUpdate = {
        'bio': bio.trim(),
        'skills': skills,
        'city': city.trim(),
        'gender': gender,
        'linkedin': linkedin.trim(),
        'github': github.trim(),
        'profileSetupComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null && name.isNotEmpty) {
        dataToUpdate['fullName'] = name.trim();
      }

      if (username != null && username.isNotEmpty) {
        dataToUpdate['username'] = username.trim();
      }

      if (phone != null && phone.isNotEmpty) {
        dataToUpdate['phoneNumber'] = phone.trim();
      }

      if (deletePhoto) {
        dataToUpdate['profilePhotoPath'] = FieldValue.delete();
      } else if (_pickedImage != null) {
        dataToUpdate['profilePhotoPath'] = _pickedImage!.path;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            dataToUpdate,
            SetOptions(merge: true),
          );

      if (context.mounted) {
        clearPickedImage();
        _showSnackBar(context, "Profile updated successfully ✅", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Update failed: ${e.toString()}", Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    final String cleanEmail = email.trim();
    final String cleanPassword = password;

    if (cleanEmail.isEmpty || cleanPassword.trim().isEmpty) {
      _showSnackBar(
        context,
        "Please enter your email and password",
        Colors.orange,
      );
      return;
    }

    _setLoading(true);
    try {
      final userCredential = await _authService.signIn(
        cleanEmail,
        cleanPassword,
      );
      final String? uid = userCredential.user?.uid;

      if (uid == null) {
        throw "User session not found.";
      }

      await NotificationService.instance.init();
      OneSignal.login(uid);

      final firestore = FirebaseFirestore.instance;

      final orgDoc = await firestore.collection('organizations').doc(uid).get();
      if (orgDoc.exists) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/orgHome');
        }
        return;
      }

      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
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
    OneSignal.logout();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/loginUser',
        (route) => false,
      );
    }
  }

  String _getCleanErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return "Email already registered.";
        case 'invalid-credential':
          return "Incorrect email or password.";
        default:
          return "Error: ${error.code}";
      }
    }
    return "Something went wrong. Please try again.";
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<bool> _isPhoneNumberAlreadyExists(String phoneNumber) async {
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber.trim())
        .get();

    if (userQuery.docs.isNotEmpty) return true;

    final orgQuery = await FirebaseFirestore.instance
        .collection('organizations')
        .where('phoneNumber', isEqualTo: phoneNumber.trim())
        .get();

    return orgQuery.docs.isNotEmpty;
  }

  Future<bool> isUsernameAlreadyExists(String username) async {
    final String searchName = username.trim().toLowerCase();

    final userQuery =
        await FirebaseFirestore.instance.collection('users').get();

    for (final doc in userQuery.docs) {
      final String dbUsername =
          (doc.data()['username'] ?? '').toString().toLowerCase();

      if (dbUsername == searchName) {
        return true;
      }
    }

    final orgQuery =
        await FirebaseFirestore.instance.collection('organizations').get();

    for (final doc in orgQuery.docs) {
      final String dbUsername =
          (doc.data()['username'] ?? '').toString().toLowerCase();

      if (dbUsername == searchName) {
        return true;
      }
    }

    return false;
  }
}