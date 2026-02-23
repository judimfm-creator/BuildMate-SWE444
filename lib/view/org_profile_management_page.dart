import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/model/org_model.dart';
import 'package:buildmate/viewmodel/org_profile_view_model.dart';
import 'package:buildmate/viewmodel/register_view_model.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';

class OrgProfileManagementPage extends StatefulWidget {
  const OrgProfileManagementPage({super.key});

  @override
  State<OrgProfileManagementPage> createState() => _OrgProfileManagementPageState();
}

class _OrgProfileManagementPageState extends State<OrgProfileManagementPage> {
  final Color primaryPurple = const Color(0xFF7A62B3);
  final Color deleteRed = const Color(0xFFD9534F);

  bool _isEditMode = false;
  bool _isInitialized = false;

  final Set<String> _itemsMarkedForDeletion = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadOrgData();
    }
  }

  Future<void> _loadOrgData() async {
    final viewModel = Provider.of<OrgProfileViewModel>(context, listen: false);
    viewModel.orgDataStream.first.then((org) {
      if (org != null && mounted) {
        setState(() {
          _controllers["Organization Name"] = TextEditingController(text: org.orgName);
          _controllers["Username"] = TextEditingController(text: org.username ?? "");
          _controllers["Phone Number"] = TextEditingController(text: org.phoneNumber);
          _controllers["Location"] = TextEditingController(text: org.location ?? "");
          _controllers["Biography"] = TextEditingController(text: org.biography ?? "");
          _controllers["Email Address"] = TextEditingController(text: FirebaseAuth.instance.currentUser?.email ?? "");
          _itemsMarkedForDeletion.clear();
          _isInitialized = true;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isInitialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OrgProfileViewModel>(context);

    return StreamBuilder<OrgModel?>(
      stream: viewModel.orgDataStream,
      builder: (context, snapshot) {
        final org = snapshot.data;

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAvatarSection(org),
                            const SizedBox(height: 25),
                            _buildSectionTitle("Organization Info"),
                            _buildInfoField("Organization Name", Icons.business_rounded),
                            _buildInfoField("Username", Icons.person_outline),
                            _buildInfoField("Email Address", Icons.email_outlined, isAlwaysDisabled: true),
                            _buildInfoField("Phone Number", Icons.phone_android, isAlwaysDisabled: true),
                            const SizedBox(height: 15),
                            _buildSectionTitle("Additional Details"),
                            _buildFieldRow("Biography", "biography", Icons.info_outline, maxLines: 3),
                            _buildInfoField("Location", Icons.location_on_outlined), 
                            const SizedBox(height: 30),
                            if (!_isEditMode) _buildDeleteButton(),
                            const SizedBox(height: 50),
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

  Widget _buildInfoField(String label, IconData icon, {bool isAlwaysDisabled = false, int maxLines = 1}) {
    TextEditingController ctrl = _controllers[label] ?? TextEditingController();
    bool canEdit = _isEditMode && !isAlwaysDisabled;

    return Opacity(
      opacity: _isEditMode ? 1.0 : 0.6, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: canEdit ? primaryPurple.withOpacity(0.5) : Colors.grey.shade100, width: canEdit ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: primaryPurple, size: 20),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  const SizedBox(height: 2),
                  TextFormField(
                    controller: ctrl,
                    enabled: canEdit,
                    maxLines: maxLines,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (isAlwaysDisabled) Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, String key, IconData icon, {int maxLines = 1}) {
    bool isMarked = _itemsMarkedForDeletion.contains(key);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Opacity(
            opacity: isMarked ? 0.3 : 1.0, 
            child: _buildInfoField(label, icon, maxLines: maxLines)
          )
        ),
        if (_isEditMode)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 5),
            child: IconButton(
              icon: Icon(isMarked ? Icons.undo : Icons.close, color: isMarked ? Colors.blue : Colors.red),
              onPressed: () => setState(() {
                isMarked ? _itemsMarkedForDeletion.remove(key) : _itemsMarkedForDeletion.add(key);
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton(OrgModel? org) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            final orgVM = Provider.of<OrgProfileViewModel>(context, listen: false);
            final regVM = Provider.of<RegisterViewModel>(context, listen: false);

            if (_itemsMarkedForDeletion.isNotEmpty) {
              await orgVM.updateOrgProfile(
                name: org?.orgName ?? "",
                phone: org?.phoneNumber ?? "",
                location: org?.location ?? "",
                bio: _itemsMarkedForDeletion.contains("biography") ? "" : (org?.biography ?? ""),
                context: context,
              );
              if (_itemsMarkedForDeletion.contains("photo")) regVM.clearPickedImage();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully! ✅'), backgroundColor: Colors.green));
              await _loadOrgData();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved locally! ✅ (Demo Mode)'), backgroundColor: Colors.green));
            }

            setState(() { _isEditMode = false; _itemsMarkedForDeletion.clear(); });
          },
          child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(OrgModel? org) {
    bool isMarked = _itemsMarkedForDeletion.contains("photo");
    ImageProvider? imageProvider;
    if (org?.profilePhotoPath != null && org!.profilePhotoPath!.isNotEmpty) {
      imageProvider = org.profilePhotoPath!.startsWith('http') ? NetworkImage(org.profilePhotoPath!) : FileImage(File(org.profilePhotoPath!)) as ImageProvider;
    }
    return Center(child: Stack(children: [
      Opacity(opacity: isMarked ? 0.3 : 1.0, child: CircleAvatar(radius: 50, backgroundColor: primaryPurple.withOpacity(0.1), backgroundImage: imageProvider, child: imageProvider == null ? Icon(Icons.business, size: 50, color: primaryPurple) : null)),
      if (_isEditMode && imageProvider != null) Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setState(() => isMarked ? _itemsMarkedForDeletion.remove("photo") : _itemsMarkedForDeletion.add("photo")), child: CircleAvatar(radius: 14, backgroundColor: isMarked ? Colors.blue : Colors.red, child: Icon(isMarked ? Icons.undo : Icons.close, size: 14, color: Colors.white))))
    ]));
  }

  Widget _buildEditToggle() => Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Enable Editing Mode", style: TextStyle(color: _isEditMode ? primaryPurple : Colors.grey.shade600, fontWeight: FontWeight.bold)), Switch(value: _isEditMode, activeColor: primaryPurple, onChanged: (v) => setState(() { _isEditMode = v; }))]));
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 5), child: Text(title, style: TextStyle(color: primaryPurple, fontSize: 14, fontWeight: FontWeight.bold)));

  // ✅ تفعيل حذف الحساب الحقيقي للمنشأة (نفس نظام اليوزر)
  Widget _buildDeleteButton() => Center(
    child: OutlinedButton.icon(
      onPressed: _handleDeleteAccount, 
      icon: Icon(Icons.delete_forever_outlined, color: deleteRed), 
      label: Text("Delete Account", style: TextStyle(color: deleteRed, fontWeight: FontWeight.bold)), 
      style: OutlinedButton.styleFrom(side: BorderSide(color: deleteRed.withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12))
    )
  );

  Future<void> _handleDeleteAccount() async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Account Deletion"),
        content: const Text("Are you sure you want to permanently delete your organization account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmDelete != true) return;

    final passwordController = TextEditingController();

    final confirmPassword = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Enter Password"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmPassword != true) return;

    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    final orgVM = Provider.of<OrgProfileViewModel>(context, listen: false);

    // ✅ استدعاء دالة الحذف من الـ ViewModel الخاص بالمنظمة
    await orgVM.DeleteAccount(
      context,
      userEmail,
      passwordController.text,
    );
  }
}