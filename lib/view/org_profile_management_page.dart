import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buildmate/model/org_model.dart';
import 'package:buildmate/viewmodel/org_profile_view_model.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';
import 'package:buildmate/viewmodel/register_view_model.dart';

class OrgProfileManagementPage extends StatefulWidget {
  const OrgProfileManagementPage({super.key});

  @override
  State<OrgProfileManagementPage> createState() => _OrgProfileManagementPageState();
}

class _OrgProfileManagementPageState extends State<OrgProfileManagementPage> {
  late OrgProfileViewModel _viewModel;

  final Color deepMediumPurple = const Color(0xFF7A62B3);
  final Color deleteRed = const Color(0xFFD9534F);

  bool _isEditMode = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = Provider.of<OrgProfileViewModel>(context);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _viewModel.uploadOrgPhoto(File(image.path), context);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrgModel?>(
      stream: _viewModel.orgDataStream,
      builder: (context, snapshot) {
        final org = snapshot.data;

        if (org != null && _controllers.isEmpty) {
          _controllers["Organization Name"] = TextEditingController(text: org.orgName);
          _controllers["Phone Number"] = TextEditingController(text: org.phoneNumber);
          _controllers["Location"] = TextEditingController(text: org.location ?? "");
          _controllers["Biography"] = TextEditingController(text: org.biography ?? "");
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: BuildMateAppBar(
            titleText: "Account Management",
            showBack: true,
            onBack: () => Navigator.pop(context),
            onLogout: () async {
              await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
            },
          ),
          body: Column(
            children: [
              // مفتاح تبديل وضع التعديل (مطابق لليوزر)
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
                    children: [
                      _buildProfileImageSection(org),
                      const SizedBox(height: 25),
                      _buildSectionTitle("Organization Info"),
                      _buildInfoField("Organization Name", Icons.business_outlined),
                      _buildInfoField("Phone Number", Icons.phone_android_outlined),
                      const SizedBox(height: 15),
                      _buildSectionTitle("Additional Details"),
                      _buildInfoField("Location", Icons.location_on_outlined),
                      _buildInfoField("Biography", Icons.info_outline, maxLines: 3),
                      const SizedBox(height: 30),
                      if (!_isEditMode) _buildDeleteOption(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              if (_isEditMode) _buildSaveButton(org),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5, top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: deepMediumPurple, fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProfileImageSection(OrgModel? org) {
    return Center(
      child: GestureDetector(
        onTap: _isEditMode ? _pickImage : null,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: deepMediumPurple.withOpacity(0.1),
              backgroundImage: (org?.profilePhotoPath != null && org!.profilePhotoPath!.isNotEmpty)
                  ? FileImage(File(org.profilePhotoPath!))
                  : null,
              child: (org?.profilePhotoPath == null || org!.profilePhotoPath!.isEmpty)
                  ? Icon(Icons.business, size: 50, color: deepMediumPurple)
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
    );
  }

  Widget _buildInfoField(String label, IconData icon, {int maxLines = 1}) {
    TextEditingController controller = _controllers[label] ?? TextEditingController();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditMode ? deepMediumPurple.withOpacity(0.5) : Colors.grey.shade100,
          width: _isEditMode ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: deepMediumPurple, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 4),
                _isEditMode
                    ? TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                )
                    : Text(
                  controller.text.isEmpty ? "Not set" : controller.text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteOption() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.delete_forever_outlined, color: deleteRed, size: 18),
        label: Text("Delete Account", style: TextStyle(color: deleteRed, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          side: BorderSide(color: deleteRed.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSaveButton(OrgModel? org) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: deepMediumPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            await _viewModel.updateOrgProfile(
              name: _controllers["Organization Name"]!.text,
              phone: _controllers["Phone Number"]!.text,
              location: _controllers["Location"]!.text,
              bio: _controllers["Biography"]!.text,
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