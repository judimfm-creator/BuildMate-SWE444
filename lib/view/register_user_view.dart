import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/register_view_model.dart';
import '../model/user_model.dart';

class RegisterUserView extends StatefulWidget {
  const RegisterUserView({super.key});

  @override
  State<RegisterUserView> createState() => _RegisterUserViewState();
}

class _RegisterUserViewState extends State<RegisterUserView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  final Color purple = const Color(0xFF6D56B3);

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              // حقل الاسم الكامل (3 أسماء على الأقل)
              _buildField(
                _fullNameController,
                "Full Name",
                "Enter your first, middle, and last name",
                Icons.badge_outlined,
                customValidator: (v) {
                  if (v == null || v.trim().isEmpty) return "Full name is required";
                  if (v.trim().split(RegExp(r'\s+')).length < 3) return "Enter your triple name (3 names minimum)";
                  return null;
                },
              ),

              // اسم المستخدم
              _buildField(
                _usernameController,
                "Username",
                "minimum 3 characters",
                Icons.person_outline,
                customValidator: (v) => (v != null && v.trim().length < 3) ? "At least 3 characters" : null,
              ),

              // البريد الإلكتروني مع فحص الصيغة
              _buildField(
                _emailController,
                "Email Address",
                "name@example.com",
                Icons.email_outlined,
                type: TextInputType.emailAddress,
                customValidator: (v) {
                  if (v == null || v.trim().isEmpty) return "Email is required";
                  final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|net|org|sa)$");
                  if (!regex.hasMatch(v.trim())) return "Invalid email format (e.g. .com, .sa)";
                  return null;
                },
              ),

              // رقم الجوال (يبدأ بـ 05)
              _buildField(
                _phoneController,
                "Phone Number",
                "10 digits starting with 05",
                Icons.phone_android,
                type: TextInputType.phone,
                customValidator: (v) {
                  final regex = RegExp(r'^05\d{8}$');
                  if (v == null || !regex.hasMatch(v.trim())) return "Must be 10 digits starting with 05";
                  return null;
                },
              ),

              // كلمة المرور مع فحص القوة
              _buildPassField(
                  _passwordController,
                  "Password",
                  "Min 8 chars, include capital, number, symbol",
                  _isPasswordVisible,
                      () => setState(() => _isPasswordVisible = !_isPasswordVisible)
              ),

              // تأكيد كلمة المرور
              _buildPassField(
                  _confirmPasswordController,
                  "Confirm Password",
                  "match the same password above",
                  _isConfirmVisible,
                      () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                  isConfirm: true
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: vm.isLoading ? null : _submit,
                  child: vm.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String helper, IconData icon, {TextInputType type = TextInputType.text, String? Function(String?)? customValidator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperStyle: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: Icon(icon, color: purple),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: customValidator,
      ),
    );
  }

  Widget _buildPassField(TextEditingController ctrl, String label, String helper, bool visible, VoidCallback toggle, {bool isConfirm = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperStyle: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: Icon(Icons.lock_outline, color: purple),
          suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: toggle),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "Required";
          if (isConfirm && v != _passwordController.text) return "Passwords do not match";
          if (!isConfirm) {
            if (v.length < 8) return "Min 8 characters";
            if (!v.contains(RegExp(r'[A-Z]'))) return "Add a capital letter";
            if (!v.contains(RegExp(r'[0-9]'))) return "Add a number";
            if (!v.contains(RegExp(r'[!@#$%^&*(),._?":{}|<>]'))) return "Add a symbol like _ or @";
          }
          return null;
        },
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<RegisterViewModel>().registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim(),
        context: context,
      );
    }
  }
}