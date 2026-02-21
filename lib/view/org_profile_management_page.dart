import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/viewmodel/org_profile_view_model.dart';
import 'package:buildmate/viewmodel/register_view_model.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';
import 'package:buildmate/model/org_model.dart';

class OrgProfileManagementPage extends StatefulWidget {
  const OrgProfileManagementPage({super.key});

  @override
  State<OrgProfileManagementPage> createState() => _OrgProfileManagementPageState();
}

class _OrgProfileManagementPageState extends State<OrgProfileManagementPage> {
  final Color primaryPurple = const Color(0xFF7A62B3);
  final Color deleteRed = const Color(0xFFD9534F);
  bool _isEditMode = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OrgProfileViewModel>(context);
    final String userEmail = FirebaseAuth.instance.currentUser?.email ?? "Not Available";

    return StreamBuilder<OrgModel?>(
      stream: viewModel.orgDataStream,
      builder: (context, snapshot) {
        final org = snapshot.data;

        if (org != null && _controllers.isEmpty) {
          _controllers["Organization Name"] = TextEditingController(text: org.orgName);
          _controllers["Username"] = TextEditingController(text: org.username ?? "");
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
            onLogout: () async => await Provider.of<RegisterViewModel>(context, listen: false).logout(context),
          ),
          body: Column(
            children: [
              _buildEditToggle(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      _buildAvatarSection(org),
                      const SizedBox(height: 25),
                      _buildSectionTitle("Organization Info"),
                      _buildInfoField("Organization Name", Icons.business_rounded, isEditable: true),
                      // ✅ اليوزر نيم قابل للتعديل
                      _buildInfoField("Username", Icons.alternate_email, isEditable: true),

                      const SizedBox(height: 15),
                      _buildSectionTitle("Contact Details"),
                      // ✅ الإيميل ثابت (مشبوك ومقفل)
                      _buildFixedField("Email Address", userEmail, Icons.email_outlined),
                      // ✅ رقم الجوال ثابت (مشبوك ومقفل)
                      _buildFixedField("Phone Number", _controllers["Phone Number"]?.text ?? "", Icons.phone_android_rounded),

                      const SizedBox(height: 15),
                      _buildSectionTitle("Additional Details"),
                      _buildInfoField("Location", Icons.location_on_outlined, isEditable: true),
                      _buildInfoField("Biography", Icons.description_outlined, maxLines: 3, isEditable: true),
                      const SizedBox(height: 30),
                      if (!_isEditMode) _buildDeleteButton(),
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

  // ✅ دالة الرسائل (SnackBar) مطابقة تماماً لستايل صفحة اليوزر (ملتصقة بالأسفل)
  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? deleteRed : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.fixed, // مشبوكة بالأسفل تماماً
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSaveButton() => Container(
    padding: const EdgeInsets.all(20),
    child: SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: () {
          _showCustomSnackBar("Profile Updated Successfully ✅");
          setState(() => _isEditMode = false);
        },
        child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    ),
  );

  Widget _buildFixedField(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, IconData icon, {int maxLines = 1, required bool isEditable}) {
    TextEditingController controller = _controllers[label] ?? TextEditingController();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (_isEditMode && isEditable) ? primaryPurple.withOpacity(0.5) : Colors.grey.shade100, width: (_isEditMode && isEditable) ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryPurple, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                (_isEditMode && isEditable)
                    ? TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                )
                    : Text(controller.text.isEmpty ? "Not set" : controller.text,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditToggle() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Enable Editing Mode", style: TextStyle(color: _isEditMode ? primaryPurple : Colors.grey, fontWeight: FontWeight.bold)),
        Switch(value: _isEditMode, activeColor: primaryPurple, onChanged: (v) => setState(() => _isEditMode = v)),
      ],
    ),
  );

  Widget _buildAvatarSection(org) => Center(
    child: Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: primaryPurple.withOpacity(0.1),
          backgroundImage: (org?.profilePhotoPath?.isNotEmpty ?? false) ? FileImage(File(org!.profilePhotoPath!)) : null,
          child: (org?.profilePhotoPath?.isEmpty ?? true) ? Icon(Icons.business, size: 50, color: primaryPurple) : null,
        ),
        if (_isEditMode)
          Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: primaryPurple, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))),
      ],
    ),
  );

  Widget _buildSectionTitle(String title) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(title, style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold))));

  Widget _buildDeleteButton() => OutlinedButton.icon(
    onPressed: () => _showCustomSnackBar("Account Deletion is not available in Demo Mode", isError: true),
    icon: Icon(Icons.delete_outline, color: deleteRed),
    label: Text("Delete Account", style: TextStyle(color: deleteRed)),
    style: OutlinedButton.styleFrom(side: BorderSide(color: deleteRed.withOpacity(0.3))),
  );
}