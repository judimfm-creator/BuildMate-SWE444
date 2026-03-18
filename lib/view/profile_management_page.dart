import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/model/user_model.dart';
import 'package:buildmate/viewmodel/profile_view_model.dart';
import 'package:buildmate/viewmodel/register_view_model.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  late ProfileViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _skillController = TextEditingController();

  final Color deepMediumPurple = const Color(0xFF7A62B3);
  final Color deleteRed = const Color(0xFFD9534F);

  bool _isEditMode = false;
  bool _isInitialized = false;
  bool _obscurePassword = true;

  final Set<String> _itemsMarkedForDeletion = {};
  final Map<String, TextEditingController> _controllers = {};
  String? _selectedGender;
  List<String> _selectedSkills = [];
  final List<String> _predefinedSkills = ["UI/UX", "Flutter", "Python", "Java", "Teamwork"];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = Provider.of<ProfileViewModel>(context);
    if (!_isInitialized) { _loadUserData(); }
  }

  Future<void> _loadUserData() async {
    _viewModel.userDataStream.first.then((user) {
      if (user != null && mounted) {
        setState(() {
          _controllers["Full Name"] = TextEditingController(text: user.fullName);
          _controllers["Username"] = TextEditingController(text: user.username);
          _controllers["Email Address"] = TextEditingController(text: user.email);
          _controllers["Phone Number"] = TextEditingController(text: user.phoneNumber);
          _controllers["Biography"] = TextEditingController(text: user.bio ?? "");
          _controllers["City"] = TextEditingController(text: user.city ?? "");
          _controllers["LinkedIn"] = TextEditingController(text: user.linkedin ?? "");
          _controllers["GitHub"] = TextEditingController(text: user.github ?? "");
          _selectedGender = user.gender;

          if (user.skills is List) {
            _selectedSkills = List<String>.from(user.skills);
          } else if (user.skills is String && (user.skills as String).isNotEmpty) {
            _selectedSkills = (user.skills as String).split(", ").map((e) => e.trim()).toList();
          }
          _itemsMarkedForDeletion.clear();
          _isInitialized = true;
        });
      }
    }).catchError((_) { if (mounted) setState(() => _isInitialized = true); });
  }

  void _toggleDeletion(String key) {
    setState(() {
      if (_itemsMarkedForDeletion.contains(key)) { _itemsMarkedForDeletion.remove(key); } 
      else { _itemsMarkedForDeletion.add(key); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        final user = viewModel.currentUser;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: BuildMateAppBar(
            showBack: true,
            onBack: () => Navigator.pop(context),
            onLogout: () async => await Provider.of<RegisterViewModel>(context, listen: false).logout(context),
          ),
          body: !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildEditToggle(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatarSection(user),
                              const SizedBox(height: 25),
                              _buildSectionTitle("Personal Info"),
                              _buildInfoField("Full Name", Icons.badge_outlined),
                              _buildInfoField("Username", Icons.person_outline),
                              _buildInfoField("Email Address", Icons.email_outlined, isAlwaysDisabled: true),
                              _buildInfoField("Phone Number", Icons.phone_android, isAlwaysDisabled: true),
                              const SizedBox(height: 15),
                              _buildSectionTitle("Skills"),
                              _buildSkillsSection(),
                              const SizedBox(height: 15),
                              _buildSectionTitle("Additional Details"),
                              _buildFieldRow("Biography", "bio", Icons.info_outline, maxLength: 100),
                              _buildFieldRow("City", "city", Icons.location_city_outlined),
                              Opacity(
                                opacity: _isEditMode ? 1.0 : 0.3, 
                                child: _buildGenderDropdown(),
                              ),
                              _buildSectionTitle("Social Links"),
                              _buildFieldRow("LinkedIn", "linkedin", Icons.link),
                              _buildFieldRow("GitHub", "github", Icons.code_rounded),
                              const SizedBox(height: 40),
                              if (!_isEditMode) _buildDeleteButton(),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_isEditMode) _buildSaveButton(user),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSaveButton(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5)
            )
          ]
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: deepMediumPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: () async {
            // 1. فحص المدخلات (الشروط اللي طابقناها مع كرييت اكاونت)
            if (_formKey.currentState!.validate()) {
              final vm = Provider.of<RegisterViewModel>(context, listen: false);

              // 2. معالجة المهارات (تصفية المهارات اللي اخترتي حذفها)
              List<String> finalSkills = _selectedSkills
                  .where((s) => !_itemsMarkedForDeletion.contains("skill_$s"))
                  .toList();

              // 3. استدعاء دالة زميلتك (تحديث شامل للباك اند)
              // نمرر لها كل الحقول، وإذا الحقل محدد للحذف نرسل نص فارغ ""
              await vm.updateProfile(
                name: _controllers["Full Name"]?.text,     // 👈 أضيفي هذا السطر (سحب الاسم من التكست فيلد)
                username: _controllers["Username"]?.text,
                bio: _itemsMarkedForDeletion.contains("bio") ? "" : (_controllers["Biography"]?.text ?? ""),
                city: _itemsMarkedForDeletion.contains("city") ? "" : (_controllers["City"]?.text ?? ""),
                linkedin: _itemsMarkedForDeletion.contains("linkedin") ? "" : (_controllers["LinkedIn"]?.text ?? ""),
                github: _itemsMarkedForDeletion.contains("github") ? "" : (_controllers["GitHub"]?.text ?? ""),
                skills: finalSkills,
                gender: _selectedGender ?? "",
                context: context,
                // تمرير حالة حذف الصورة لدالة زميلتك
                deletePhoto: _itemsMarkedForDeletion.contains("photo"),
              );

              // 4. تحديث البيانات في واجهتك فوراً بعد الحفظ
              await _loadUserData();

              // 5. إغلاق وضع التعديل وتصفير قائمة الحذف
              setState(() {
                _isEditMode = false;
                _itemsMarkedForDeletion.clear();
                // تصفير الصورة المختارة في موديل زميلتك بعد الحفظ
                vm.clearPickedImage();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully! ✅'), backgroundColor: Colors.green)
              );
            }
          },
          child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. عرض المهارات الموجودة (Chips) - نفس الترتيب
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _selectedSkills.map((skill) {
            bool isMarked = _itemsMarkedForDeletion.contains("skill_$skill");
            return Opacity(
              opacity: isMarked ? 0.3 : 1.0,
              child: InputChip(
                label: Text(skill),
                backgroundColor: isMarked ? Colors.grey.shade200 : deepMediumPurple.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: isMarked ? Colors.grey : deepMediumPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                // أيقونة الحذف تظهر فقط في وضع التعديل
                onDeleted: _isEditMode ? () => _toggleDeletion("skill_$skill") : null,
                deleteIcon: Icon(
                  isMarked ? Icons.undo : Icons.cancel,
                  size: 18,
                  color: isMarked ? Colors.blue : Colors.red,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isMarked ? Colors.grey : deepMediumPurple,
                    width: 1.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // 2. حقل "Add Skill" - يظهر في وضع التعديل بنفس ستايل Complete Profile
        if (_isEditMode) ...[
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100, width: 1),
              // إضافة ظل خفيف ليطابق ستايل حقول الإدخال عندك
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.star_border, color: deepMediumPurple, size: 20),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Add Skill", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                      TextFormField(
                        controller: _skillController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "e.g. Flutter",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        onFieldSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              if (!_selectedSkills.contains(val.trim())) {
                                _selectedSkills.add(val.trim());
                              }
                              _skillController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: deepMediumPurple),
                  onPressed: () {
                    if (_skillController.text.trim().isNotEmpty) {
                      setState(() {
                        if (!_selectedSkills.contains(_skillController.text.trim())) {
                          _selectedSkills.add(_skillController.text.trim());
                        }
                        _skillController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldRow(String label, String key, IconData icon, {int? maxLength}) {
    bool isMarked = _itemsMarkedForDeletion.contains(key);
    return Row(
      children: [
        Expanded(child: Opacity(opacity: isMarked ? 0.3 : 1.0, child: _buildInfoField(label, icon, maxLength: maxLength))),
        if (_isEditMode) IconButton(
          icon: Icon(isMarked ? Icons.undo : Icons.close, color: isMarked ? Colors.blue : Colors.red),
          onPressed: () => _toggleDeletion(key),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, IconData icon, {bool isAlwaysDisabled = false, int? maxLength}) {
    TextEditingController ctrl = _controllers[label] ?? TextEditingController();
    bool canEdit = _isEditMode && !isAlwaysDisabled;

    bool isBio = label.toLowerCase().contains("bio") || label.toLowerCase().contains("biography");
    bool isPhone = label.toLowerCase().contains("phone");
    bool isEmail = label.toLowerCase().contains("email");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: canEdit ? deepMediumPurple.withOpacity(0.5) : Colors.grey.shade100,
              width: canEdit ? 1.5 : 1
          )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: deepMediumPurple, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                TextFormField(
                  controller: ctrl,
                  enabled: canEdit,
                  maxLines: isPhone ? 1 : null,
                  maxLength: isBio ? 100 : (isPhone ? 10 : 40),
                  keyboardType: isPhone
                      ? TextInputType.phone
                      : (isEmail ? TextInputType.emailAddress : TextInputType.multiline),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: isBio ? null : "",
                    errorStyle: const TextStyle(fontSize: 10, color: Colors.red),
                  ),
                  // ✅ مطابقة الشروط والرسائل حرفياً مع Create Account
                  validator: (value) {
                    if (!canEdit) return null;
                    String v = value?.trim() ?? "";

                    if (label == "Full Name") {
                      if (v.isEmpty) return "Enter your first, middle, last name(Letters only)";
                      if (!RegExp(r"^[a-zA-Z\s\u0600-\u06FF]+$").hasMatch(v)) return "Enter your first, middle, last name(Letters only)";
                      if (v.split(RegExp(r'\s+')).length < 3) return "Enter your first, middle, last name(Letters only)";
                    }

                    if (label == "Username") {
                      if (v.isEmpty) return "minimum 3 characters , spaces are not allowed";
                      if (v.contains(' ')) return "minimum 3 characters , spaces are not allowed";
                      if (v.length < 3) return "minimum 3 characters , spaces are not allowed";
                    }

                    if (label == "LinkedIn") {
                      if (v.isNotEmpty && !v.contains("linkedin.com/")) {
                        return "Please enter a valid LinkedIn URL";
                      }
                    }

                    if (label == "GitHub") {
                      if (v.isNotEmpty && !v.contains("github.com/")) {
                        return "Please enter a valid GitHub URL";
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          if (isAlwaysDisabled)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade300),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(UserModel? user) {
    // استدعاء الـ ViewModel اللي فيه شغل زميلتك
    final registerVm = Provider.of<RegisterViewModel>(context);
    bool isMarked = _itemsMarkedForDeletion.contains("photo");

    ImageProvider? imageProvider;

    // أولاً: نتحقق إذا فيه صورة اختارتها زميلتك بـ "pickedImage"
    if (registerVm.pickedImage != null) {
      imageProvider = FileImage(registerVm.pickedImage!);
    }
    // ثانياً: إذا ما فيه، نعرض الصورة اللي جاية من السيرفر أصلاً
    else if (user?.profilePhotoPath != null && user!.profilePhotoPath!.isNotEmpty) {
      imageProvider = user.profilePhotoPath!.startsWith('http')
          ? NetworkImage(user.profilePhotoPath!)
          : FileImage(File(user.profilePhotoPath!)) as ImageProvider;
    }

    return Center(
      child: Stack(
        children: [
          Opacity(
            opacity: isMarked ? 0.3 : 1.0,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: deepMediumPurple.withOpacity(0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person, size: 50, color: deepMediumPurple)
                  : null,
            ),
          ),
          if (_isEditMode) ...[
            // زر الكاميرا (مطابق لـ Complete Profile ويستدعي شغل زميلتك)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => registerVm.pickImage(ImageSource.gallery), // ميثود زميلتك
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: deepMediumPurple,
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ),
            // زر الحذف (من كودك الأصلي)
            if (imageProvider != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _toggleDeletion("photo"),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: isMarked ? Colors.blue : Colors.red,
                    child: Icon(
                        isMarked ? Icons.undo : Icons.close,
                        size: 14,
                        color: Colors.white
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditToggle() => Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Enable Editing Mode", style: TextStyle(color: _isEditMode ? deepMediumPurple : Colors.grey.shade600, fontWeight: FontWeight.bold)), Switch(value: _isEditMode, activeColor: deepMediumPurple, onChanged: (v) => setState(() { _isEditMode = v; }))]));
  
  Widget _buildGenderDropdown() => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15), 
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)), 
    child: Row(children: [
      Icon(Icons.wc_outlined, color: deepMediumPurple, size: 20), const SizedBox(width: 15), 
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Gender", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)), 
        _isEditMode 
          ? DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: (["Male", "Female"].contains(_selectedGender)) ? _selectedGender : null, 
              isDense: true, 
              hint: const Text("Select Gender", style: TextStyle(fontSize: 14)),
              items: ["Male", "Female"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(), 
              onChanged: (v) => setState(() => _selectedGender = v))) 
          : Text(_selectedGender ?? "Not set", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
      ]))
    ])
  );

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 5), child: Text(title, style: TextStyle(color: deepMediumPurple, fontSize: 14, fontWeight: FontWeight.bold)));

  Widget _buildDeleteButton() => Center(
    child: OutlinedButton.icon(
      onPressed: _handleDeleteAccount, 
      icon: Icon(Icons.delete_forever_outlined, color: deleteRed), 
      label: Text("Delete Account", style: TextStyle(color: deleteRed, fontWeight: FontWeight.bold)), 
      style: OutlinedButton.styleFrom(side: BorderSide(color: deleteRed.withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12)))
  );

  Future<void> _handleDeleteAccount() async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Account Deletion"),
        content: const Text(
            "Are you sure you want to permanently delete your account? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes, Delete",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmDelete != true) return;

    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _DeletePasswordDialog(),
    );

    if (password == null) return;

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    try {
      await _viewModel.deleteAccount(userEmail, password);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully ✅"),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/loginUser', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Failed"), backgroundColor: Colors.red),
        );
      }
    }
  }
}  // ✅ هذا القوس يغلق _ProfileManagementPageState







class _DeletePasswordDialog extends StatefulWidget {
  const _DeletePasswordDialog();

  @override
  State<_DeletePasswordDialog> createState() => _DeletePasswordDialogState();
}


class _DeletePasswordDialogState extends State<_DeletePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String? _serverError;
  bool _obscurePassword = true; // ✅ إضافة

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryDelete(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      if (context.mounted) Navigator.pop(context, _passwordController.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _serverError = "Incorrect password. Please try again.";
        } else {
          _serverError = e.message ?? "An error occurred.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter Password"),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword, // ✅
          decoration: InputDecoration(
            labelText: "Password",
            errorText: _serverError,
            suffixIcon: IconButton( // ✅ زر الإظهار/الإخفاء
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          onChanged: (_) {
            if (_serverError != null) {
              setState(() => _serverError = null);
            }
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Please enter the password";
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => _tryDelete(context),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}