import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // (ملاحظتي) هنا أحفظ الإيميل اللي المستخدم يكتبه
  final TextEditingController _emailController = TextEditingController();

  // (ملاحظتي) عشان أعطل الزر وقت الإرسال وما يصير ضغطات كثيرة
  bool _loading = false;

  // (ملاحظتي) لون المشروع (بنفس اللي عندك)
  final Color purple = const Color(0xFF6D56B3);

  @override
  void dispose() {
    // (ملاحظتي) لازم أفضي الذاكرة من الكونترولر
    _emailController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    // (ملاحظتي) أطلع رسالة بسيطة للمستخدم
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  bool _isValidEmail(String email) {
    // (ملاحظتي) تحقق بسيط وسريع للإيميل
    return email.contains('@') && email.contains('.');
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    // (ملاحظتي) لا أرسل إذا الإيميل فاضي
    if (email.isEmpty) {
      _toast("Email is required");
      return;
    }

    // (ملاحظتي) لا أرسل إذا الإيميل شكله غلط
    if (!_isValidEmail(email)) {
      _toast("Enter a valid email");
      return;
    }

    setState(() => _loading = true);

    try {
     
      // Firebase يرسل رابط reset الرسمي على الإيميل
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // (ملاحظتي) أذكرها تشيك spam بعد
      _toast("Reset link sent ✅ Check your inbox + Spam");

      // (ملاحظتي) بعد ما أرسله أرجع لصفحة اللوقن
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // (ملاحظتي) رسائل واضحة وبسيطة بدل ما أعرض كودات كثيرة
      String msg = "Failed to send reset email";

      if (e.code == 'invalid-email') msg = "Invalid email";
      if (e.code == 'user-not-found') msg = "No user found for this email";

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

              
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 160,
                  width: 160,
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
                keyboardType: TextInputType.emailAddress,
                enabled: !_loading,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined, color: purple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                "After you tap the email link, you will reset the password on the Firebase page.",
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