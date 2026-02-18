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
      appBar: AppBar(title: const Text("Create Participant Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // حقل الاسم الكامل مع شرط الـ 3 أسماء
              _buildField(_fullNameController, "Full Name", Icons.badge_outlined, (v) {
                if (v == null || v.trim().isEmpty) return "Full name is required";
                List<String> parts = v.trim().split(RegExp(r'\s+'));
                if (parts.length < 3) {
                  return "Please enter at least 3 names";
                }
                return null;
              }),
              
              _buildField(_usernameController, "Username", Icons.person_outline, 
                (v) => v!.trim().length < 3 ? "At least 3 characters" : null),
              
              // حقل الإيميل مع الـ Regex القوي والـ Trim
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined, color: purple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Email is required";
                  final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                  if (!regex.hasMatch(v.trim())) return "Enter a valid email address";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // حقل الهاتف (الجوال السعودي)
              _buildField(_phoneController, "Phone (05xxxxxxxx)", Icons.phone_android, (v) {
                final regex = RegExp(r'^05\d{8}$');
                return !regex.hasMatch(v!.trim()) ? "Must be 10 digits starting with 05" : null;
              }, type: TextInputType.phone),

              // كلمة المرور بنفس شروط المنشأة
              _buildPassField(_passwordController, "Password", _isPasswordVisible, 
                () => setState(() => _isPasswordVisible = !_isPasswordVisible), 
                (v) {
                  if (v == null || v.isEmpty) return "Password is required";
                  if (v.length < 8) return "Min 8 characters";
                  if (!v.contains(RegExp(r'[A-Z]'))) return "Add one uppercase letter";
                  if (!v.contains(RegExp(r'[0-9]'))) return "Add one number";
                  if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return "Add one special character";
                  return null;
                }
              ),

              _buildPassField(_confirmPasswordController, "Confirm Password", _isConfirmVisible, 
                () => setState(() => _isConfirmVisible = !_isConfirmVisible), 
                (v) => v != _passwordController.text ? "Passwords do not match" : null
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: vm.isLoading ? null : _submit,
                  child: vm.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, String? Function(String?)? validator, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: Icon(icon, color: purple), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPassField(TextEditingController ctrl, String label, bool visible, VoidCallback toggle, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.lock_outline, color: purple),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), 
            onPressed: toggle
          ),
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