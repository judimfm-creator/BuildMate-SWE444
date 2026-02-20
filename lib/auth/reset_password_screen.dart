import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  final Color purple = const Color(0xFF6D56B3);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    // أنا أحب أتحقق بسرعة قبل ما أرسل
    if (email.isEmpty) {
      _toast("Email is required");
      return;
    }
    if (!email.contains('@')) {
      _toast("Enter a valid email");
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      _toast("Reset link sent ✅ Check your inbox");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // رسائل واضحة وبسيطة
      String msg = "Failed to send reset email";
      if (e.code == 'user-not-found') msg = "No user found for this email";
      if (e.code == 'invalid-email') msg = "Invalid email";
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),

            const Text(
              "Type your email and we will send you a reset link.",
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 18),

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
          ],
        ),
      ),
    );
  }
}
