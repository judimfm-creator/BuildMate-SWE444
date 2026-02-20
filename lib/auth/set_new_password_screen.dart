import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String oobCode; // code from reset link

  const SetNewPasswordScreen({super.key, required this.oobCode});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pass1Controller = TextEditingController();
  final _pass2Controller = TextEditingController();
  bool _loading = false;

  final Color purple = const Color(0xFF6D56B3);

  @override
  void dispose() {
    _pass1Controller.dispose();
    _pass2Controller.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool isValidPassword(String password) {
    // 8+ chars, at least 1 uppercase, 1 number, 1 symbol
    final reg = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>_\-]).{8,}$');
    return reg.hasMatch(password);
  }

  Future<void> _confirmReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: _pass1Controller.text.trim(),
      );

      if (!mounted) return;
      _toast("Password updated successfully ✅");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = "Failed to reset password";
      if (e.code == 'expired-action-code') msg = "Reset link expired";
      if (e.code == 'invalid-action-code') msg = "Invalid reset link";
      if (e.code == 'weak-password') msg = "Password is too weak";
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
        title: const Text("Set New Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              const Text(
                "Create a strong password (8+ chars, 1 uppercase, 1 number, 1 symbol).",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _pass1Controller,
                enabled: !_loading,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.lock_outline, color: purple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  final value = (v ?? "").trim();
                  if (value.isEmpty) return "New password is required";
                  if (!isValidPassword(value)) {
                    return "Min 8 chars + 1 uppercase + 1 number + 1 symbol";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _pass2Controller,
                enabled: !_loading,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock, color: purple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  final value = (v ?? "").trim();
                  if (value.isEmpty) return "Confirm your password";
                  if (value != _pass1Controller.text.trim()) return "Passwords do not match";
                  return null;
                },
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirmReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          "Update password",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}