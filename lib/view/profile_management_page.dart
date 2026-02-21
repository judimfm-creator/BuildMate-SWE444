import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buildmate/model/user_model.dart';
import 'package:buildmate/viewmodel/profile_view_model.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';
import '../viewmodel/register_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  late ProfileViewModel _viewModel;

  final Color deepMediumPurple = const Color(0xFF7A62B3);
  final Color deleteRed = const Color(0xFFD9534F);

  bool _isEditMode = false;
  final Map<String, TextEditingController> _controllers = {};
  String? _selectedGender;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = Provider.of<ProfileViewModel>(context);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _viewModel.uploadProfilePhoto(File(image.path), context);
      setState(() {}); 
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _viewModel.userDataStream,
      builder: (context, snapshot) {
        final user = snapshot.data;

        // ✅ تم تصحيح المسميات هنا لتقرأ من 'linkedin' و 'github' كما في الفايربيز
        if (user != null && _controllers.isEmpty) {
          _controllers["Full Name"] = TextEditingController(text: user.fullName);
          _controllers["Username"] = TextEditingController(text: user.username);
          _controllers["Email Address"] = TextEditingController(text: user.email);
          _controllers["Phone Number"] = TextEditingController(text: user.phoneNumber);
          _controllers["Biography"] = TextEditingController(text: user.bio ?? "");
          _controllers["City"] = TextEditingController(text: user.city ?? "");
          
          // حُذفت كلمة "Url" لأن الفايربيز عندك يخزنها كـ linkedin و github فقط
          _controllers["LinkedIn Profile"] = TextEditingController(text: user.linkedin ?? "");
          _controllers["GitHub Profile"] = TextEditingController(text: user.github ?? "");
          
          _selectedGender = user.gender;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: BuildMateAppBar(
            titleText: "Profile Management",
            //label: "Profile",
            showBack: true,
            onBack: () => Navigator.pop(context),
            onLogout: () async {
              await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
            },
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Enable Editing Mode",
                      style: TextStyle(
                        color: _isEditMode ? deepMediumPurple : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Switch(
                      value: _isEditMode,
                      activeColor: deepMediumPurple,
                      onChanged: (value) => setState(() => _isEditMode = value),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _isEditMode ? _pickImage : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: deepMediumPurple.withOpacity(0.1),
                                backgroundImage: (user?.profilePhotoPath != null && user!.profilePhotoPath!.isNotEmpty)
                                    ? (user.profilePhotoPath!.startsWith('http'))
                                    ? NetworkImage(user.profilePhotoPath!) as ImageProvider
                                    : FileImage(File(user.profilePhotoPath!))
                                    : null,
                                child: (user?.profilePhotoPath == null || user!.profilePhotoPath!.isEmpty)
                                    ? Icon(Icons.person, size: 50, color: deepMediumPurple)
                                    : null,
                              ),
                              if (_isEditMode)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: deepMediumPurple, shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildSectionTitle("Personal Info"),
                      _buildInfoField("Full Name", Icons.badge_outlined),
                      _buildInfoField("Username", Icons.person_outline),
                      _buildInfoField("Email Address", Icons.email_outlined, isAlwaysDisabled: true),
                      _buildInfoField("Phone Number", Icons.phone_android),
                      const SizedBox(height: 15),
                      _buildSectionTitle("Additional Details"),
                      _buildInfoField("Biography", Icons.info_outline),
                      _buildInfoField("City", Icons.location_city_outlined),
                      _buildGenderDropdown(),
                      
                      // حقول الروابط
                      _buildInfoField("LinkedIn Profile", Icons.link),
                      _buildInfoField("GitHub Profile", Icons.code_rounded),
                      
                      const SizedBox(height: 30),
                      if (!_isEditMode)
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Confirm Account Deletion"),
                                  content: const Text(
                                    "Are you sure you want to permanently delete your account? This action cannot be undone.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text(
                                        "Yes, Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmDelete != true) return;

                              final passwordController = TextEditingController();
                              final confirmPassword = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Enter Password"),
                                  content: TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(labelText: "Password"),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmPassword == true) {
                                final userEmail = FirebaseAuth.instance.currentUser?.email ?? "";
                                await _viewModel.deleteAccount(
                                  context,
                                  userEmail,
                                  passwordController.text,
                                );
                              }
                            },
                            icon: Icon(Icons.delete_forever_outlined, color: deleteRed, size: 18),
                            label: Text(
                              "Delete Account",
                              style: TextStyle(color: deleteRed, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                              side: BorderSide(color: deleteRed.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              if (_isEditMode) _buildSaveButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5, top: 10),
      child: Text(title, style: TextStyle(color: deepMediumPurple, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoField(String label, IconData icon, {bool isAlwaysDisabled = false}) {
    TextEditingController controller = _controllers[label] ?? TextEditingController();
    bool canEdit = _isEditMode && !isAlwaysDisabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canEdit ? deepMediumPurple.withOpacity(0.5) : Colors.grey.shade100,
          width: canEdit ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: deepMediumPurple, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 4),
                canEdit
                    ? TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                )
                    : Text(
                  controller.text,
                  style: TextStyle(
                    color: isAlwaysDisabled ? Colors.black54 : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isAlwaysDisabled)
            Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 16),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isEditMode ? deepMediumPurple.withOpacity(0.5) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.wc_outlined, color: deepMediumPurple, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Gender", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                const SizedBox(height: 4),
                _isEditMode
                    ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isDense: true,
                    items: ["Male", "Female"].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)));
                    }).toList(),
                    onChanged: (newValue) => setState(() => _selectedGender = newValue),
                  ),
                )
                    : Text(_selectedGender ?? "Not set", style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: deepMediumPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            // ✅ تأكدي أن دالة التحديث في الـ ViewModel ترسل linkedin و github أيضاً
            await _viewModel.updateProfile(
              name: _controllers["Full Name"]!.text,
              phone: _controllers["Phone Number"]!.text,
              bio: _controllers["Biography"]!.text,
              city: _controllers["City"]!.text,
              linkedin: _controllers["LinkedIn Profile"]!.text,
              github: _controllers["GitHub Profile"]!.text,
              gender: _selectedGender ?? "",
              context: context,
            );
            setState(() => _isEditMode = false);
          },
          child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
