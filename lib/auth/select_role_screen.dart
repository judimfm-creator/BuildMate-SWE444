import 'dart:math' as math;
import 'package:flutter/material.dart';

// استخدام الـ Package import هو الحل الأمثل لتفادي مشاكل المجلدات
// استبدلي 'buildmate' باسم مشروعك كما هو موجود في ملف pubspec.yaml
import 'package:buildmate/auth/login_screen.dart';
import 'package:buildmate/auth/org_login_screen.dart';
import 'package:buildmate/view/register_user_view.dart';
import 'package:buildmate/view/register_org_view.dart';

class SelectRoleScreen extends StatelessWidget {
  const SelectRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgTeal = Color(0xFFA4C4C5);
    const purple = Color(0xFF6D56B3);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(37),
            child: Container(
              width: 430,
              height: 932,
              color: bgTeal,
              child: Stack(
                children: [
                  // دائرة اليوزر (المتسابق) - تفتح صفحة تسجيل المتسابق
                  Positioned(
                    top: -80,
                    left: -80,
                    child: _RoleCircle(
                      size: 340,
                      color: Colors.white,
                      text: 'User',
                      textColor: purple,
                      textOffset: const Offset(40, 40),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterUserView()),
                        );
                      },
                    ),
                  ),

                  // دائرة المنظمة - تفتح صفحة تسجيل المنظمة
                  Positioned(
                    bottom: -80,
                    right: -80,
                    child: _RoleCircle(
                      size: 340,
                      color: purple,
                      text: 'Organization',
                      textColor: Colors.white,
                      textOffset: const Offset(-40, -40),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterOrgView()),
                        );
                      },
                    ),
                  ),

                  // اللوجو بالنص
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCircle extends StatelessWidget {
  final double size;
  final Color color;
  final String text;
  final Color textColor;
  final Offset textOffset;
  final VoidCallback onTap;

  const _RoleCircle({
    required this.size,
    required this.color,
    required this.text,
    required this.textColor,
    required this.textOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Transform.translate(
            offset: textOffset,
            child: Center(
              child: Transform.rotate(
                angle: -35 * math.pi / 180,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}