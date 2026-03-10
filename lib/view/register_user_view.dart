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

  // دالة الفحص بصمت لتغيير الستايل (Bold) بدون إظهار الأحمر
  bool _isFieldValid(String label, String value) {
    if (value.trim().isEmpty) return false;
    if (label == "Full Name") {
      final nameRegExp = RegExp(r"^[a-zA-Z\s\u0600-\u06FF]+$");
      return value.trim().split(RegExp(r'\s+')).length >= 3;
    }
    if (label == "Email Address")
      return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|net|org|sa)$")
          .hasMatch(value.trim());
    if (label == "Phone Number")
      return RegExp(r'^05\d{8}$').hasMatch(value.trim());
    if (label == "Username") return value.trim().length >= 3;
    if (label == "Password" || label == "Confirm Password") {
      return value.length >= 8 &&
          value.contains(RegExp(r'[A-Z]')) &&
          value.contains(RegExp(r'[0-9]'));
    }
    return value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Register Participant",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode
              .disabled, // معطل لضمان ظهور التنبيهات عند الـ Submit فقط
          child: Column(
            children: [
              _buildField(
                _fullNameController,
                "Full Name",
                "Enter your first, middle, and last name",
                Icons.badge_outlined,
                customValidator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return "Enter your first, middle, and last name";
                  if (!RegExp(r"^[a-zA-Z\s\u0600-\u06FF]+$").hasMatch(v.trim())) {
                    return "Only letters are allowed ";
                  }
                  if (v.trim().split(RegExp(r'\s+')).length < 3)
                    return "Enter your first, middle, and last name ";
                  return null;
                },
              ),
              _buildField(
                _usernameController,
                "Username",
                "minimum 3 characters , spaces are not allowed",
                Icons.person_outline,
                customValidator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return "minimum 3 characters , spaces are not allowed";
                  if (v.contains(' '))
                    return "Spaces are not allowed"; // ✅ هذا هو شرط منع المسافات
                  if (v.trim().length < 3) return "At least 3 characters";
                  return null;
                },
              ),
            _buildField(
  _emailController,
  "Email Address",
  "Example: sara@gmail.com", // المثال ثابت هنا كـ Helper Text
  Icons.email_outlined,
  type: TextInputType.emailAddress,
  customValidator: (v) {
    if (v == null || v.trim().isEmpty) {
      return "Example: sara@gmail.com";
    }

    String email = v.trim();

    // 1. نسي علامة @
    if (!email.contains('@')) {
      return "Follow example: sara@gmail.com";
    }

    // 2. حط @ بس ما كمل بعدها شي (الدومين)
    if (email.endsWith('@')) {
      return "Follow example:sara@gmail.com";
    }

    // 3. نسي النقطة (.) بعد الـ @
    String domainPart = email.substring(email.indexOf('@'));
    if (!domainPart.contains('.')) {
      return "Follow example:sara@gmail.com";
    }

    // 4. حط مسافات داخل الإيميل
    if (email.contains(' ')) {
      return "Follow example:sara@gmail.com";
    }

    // 5. الصيغة العامة (للتأكد من النهايات الصحيحة)
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|net|org|sa)$");
    if (!regex.hasMatch(email)) {
      return "Follow example:sara@gmail.com";
    }

    return null;
  },
),
              _buildField(
                _phoneController,
                "Phone Number",
                "10 digits starting with 05",
                Icons.phone_android,
                type: TextInputType.phone,
                customValidator: (v) {
                  final regex = RegExp(r'^05\d{8}$');
                  if (v == null || !regex.hasMatch(v.trim()))
                    return "must be 10 digits starting with 05";
                  return null;
                },
              ),
              _buildPassField(
                  _passwordController,
                  "Password",
                  "min 8 chars, include capital letter, number, symbol",
                  _isPasswordVisible,
                  () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible)),
              _buildPassField(
                  _confirmPasswordController,
                  "Confirm Password",
                  "match the same password above",
                  _isConfirmVisible,
                  () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                  isConfirm: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: vm.isLoading ? null : _submit,
                  child: vm.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String label, String helper, IconData icon,
      {TextInputType type = TextInputType.text,
      String? Function(String?)? customValidator}) {
    bool isValid = _isFieldValid(label, ctrl.text);
    bool isEmail = label == "Email Address";
    bool isPhone = label == "Phone Number";

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        maxLength: isPhone ? 10 : 40,
        maxLines: isPhone ? 1 : null,
        minLines: 1,
// ✅ التعديل الذكي لنوع لوحة المفاتيح
        keyboardType: isPhone
            ? TextInputType.phone // لو كان جوال تطلع أرقام بس
            : (label == "Email Address"
                ? TextInputType.emailAddress
                : TextInputType.multiline),
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          counterText: "", // ✅ هذا السطر يخفي العداد نهائياً (0/40)
          helperStyle: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: Icon(icon, color: purple),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isValid ? purple : Colors.grey.shade300,
              width: isValid ? 2.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: purple, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: customValidator,
      ),
    );
  }

  Widget _buildPassField(TextEditingController ctrl, String label,
      String helper, bool visible, VoidCallback toggle,
      {bool isConfirm = false}) {
    bool isValid = _isFieldValid(label, ctrl.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: ctrl,
        obscureText: !visible,
        maxLength: 40, // ✅ تحديد 40 حرف
        maxLines: 1,
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          counterText: "", // ✅ إخفاء العداد في الباسورد أيضاً
          helperStyle: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: Icon(Icons.lock_outline, color: purple),
          suffixIcon: IconButton(
              icon: Icon(visible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey),
              onPressed: toggle),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isValid ? purple : Colors.grey.shade300,
              width: isValid ? 2.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: purple, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) {
    // هنا السر: إذا كان الحقل هو 'Confirm Password' تطلع الجملة اللي اخترتيها
    // وإذا كان الباسورد الأساسي تطلع الشروط الطويلة
    return isConfirm 
        ? "match the same password above" 
        : "min 8 chars, include capital letter, number, symbol";
  }
          if (isConfirm && v != _passwordController.text)
            return "Passwords do not match";
          if (!isConfirm) {
            if (v.length < 8) return "min 8 chars, include capital letter, number, symbol";
            if (!v.contains(RegExp(r'[A-Z]'))) return "min 8 chars, include capital letter, number, symbol";
            if (!v.contains(RegExp(r'[0-9]'))) return "min 8 chars, include capital letter, number, symbol";
            if (!v.contains(RegExp(r'[!@#$%^&*(),._?":{}|<>]')))
              return "min 8 chars, include capital letter, number, symbol";
          }
          return null;
        },
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // ✅ إنشاء الموديل بناءً على تعريف الكلاس الخاص بكِ بدقة
      final user = UserModel(
        uid: "", // يتم توليده تلقائياً في الـ ViewModel بعد التسجيل في فايربيز
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        // الحقول التالية اختيارية نتركها فارغة في البداية
        profilePhotoPath: null,
        bio: "",
        city: "",
        gender: "Not Specified",
        skills: [], // مصفوفة فارغة في البداية
        linkedin: "",
        github: "",
      );

      // إرسال البيانات للـ ViewModel
      context
          .read<RegisterViewModel>()
          .registerUser(user, _passwordController.text, context);
    }
  }
}
