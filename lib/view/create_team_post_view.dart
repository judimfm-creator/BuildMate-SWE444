import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateTeamPostScreen extends StatefulWidget {
  final String hackathonId;
  final int hackathonTeamSize;

  const CreateTeamPostScreen({
    super.key,
    required this.hackathonId,
    required this.hackathonTeamSize,
  });

  @override
  State<CreateTeamPostScreen> createState() => _CreateTeamPostScreenState();
}

class _CreateTeamPostScreenState extends State<CreateTeamPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _customRoleController = TextEditingController();
  final _ideaController = TextEditingController();

  String? _selectedRole;
  String? _selectedGender;
  bool _isLoading = false;
  bool _isFetchingRoles = true;
  List<String> _availableRoles = [];
  bool _allowCustomRole = false;

  static const Color purple = Color(0xFF6D56B3);

  @override
  void initState() {
    super.initState();
    _loadOrganizerData();
  }

  Future<void> _loadOrganizerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hackathons')
          .doc(widget.hackathonId)
          .get();

      if (doc.exists) {
        final List<dynamic>? roles = doc.data()?['rolesNeeded'];
        if (roles != null) {
          setState(() {
            _availableRoles = roles.map((e) => e.toString()).toList();
            _allowCustomRole =
                _availableRoles.any((r) => r.toLowerCase() == 'any');
          });
        }
      }
    } finally {
      setState(() => _isFetchingRoles = false);
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _customRoleController.dispose();
    _ideaController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required String helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      errorMaxLines: 2,
      prefixIcon: Icon(icon, color: purple),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Team Post',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isFetchingRoles
          ? const Center(child: CircularProgressIndicator(color: purple))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),


                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _teamNameController,
                          maxLength: 25,
                          decoration: _fieldDecoration(
                            label: 'Team Name',
                            icon: Icons.groups_rounded,
                            helper: 'Letters & numbers only',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Letters & numbers only';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(v)) {
                              return 'Letters & numbers only';
                            }
                            return null;
                          },
                        ),
                      ),


                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: _fieldDecoration(
                            label: 'Gender Preference',
                            icon: Icons.wc_rounded,
                            helper: 'Select Preference',
                          ),
                          items: ['Male', 'Female', 'Any']
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedGender = v),
                          validator: (v) =>
                              v == null ? 'Select Preference' : null,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                            label: 'My role in the team',
                            icon: Icons.person_search_rounded,
                            helper: 'Specify Your Role',
                          ),
                          items: _availableRoles
                              .map((r) =>
                                  DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRole = v),
                          validator: (v) =>
                              v == null ? 'Specify Your Role' : null,
                        ),
                      ),


                      if (_allowCustomRole && _selectedRole == 'Any') ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _customRoleController,
                            decoration: _fieldDecoration(
                              label: 'Specify Your Role',
                              icon: Icons.edit_note_rounded,
                              helper: 'Specify Your Role',
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Specify Your Role'
                                : null,
                          ),
                        ),
                      ],


                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _ideaController,
                          maxLength: 100,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            label: 'Project Idea (Optional)',
                            icon: Icons.lightbulb_outline,
                            helper: 'Briefly describe your idea',
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),


                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                              _isLoading ? 'Saving...' : 'Create Team Post',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;


      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final leaderName = userDoc.data()?['fullName'] ?? 'Unknown Leader';

      final finalRole = (_allowCustomRole && _selectedRole == 'Any')
          ? _customRoleController.text.trim()
          : _selectedRole;


      List<String> needed = List<String>.from(_availableRoles);
      needed.remove(finalRole);

      await FirebaseFirestore.instance.collection('team_posts').add({
        'hackathonId': widget.hackathonId,
        'createdBy': user.uid,
        'leaderId': user.uid,
        'leaderName':
            leaderName,
        'teamName': _teamNameController.text.trim(),
        'myRole': finalRole,
        'neededRoles': needed,
        'genderPreference': _selectedGender,
        'idea': _ideaController.text.trim(),
        'maxMembers': widget.hackathonTeamSize,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
        'members': [user.uid],
        'submittedToInstitution': false,
      });

      if (!mounted) return;
      Navigator.pop(context,true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
