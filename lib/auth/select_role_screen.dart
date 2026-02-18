import 'dart:math' as math;
import 'package:flutter/material.dart';

// استدعاء ملفات الـ View الخاصة بكِ
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
                  // 1. سهم الرجوع - أعلى اليسار
                  Positioned(
                    top: 30,
                    left: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.3),
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/loginUser'),
                      ),
                    ),
                  ),

                  // 2. دائرة اليوزر (المتسابق) - أعلى اليمين
                  Positioned(
                    top: -80,
                    right: -80,
                    child: _RoleCircle(
                      size: 340,
                      color: Colors.white,
                      text: 'User',
                      textColor: purple,
                      textOffset: const Offset(-40, 40),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterUserView()));
                      },
                    ),
                  ),

                  // 3. دائرة المنظمة - أسفل اليسار
                  Positioned(
                    bottom: -80,
                    left: -80,
                    child: _RoleCircle(
                      size: 340,
                      color: purple,
                      text: 'Organization',
                      textColor: Colors.white,
                      textOffset: const Offset(40, -40),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterOrgView()));
                      },
                    ),
                  ),

                  // 4. النص التوضيحي الكبير في المنتصف
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "CREATE\nACCOUNT",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 35,
                              // تم تصحيح الخطأ هنا باستخدام w900 (وهي تعادل الـ Black)
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 4,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Get started by choosing your role",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Transform.translate(
            offset: textOffset,
            child: Center(
              child: Transform.rotate(
                angle: 35 * math.pi / 180,
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
