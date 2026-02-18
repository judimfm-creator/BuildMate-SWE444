import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodel/register_view_model.dart';
import '../model/org_model.dart';

class RegisterOrgView extends StatefulWidget {
  const RegisterOrgView({super.key});

  @override
  State<RegisterOrgView> createState() => _RegisterOrgViewState();
}

class _RegisterOrgViewState extends State<RegisterOrgView> {
  final _formKey = GlobalKey<FormState>();
  
  // وحدات التحكم بالنصوص لجميع الحقول
  final _orgNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // متغيرات الحالة لإظهار/إخفاء الباسورد
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final Color primaryColor = const Color(0xFF6D56B3);

  @override
  void dispose() {
    _orgNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showImagePicker(BuildContext context, RegisterViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: primaryColor),
              title: const Text('Photo Library'),
              onTap: () { vm.pickImage(ImageSource.gallery); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: primaryColor),
              title: const Text('Camera'),
              onTap: () { vm.pickImage(ImageSource.camera); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<RegisterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Register Organization"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // قسم اختيار اللوجو
              GestureDetector(
                onTap: () => _showImagePicker(context, authVM),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      backgroundImage: authVM.pickedImage != null ? FileImage(authVM.pickedImage!) : null,
                      child: authVM.pickedImage == null ? Icon(Icons.business, size: 50, color: primaryColor) : null,
                    ),
                    CircleAvatar(radius: 18, backgroundColor: primaryColor, child: const Icon(Icons.camera_alt, size: 15, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildField(_usernameController, "Username", Icons.person_outline, (v) => v!.trim().length < 3 ? "At least 3 characters" : null),
              _buildField(_orgNameController, "Organization Name", Icons.corporate_fare, (v) => v!.trim().isEmpty ? "Required" : null),
              
              // حقل الإيميل مع الـ Trim والـ Regex المرن
              _buildEmailField(),

              _buildField(_phoneController, "Phone (05xxxxxxxx)", Icons.phone_android, (v) {
                final regex = RegExp(r'^05\d{8}$');
                return !regex.hasMatch(v!.trim()) ? "Must be 10 digits starting with 05" : null;
              }, type: TextInputType.phone),

              _buildField(_locationController, "Location", Icons.location_on_outlined, (v) => v!.trim().isEmpty ? "Location is required" : null),
              
              _buildField(_bioController, "Biography", Icons.info_outline, (v) => v!.trim().isEmpty ? "Bio is required" : null),

              // كلمة المرور مع ميزة العين
              _buildPasswordField(
                controller: _passwordController,
                label: "Password",
                isVisible: _isPasswordVisible,
                onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Password is required";
                  if (v.length < 8) return "Min 8 characters";
                  if (!v.contains(RegExp(r'[A-Z]'))) return "Add one uppercase letter";
                  if (!v.contains(RegExp(r'[0-9]'))) return "Add one number";
                  if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return "Add one special character";
                  return null;
                },
              ),

              _buildPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                isVisible: _isConfirmPasswordVisible,
                onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                validator: (v) => v != _passwordController.text ? "Passwords do not match" : null,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: authVM.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: authVM.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Register", style: TextStyle(color: Colors.white, fontSize: 18)),
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
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: "Email",
          prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Email is required";
          final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
          if (!emailRegex.hasMatch(value.trim())) return "Enter a valid email address";
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // التأكد من أن المودل يحتوي على جميع هذه الحقول لتفادي الإيرور
      final org = OrgModel(
        orgName: _orgNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        biography: _bioController.text.trim(),
        profilePhotoPath: context.read<RegisterViewModel>().pickedImage?.path,
      );
      context.read<RegisterViewModel>().registerOrg(org, _passwordController.text, context);
    }
  }
}