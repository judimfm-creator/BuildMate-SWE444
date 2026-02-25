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
  bool _obscurePassword = true;

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
                            _buildFieldRow("Biography", "biography", Icons.info_outline),
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

  Widget _buildInfoField(String label, IconData icon, {bool isAlwaysDisabled = false}) {
    TextEditingController ctrl = _controllers[label] ?? TextEditingController();
    bool canEdit = _isEditMode && !isAlwaysDisabled;

    bool isBio = label.toLowerCase().contains("bio") || label.toLowerCase().contains("biography");
    bool isPhone = label.toLowerCase().contains("phone");
    bool isEmail = label.toLowerCase().contains("email");

    return Opacity(
      opacity: _isEditMode ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canEdit ? primaryPurple.withOpacity(0.5) : Colors.grey.shade100,
            width: canEdit ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // الأيقونة تبقى فوق عند تعدد الأسطر
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: primaryPurple, size: 20),
            ),
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
                    maxLines: (isPhone || isEmail) ? 1 : null,
                    maxLength: isBio ? 100 : (isPhone ? 10 : 40),
                    keyboardType: isPhone
                        ? TextInputType.phone
                        : (isEmail ? TextInputType.emailAddress : TextInputType.multiline),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      counterText: isBio ? null : "", // إظهار العداد فقط في البيو
                    ),
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
      ),
    );
  }

  Widget _buildFieldRow(String label, String key, IconData icon) {
    bool isMarked = _itemsMarkedForDeletion.contains(key);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Opacity(
                opacity: isMarked ? 0.3 : 1.0,
                child: _buildInfoField(label, icon)
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
  name: _controllers["Organization Name"]?.text ?? org?.orgName ?? "",
  phone: _controllers["Phone Number"]?.text ?? org?.phoneNumber ?? "",
  location: _itemsMarkedForDeletion.contains("location") ? "" : (_controllers["Location"]?.text ?? ""),
  bio: _itemsMarkedForDeletion.contains("biography") ? "" : (_controllers["Biography"]?.text ?? ""),
  context: context,
  // الحل: نرسل "" فقط لو ضغطتي حذف، ونرسل null لو ما لمستي الصورة عشان ما تتغير
  image: _itemsMarkedForDeletion.contains("photo") ? "" : (regVM.pickedImage?.path),
);

// تأكدي أن هذا السطر موجود عشان الصورة تختفي من الشاشة
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

    // ✅ نفس نظام اليوزر — Widget مستقل
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _OrgDeletePasswordDialog(),
    );

    if (password == null) return;


    final orgVM = Provider.of<OrgProfileViewModel>(context, listen: false);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    try {
      await orgVM.deleteAccount(userEmail, password);
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
          SnackBar(content: Text(e.message ?? "Failed to delete account"), backgroundColor: Colors.red),
        );
      }
    }
  }
}


// ✅ Widget مستقل للـ dialog — نفس نظام اليوزر
class _OrgDeletePasswordDialog extends StatefulWidget {
  const _OrgDeletePasswordDialog();

  @override
  State<_OrgDeletePasswordDialog> createState() => _OrgDeletePasswordDialogState();
}

class _OrgDeletePasswordDialogState extends State<_OrgDeletePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String? _serverError;
  bool _obscurePassword = true;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Enter Password"),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Password",
            errorText: _serverError,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onChanged: (_) {
            if (_serverError != null) setState(() => _serverError = null);
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
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel")),
        TextButton(
          onPressed: () => _tryDelete(context),
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}