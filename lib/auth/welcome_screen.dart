import 'dart:async';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // تعريف اللون البنفسجي الموحد للمشروع
  static const Color purple = Color(0xFF6D56B3);

  @override
  void initState() {
    super.initState();

    // عداد زمني لمدة 3 ثواني قبل الانتقال التلقائي
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // الانتقال لصفحة تسجيل الدخول واستبدال الشاشة الحالية
        Navigator.pushReplacementNamed(context, '/loginUser');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // عرض شعار التطبيق في المنتصف
        child: Image.asset(
          'assets/images/logo.png',
          height: 270,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}