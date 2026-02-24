import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // تعريف الكونترولر واللون المعتمد
  final TextEditingController _emailController = TextEditingController();
  static const Color purple = Color(0xFF6D56B3);

  // حالة التحميل
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  bool _isValidEmail(String email) {
    final cleanEmail = email.trim();
    return cleanEmail.contains('@') && cleanEmail.contains('.');
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _toast("Email is required");
      return;
    }

    if (!_isValidEmail(email)) {
      _toast("Enter a valid email");
      return;
    }

    setState(() => _loading = true);

    try {
      // إرسال رابط إعادة التعيين عبر فايربيز
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _toast("Reset link sent ✅ Check your inbox + Spam");

      // العودة لصفحة تسجيل الدخول بعد النجاح
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = "Failed to send reset email";

      // معالجة شاملة لكل أنواع الأخطاء المحتملة
      if (e.code == 'invalid-email') msg = "Invalid email format";
      if (e.code == 'user-not-found') msg = "No user found for this email";
      if (e.code == 'too-many-requests') msg = "Too many attempts, try later";
      if (e.code == 'network-request-failed') msg = "Network error, try again";

      _toast(msg);
    } catch (_) {
      _toast("Something went wrong");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: const Text("Reset Password"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),

              // اللوجو بحجم متناسق 170
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 170,
                  width: 170,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Type your email and we will send you a reset link.",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 22),

              TextField(
                controller: _emailController,
               keyboardType: TextInputType.emailAddress, // ✅ تطلع لوحة مفاتيح الإيميل (@)
  maxLines: 2,
  minLines: 1,
  maxLength: 40, //
                enabled: !_loading,
                decoration: InputDecoration(
                  labelText: "Email",
                  counterText: "", // ✅ إخفاء العداد 0/40 عشان التصميم يبقى نظيف
                  prefixIcon: const Icon(Icons.email_outlined, color: purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          "Send reset link",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Open the email link, change the password, then come back and login with the new password.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}