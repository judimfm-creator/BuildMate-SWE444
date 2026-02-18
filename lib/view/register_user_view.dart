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
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Participant Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(_fullNameController, "Full Name", Icons.badge_outlined, (v) => v!.isEmpty ? "Required" : null),
              _buildField(_usernameController, "Username", Icons.person_outline, (v) => v!.length < 3 ? "Too short" : null),
              
              // Email مع الـ Regex المرن والـ Trim
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined, color: purple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  final regex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                  if (!regex.hasMatch(v!.trim())) return "Invalid email";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildField(_phoneController, "Phone", Icons.phone_android, (v) => !RegExp(r'^05\d{8}$').hasMatch(v!) ? "Invalid Saudi phone" : null),

              // كلمة المرور بشروط القوة
              _buildPassField(_passwordController, "Password", _isPasswordVisible, () => setState(() => _isPasswordVisible = !_isPasswordVisible), 
                (v) {
                  if (v!.length < 8) return "Min 8 characters";
                  if (!v.contains(RegExp(r'[A-Z]'))) return "Add an uppercase letter";
                  if (!v.contains(RegExp(r'[0-9]'))) return "Add a number";
                  return null;
                }
              ),

              _buildPassField(_confirmPasswordController, "Confirm Password", _isConfirmVisible, () => setState(() => _isConfirmVisible = !_isConfirmVisible), 
                (v) => v != _passwordController.text ? "Not matching" : null
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: vm.isLoading ? null : _submit,
                  child: vm.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة بناء الحقول
  Widget _buildField(TextEditingController ctrl, String label, IconData icon, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: purple), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: validator,
      ),
    );
  }

  // دالة بناء حقل الباسورد
  Widget _buildPassField(TextEditingController ctrl, String label, bool visible, VoidCallback toggle, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.lock_outline, color: purple),
          suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility : Icons.visibility_off), onPressed: toggle),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final user = UserModel(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      context.read<RegisterViewModel>().registerUser(user, _passwordController.text, context);
    }
  }
}