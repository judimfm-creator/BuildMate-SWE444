import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  void initState() {
    super.initState();

    // (ملاحظتي) أعرض الشاشة 3 ثواني وبعدين أروح للوقن
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/loginUser');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color purple = Color(0xFF6D56B3);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // (ملاحظتي) اللوقو بالمنتصف تمامًا
        child: Image.asset(
          'assets/images/logo.png',
          height: 270,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}