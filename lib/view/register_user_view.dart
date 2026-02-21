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
        // نزول الحقول قليلاً عن الأعلى (top: 30)
        padding: const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, // الفحص الأحمر التفاعلي
          child: Column(
            children: [
<<<<<<< Updated upstream
              // حقل الاسم: يرفض أقل من 3 أسماء
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
                "minimum 3 characters ", 
                Icons.person_outline,
                customValidator: (v) => (v != null && v.trim().length < 3) ? "At least 3 characters" : null,
              ),
              
              // البريد الإلكتروني
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

              // رقم الجوال
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

              // كلمة المرور
              _buildPassField(
                _passwordController, 
                "Password", 
                "minimum 8 chars, include capital letter, number, symbol", 
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
=======
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

              _buildField(_phoneController, "Phone (05xxxxxxxx)", Icons.phone_android, (v) {
                final regex = RegExp(r'^05\d{8}$');
                return !regex.hasMatch(v!.trim()) ? "Must be 10 digits starting with 05" : null;
              }, type: TextInputType.phone),

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
>>>>>>> Stashed changes
              ),

              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
<<<<<<< Updated upstream
                    backgroundColor: purple, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: vm.isLoading ? null : _submit,
                  child: vm.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
=======
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: vm.isLoading ? null : _submit,
                  child: vm.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
>>>>>>> Stashed changes
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة بناء الحقول مع الإطارات الحمراء عند الخطأ
  Widget _buildField(TextEditingController ctrl, String label, String helper, IconData icon, {TextInputType type = TextInputType.text, String? Function(String?)? customValidator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
<<<<<<< Updated upstream
          labelText: label, 
          helperText: helper,
          helperStyle: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: Icon(icon, color: purple), 
          // الإطارات
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
=======
            labelText: label,
            prefixIcon: Icon(icon, color: purple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
>>>>>>> Stashed changes
        ),
        validator: customValidator,
      ),
    );
  }

  // دالة بناء حقول الباسورد
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
<<<<<<< Updated upstream
          suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: toggle),
          // الإطارات
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
=======
          suffixIcon: IconButton(
              icon: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
              onPressed: toggle
          ),
>>>>>>> Stashed changes
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "Required";
          if (isConfirm && v != _passwordController.text) return "Passwords do not match";
          if (!isConfirm) {
            if (v.length < 8) return "Min 8 characters";
            if (!v.contains(RegExp(r'[A-Z]'))) return "Add a capital letter";
            if (!v.contains(RegExp(r'[0-9]'))) return "Add a number";
            // قبول الـ underscore والرموز
            if (!v.contains(RegExp(r'[!@#$%^&*(),._?":{}|<>]'))) return "Add a symbol like _ or @";
          }
          return null;
        },
      ),
    );
  }

  // التعديل الجديد: تمرير الصورة من الـ ViewModel
  void _submit() {
<<<<<<< Updated upstream
  if (_formKey.currentState!.validate()) {
    // ✅ إضافة linkedin و github كقيم فارغة لحل الإيرور
    final user = UserModel(
      uid: "", // الفايربيز سيعطيها قيمة تلقائياً عند التسجيل
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      linkedin: "", // قيمة افتراضية فارغة
      github: "",   // قيمة افتراضية فارغة
    );
    
    context.read<RegisterViewModel>().registerUser(user, _passwordController.text, context);
=======
    if (_formKey.currentState!.validate()) {
      final vm = context.read<RegisterViewModel>();
      final user = UserModel(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profilePhotoPath: vm.pickedImage?.path, // ربط المسار هنا أيضاً
      );
      // تمرير vm.pickedImage لضمان حفظه في قاعدة البيانات
      vm.registerUser(user, _passwordController.text, vm.pickedImage, context);
    }
>>>>>>> Stashed changes
  }
}
}