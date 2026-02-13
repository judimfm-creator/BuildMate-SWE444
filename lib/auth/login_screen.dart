import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(); // (UI: username)
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _toast("Please enter username and password");
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Login failed";

      if (e.code == 'user-not-found') msg = "No user found for this account";
      if (e.code == 'wrong-password') msg = "Wrong password";
      if (e.code == 'invalid-email') msg = "Invalid username";
      if (e.code == 'user-disabled') msg = "This account is disabled";
      if (e.code == 'too-many-requests') msg = "Too many attempts, try later";

      _toast(msg);
    } catch (_) {
      _toast("Something went wrong");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Reset password by email (Firebase requirement)
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _toast("Type your email first");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast("Reset email sent ✅ Check your inbox");
    } on FirebaseAuthException catch (e) {
      String msg = "Failed to send reset email";
      if (e.code == 'invalid-email') msg = "Invalid email";
      if (e.code == 'user-not-found') msg = "No user found for this email";
      _toast(msg);
    } catch (_) {
      _toast("Something went wrong");
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        "Logo not found",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Login to your account',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),

                const SizedBox(height: 26),

                _RoundedField(
                  hint: 'username',
                  fill: fieldFill,
                  icon: Icons.person,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_loading,
                ),

                const SizedBox(height: 14),

                _RoundedField(
                  hint: 'Password',
                  fill: fieldFill,
                  icon: Icons.lock,
                  controller: _passwordController,
                  obscureText: _obscure,
                  enabled: !_loading,
                  suffix: IconButton(
                    onPressed: _loading ? null : () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _loading ? null : _resetPassword,
                    child: const Text(
                      'Forget Password?',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      disabledBackgroundColor: orange.withOpacity(0.55),
                      disabledForegroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'new user ? ',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                      child: const Text(
                        'create account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
