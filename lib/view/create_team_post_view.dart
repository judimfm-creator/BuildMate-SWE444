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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBackground = Color(0xFFF8F7FB);
  static const Color _borderColor = Color(0xFFE6E1F3);

  String? _selectedGender;
  bool _isLoading = false;

  final RegExp _lettersOnlyRegex = RegExp(r'^[A-Za-z ]+$');

  @override
  void dispose() {
    _teamNameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  bool _containsOnlyLetters(String value) {
    return _lettersOnlyRegex.hasMatch(value.trim());
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User is not logged in.'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final firestore = FirebaseFirestore.instance;

      final existingTeam = await firestore
          .collection('team_posts')
          .where('hackathonId', isEqualTo: widget.hackathonId)
          .where('createdBy', isEqualTo: user.uid)
          .get();

      if (existingTeam.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have already created a team post for this hackathon.',
            ),
          ),
        );
        return;
      }

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final String leaderName =
          (userData['fullName'] ?? user.displayName ?? 'Unknown Leader')
              .toString();

      final String teamName = _teamNameController.text.trim();
      final String myRole = _roleController.text.trim();

      await firestore.collection('team_posts').add({
        'hackathonId': widget.hackathonId,
        'createdBy': user.uid,
        'leaderId': user.uid,
        'leaderName': leaderName,
        'teamName': teamName,
        'genderPreference': _selectedGender,
        'myRole': myRole,
        'neededRoles': [myRole],
        'description': 'Team is looking for members to join.',
        'members': [user.uid],
        'currentMembers': 1,
        'maxMembers': widget.hackathonTeamSize,
        'isTeamComplete': widget.hackathonTeamSize == 1,
        'submittedToInstitution': false,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team post created successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create team post: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String helperText) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperMaxLines: 2,
      errorMaxLines: 2,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purple, width: 1.4),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Team Post'),
        centerTitle: true,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                'Team Post Information',
                'Create a team post for this hackathon so other users can join your team.',
              ),
              _buildSectionCard([
                TextFormField(
                  controller: _teamNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Team Name',
                    'Letters only, at least one word.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Team name is required';
                    }
                    if (!_containsOnlyLetters(text)) {
                      return 'Team name must contain letters only';
                    }
                    if (text.length < 2) {
                      return 'Team name is too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: _inputDecoration(
                    'Gender Preference',
                    'Select either Male or Female.',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Male',
                      child: Text('Male'),
                    ),
                    DropdownMenuItem(
                      value: 'Female',
                      child: Text('Female'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roleController,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    'My Role',
                    'Letters only.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Role is required';
                    }
                    if (!_containsOnlyLetters(text)) {
                      return 'Role must contain letters only';
                    }
                    if (text.length < 2) {
                      return 'Role is too short';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    _submit();
                  },
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _purple.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Team Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}