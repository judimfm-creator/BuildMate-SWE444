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

  final Color deepMediumPurple = const Color(0xFF7A62B3);
  final Color lightGrey = const Color(0xFFF5F5F5);
  final Color deleteRed = const Color(0xFFD9534F);

  bool _isEditMode = false;
  bool _isInitialized = false;

  final Map<String, TextEditingController> _controllers = {};
  String? _selectedGender;
  List<String> _selectedSkills = [];
  final List<String> _predefinedSkills = ["UI/UX", "Flutter", "Python", "Java", "Teamwork"];
  List<TextEditingController> _otherSkillControllers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = Provider.of<ProfileViewModel>(context);
    if (!_isInitialized) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final user = await _viewModel.userDataStream.first;
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

        List<String> loadedSkills = user.skills?.split(", ").map((e) => e.trim()).toList() ?? [];
        _selectedSkills = loadedSkills.where((s) => _predefinedSkills.contains(s)).toList();
        _otherSkillControllers = loadedSkills
            .where((s) => !_predefinedSkills.contains(s) && s.isNotEmpty)
            .map((s) => TextEditingController(text: s))
            .toList();

        _isInitialized = true;
      });
    }
  }

  void _addOtherSkillField() => setState(() => _otherSkillControllers.add(TextEditingController()));

  void _removeOtherSkillField(int index) {
    setState(() {
      _otherSkillControllers[index].dispose();
      _otherSkillControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var ctrl in _otherSkillControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        final user = viewModel.currentUser;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: BuildMateAppBar(
            titleText: "Profile Management",
            showBack: true,
            onBack: () {
              // ✅ تعديل: السهم هنا يعيدك لصفحة البروفايل السابقة
              Navigator.pop(context);
            },
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
                        _buildInfoField("Biography", Icons.info_outline, maxLength: 100),
                        _buildInfoField("City", Icons.location_city_outlined),
                        _buildGenderDropdown(),
                        _buildSectionTitle("Social Links"),
                        _buildInfoField("LinkedIn", Icons.link),
                        _buildInfoField("GitHub", Icons.code_rounded),
                        const SizedBox(height: 30),
                        if (!_isEditMode) _buildDeleteButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
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

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _isEditMode
              ? _predefinedSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return GestureDetector(
              onTap: () => setState(() => isSelected ? _selectedSkills.remove(skill) : _selectedSkills.add(skill)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? deepMediumPurple.withOpacity(0.1) : lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? deepMediumPurple : Colors.grey.shade300, width: 1.5),
                ),
                child: Text(skill, style: TextStyle(color: isSelected ? deepMediumPurple : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList()
              : (_selectedSkills + _otherSkillControllers.map((e) => e.text).where((t) => t.isNotEmpty).toList())
              .map((skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: deepMediumPurple, width: 1.5)),
            child: Text(skill, style: TextStyle(color: deepMediumPurple, fontWeight: FontWeight.bold)),
          )).toList(),
        ),
        if (_isEditMode) ...[
          const SizedBox(height: 10),
          ..._otherSkillControllers.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(child: _buildInfoField("Other Skill", Icons.star_border, controller: entry.value)),
                IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _removeOtherSkillField(entry.key)
                ),
              ],
            ),
          )),
          TextButton.icon(onPressed: _addOtherSkillField, icon: const Icon(Icons.add, size: 18, color: Color(0xFF7A62B3)), label: Text("Add Other Skill", style: TextStyle(color: deepMediumPurple, fontWeight: FontWeight.bold))),
        ],
      ],
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changes saved locally! ✅ (Demo Mode)'), backgroundColor: Colors.green),
              );

              setState(() {
                _isEditMode = false;
              });
            }
          },
          child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showDeleteDialog() async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Account Deletion"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmDelete == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deletion disabled in Demo version")),
      );
    }
  }

  Widget _buildEditToggle() => Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Enable Editing Mode", style: TextStyle(color: _isEditMode ? deepMediumPurple : Colors.grey.shade600, fontWeight: FontWeight.bold)), Switch(value: _isEditMode, activeColor: deepMediumPurple, onChanged: (v) => setState(() { _isEditMode = v; }))]));

  Widget _buildInfoField(String label, IconData icon, {bool isAlwaysDisabled = false, int? maxLength, String? Function(String?)? validator, TextEditingController? controller}) {
    TextEditingController ctrl = controller ?? _controllers[label] ?? TextEditingController();
    bool canEdit = _isEditMode && !isAlwaysDisabled;
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: canEdit ? deepMediumPurple.withOpacity(0.5) : Colors.grey.shade100, width: canEdit ? 1.5 : 1)), child: Row(children: [Icon(icon, color: deepMediumPurple, size: 20), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)), TextFormField(controller: ctrl, enabled: canEdit, maxLength: maxLength, validator: validator, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero, counterText: ""), )])), if (isAlwaysDisabled) Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 16)]));
  }

  Widget _buildGenderDropdown() => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _isEditMode ? deepMediumPurple.withOpacity(0.5) : Colors.grey.shade100)), child: Row(children: [Icon(Icons.wc_outlined, color: deepMediumPurple, size: 20), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Gender", style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)), _isEditMode ? DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedGender, isDense: true, items: ["Male", "Female"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(), onChanged: (v) => setState(() => _selectedGender = v))) : Text(_selectedGender ?? "Not set", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]))]));

  Widget _buildAvatarSection(UserModel? user) => Center(child: GestureDetector(onTap: _isEditMode ? () {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo selection active (Demo)")));
  } : null, child: Stack(children: [CircleAvatar(radius: 50, backgroundColor: deepMediumPurple.withOpacity(0.1), backgroundImage: (user?.profilePhotoPath?.isNotEmpty ?? false) ? (user!.profilePhotoPath!.startsWith('http') ? NetworkImage(user.profilePhotoPath!) : FileImage(File(user.profilePhotoPath!))) as ImageProvider : null, child: (user?.profilePhotoPath?.isEmpty ?? true) ? Icon(Icons.person, size: 50, color: deepMediumPurple) : null), if (_isEditMode) Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: deepMediumPurple, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18)))])));

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 5), child: Text(title, style: TextStyle(color: deepMediumPurple, fontSize: 14, fontWeight: FontWeight.bold)));

  Widget _buildDeleteButton() => Center(child: OutlinedButton.icon(onPressed: _showDeleteDialog, icon: Icon(Icons.delete_forever_outlined, color: deleteRed, size: 18), label: Text("Delete Account", style: TextStyle(color: deleteRed, fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10), side: BorderSide(color: deleteRed.withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))));
}