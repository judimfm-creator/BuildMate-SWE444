import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateTeamPostScreen extends StatefulWidget {
  final String hackathonId;

  const CreateTeamPostScreen({
    super.key,
    required this.hackathonId,
  });

  @override
  State<CreateTeamPostScreen> createState() => _CreateTeamPostScreenState();
}

class _CreateTeamPostScreenState extends State<CreateTeamPostScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;

  final RegExp _lettersOnlyRegex = RegExp(r'^[A-Za-z ]+$');
  final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _teamNameController.dispose();
    _roleController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _skillsController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  bool _containsOnlyLetters(String value) {
    return _lettersOnlyRegex.hasMatch(value.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not logged in')),
        );
        return;
      }

      final teamPostRef =
          await FirebaseFirestore.instance.collection('team_posts').add({
        'hackathonId': widget.hackathonId,
        'createdBy': user.uid,
        'teamName': _teamNameController.text.trim(),
        'genderPreference': _selectedGender,
        'myRole': _roleController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('registrations').add({
        'hackathonId': widget.hackathonId,
        'teamPostId': teamPostRef.id,
        'userId': user.uid,
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'university': _universityController.text.trim(),
        'major': _majorController.text.trim(),
        'skills': _skillsController.text.trim(),
        'motivation': _motivationController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Team post created and registration form submitted successfully',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      errorMaxLines: 2,
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E1F3)),
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
      ),
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
                'This section creates the team post for the selected hackathon.',
              ),
              _buildSectionCard([
                TextFormField(
                  controller: _teamNameController,
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
                    if (text
                        .split(RegExp(r'\s+'))
                        .where((e) => e.isNotEmpty)
                        .isEmpty) {
                      return 'Enter at least one word';
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
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roleController,
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
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 24),

              _sectionTitle(
                'Registration Form',
                'This information will be visible to the institution for evaluation.',
              ),
              _buildSectionCard([
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecoration(
                    'Full Name',
                    'Letters only, at least one word.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Full name is required';
                    }
                    if (!_containsOnlyLetters(text)) {
                      return 'Full name must contain letters only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    'Email',
                    'Must be a valid email format, for example: name@example.com',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Email is required';
                    }
                    if (!_emailRegex.hasMatch(text)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _universityController,
                  decoration: _inputDecoration(
                    'University',
                    'Required field.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'University is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _majorController,
                  decoration: _inputDecoration(
                    'Major',
                    'Required field.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Major is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _skillsController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    'Skills',
                    'Minimum 30 characters.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Skills are required';
                    }
                    if (text.length < 30) {
                      return 'Skills must be at least 30 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _motivationController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    'Motivation',
                    'Minimum 30 characters.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Motivation is required';
                    }
                    if (text.length < 30) {
                      return 'Motivation must be at least 30 characters';
                    }
                    return null;
                  },
                ),
              ]),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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