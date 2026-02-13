import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // Basic password policy for the project
  String? _validatePassword(String pass) {
    if (pass.length < 8) return "Password must be at least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(pass)) return "Add 1 uppercase letter";
    if (!RegExp(r'[a-z]').hasMatch(pass)) return "Add 1 lowercase letter";
    if (!RegExp(r'[0-9]').hasMatch(pass)) return "Add 1 number";
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/\[\]=+~`]').hasMatch(pass)) {
      return "Add 1 special character";
    }
    return null;
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _toast("Please fill all fields");
      return;
    }

    final passError = _validatePassword(pass);
    if (passError != null) {
      _toast(passError);
      return;
    }

    if (pass != confirm) {
      _toast("Passwords do not match");
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Registration failed";

      if (e.code == 'email-already-in-use') msg = "Email already in use";
      if (e.code == 'invalid-email') msg = "Invalid email";
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
    const bgPurple = Color(0xFF6D56B3);
    const fieldFill = Color(0xFFB8A8E6);
    const orange = Color(0xFFFF9F2E);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: bgPurple,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              children: [
                const SizedBox(height: 40),

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 30),

                _RoundedField(
                  hint: 'Email',
                  fill: fieldFill,
                  icon: Icons.person,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_loading,
                ),

                const SizedBox(height: 15),

                _RoundedField(
                  hint: 'Password',
                  fill: fieldFill,
                  icon: Icons.lock,
                  controller: _passwordController,
                  obscureText: _obscurePass,
                  enabled: !_loading,
                  suffix: IconButton(
                    onPressed: _loading ? null : () => setState(() => _obscurePass = !_obscurePass),
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                _RoundedField(
                  hint: 'Confirm Password',
                  fill: fieldFill,
                  icon: Icons.lock_outline,
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  enabled: !_loading,
                  suffix: IconButton(
                    onPressed: _loading ? null : () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      disabledBackgroundColor: orange.withOpacity(0.6),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Register",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: _loading
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final String hint;
  final Color fill;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final bool enabled;

  const _RoundedField({
    required this.hint,
    required this.fill,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        fillColor: fill.withOpacity(0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
