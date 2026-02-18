import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ضروري لفحص نوع الحساب
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

  // تسجيل المنظمة وتوجيهها لصفحتها
  Future<void> registerOrg(OrgModel org, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signUpOrg(org, password);
      if (context.mounted) {
        // التوجه لصفحة المنشأة فور التسجيل
        Navigator.pushReplacementNamed(context, '/orgHome'); 
        _showSnackBar(context, "Organization Registered Successfully! ✅", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Error: ${e.toString()}", Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل المتسابق وتوجيهه لصفحته
  Future<void> registerUser(UserModel user, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signUpUser(user, password);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
        _showSnackBar(context, "Account Created Successfully! ✅", Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Error: ${e.toString()}", Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // --- دالة تسجيل الدخول الذكية (الربط بين اليوزر والمنشأة) ---
  Future<void> login(String email, String password, BuildContext context) async {
    _setLoading(true); 
    try {
      final userCredential = await _authService.signIn(email, password);
      final uid = userCredential.user!.uid;

      // 1. فحص هل هو "متسابق"؟
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home'); // شاشة المتسابق
          _showSnackBar(context, "Welcome Back! ✅", Colors.green);
        }
        return;
      }

      // 2. فحص هل هي "منظمة/منشأة"؟
      var orgDoc = await FirebaseFirestore.instance.collection('organizations').doc(uid).get();
      if (orgDoc.exists) {
        if (context.mounted) {
          // التوجه لمسار المنشأة الذي يؤدي لـ InstitutionHomeScreen
          Navigator.pushReplacementNamed(context, '/orgHome'); 
          _showSnackBar(context, "Welcome Back, Institution! ✅", Colors.green);
        }
        return;
      }

      throw "لم يتم العثور على بيانات الحساب في قاعدة البيانات.";
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Login Failed: ${e.toString()}", Colors.red);
      }
    } finally {
      _setLoading(false);
    }
  }

  // دالة تسجيل الخروج للعودة لشاشة اللوجن فقط
  Future<void> logout(BuildContext context) async {
    try {
      await _authService.signOut(); 
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/loginUser', 
          (route) => false,
        );
        _showSnackBar(context, "Logged out successfully! 👋", Colors.blue);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, "Logout error: ${e.toString()}", Colors.red);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}