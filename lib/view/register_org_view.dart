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
  
  final _orgNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  final Color purple = const Color(0xFF6D56B3);

  @override
  void initState() {
    super.initState();
    // ✅ تصفير الصورة فور دخول الصفحة لضمان عدم ظهور صورة قديمة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegisterViewModel>().clearPickedImage();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Register Organization", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              // ✅ اختيار اللوجو مع إضافة زر الحذف (X)
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: () => _showPicker(context, vm),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: purple.withOpacity(0.1),
                        backgroundImage: vm.pickedImage != null ? FileImage(vm.pickedImage!) : null,
                        child: vm.pickedImage == null ? Icon(Icons.add_a_photo_outlined, color: purple, size: 30) : null,
                      ),
                    ),
                    // زر الحذف (X) الأحمر يظهر فقط عند وجود صورة
                    if (vm.pickedImage != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => vm.clearPickedImage(),
                          child: const CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // اسم المنشأة
              _buildField(
                _orgNameController, 
                "Organization Name", 
                "Enter the name of the organization", 
                Icons.corporate_fare,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Organization name is required" : null,
              ),
              
              // اسم المستخدم
              _buildField(
                _usernameController, 
                "Username", 
                "minimum 3 characters", 
                Icons.person_outline,
                validator: (v) => (v != null && v.trim().length < 3) ? "Username must be at least 3 characters" : null,
              ),

              // البريد الإلكتروني (صارم)
              _buildField(
                _emailController, 
                "Email Address", 
                "name@org.com ", 
                Icons.email_outlined, 
                type: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Email is required";
                  final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|net|org|sa)$");
                  if (!regex.hasMatch(v.trim())) return "Invalid email format (use .com, .sa, etc.)";
                  return null;
                },
              ),

              // رقم الجوال (صارم)
              _buildField(
                _phoneController, 
                "Phone Number", 
                "10 digits starting with '05'", 
                Icons.phone_android, 
                type: TextInputType.phone,
                validator: (v) {
                  final regex = RegExp(r'^05\d{8}$');
                  if (v == null || !regex.hasMatch(v.trim())) return "Must start with 05 and be 10 digits";
                  return null;
                },
              ),

              // الموقع
              _buildField(
                _locationController, 
                "Location", 
                "e.g., Riyadh, KSU Campus", 
                Icons.location_on_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Location is required" : null,
              ),
              
              // النبذة التعريفية
              _buildField(
                _bioController, 
                "Biography", 
                "Brief description of the organization", 
                Icons.info_outline,
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Biography is required" : null,
              ),

              // كلمة المرور (صارمة)
              _buildPassField(
                _passwordController, 
                "Password", 
                "minimum 8 chars, include capital letter, number, symbol", 
                _isPasswordVisible, 
                () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),

              // تأكيد كلمة المرور
              _buildPassField(
                _confirmPasswordController, 
                "Confirm Password", 
                " match the same password above", 
                _isConfirmVisible, 
                () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                isConfirm: true,
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
                    : const Text("Register", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String helper, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
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
        validator: validator,
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
            if (!v.contains(RegExp(r'[!@#$%^&*(),._?":{}|<>]'))) return "Add a symbol (e.g. _ )";
          }
          return null;
        },
      ),
    );
  }

  void _showPicker(BuildContext context, RegisterViewModel vm) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { vm.pickImage(ImageSource.gallery); Navigator.pop(context); }),
      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { vm.pickImage(ImageSource.camera); Navigator.pop(context); }),
    ])));
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
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