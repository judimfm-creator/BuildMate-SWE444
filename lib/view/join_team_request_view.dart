import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinTeamRequestView extends StatefulWidget {
  final String hackathonId;
  final String teamPostId;
  final String leaderId;
  final String teamName;

  const JoinTeamRequestView({
    super.key,
    required this.hackathonId,
    required this.teamPostId,
    required this.leaderId,
    required this.teamName,
  });

  @override
  State<JoinTeamRequestView> createState() => _JoinTeamRequestViewState();
}

class _JoinTeamRequestViewState extends State<JoinTeamRequestView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _desiredRoleController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBackground = Color(0xFFF8F7FB);
  static const Color _borderColor = Color(0xFFE6E1F3);

  bool _isLoading = false;

  final RegExp _lettersOnlyRegex = RegExp(r'^[A-Za-z ]+$');
  final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _skillsController.dispose();
    _desiredRoleController.dispose();
    _motivationController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  bool _containsOnlyLetters(String value) {
    return _lettersOnlyRegex.hasMatch(value.trim());
  }

  Future<void> _submitJoinRequest() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not logged in.')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final firestore = FirebaseFirestore.instance;

      final teamDoc = await firestore
          .collection('team_posts')
          .doc(widget.teamPostId)
          .get();

      if (!teamDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team post not found.')),
        );
        return;
      }

      final teamData = teamDoc.data() ?? {};
      final List<String> members = _parseStringList(teamData['members']);
      final int currentMembers = _parseInt(teamData['currentMembers']);
      final int maxMembers = _parseInt(teamData['maxMembers']);
      final bool submittedToInstitution =
          teamData['submittedToInstitution'] == true;

      if (currentUser.uid == widget.leaderId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot send a join request to your own team.'),
          ),
        );
        return;
      }

      if (members.contains(currentUser.uid)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already a member of this team.'),
          ),
        );
        return;
      }

      if (submittedToInstitution) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This team has already been submitted to the institution.',
            ),
          ),
        );
        return;
      }

      if (maxMembers > 0 && currentMembers >= maxMembers) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This team is already full.'),
          ),
        );
        return;
      }

      final existingRequest = await firestore
          .collection('join_requests')
          .where('teamPostId', isEqualTo: widget.teamPostId)
          .where('requesterId', isEqualTo: currentUser.uid)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You have already submitted a join request for this team.',
            ),
          ),
        );
        return;
      }

      await firestore.collection('join_requests').add({
        'hackathonId': widget.hackathonId,
        'teamPostId': widget.teamPostId,
        'leaderId': widget.leaderId,
        'requesterId': currentUser.uid,
        'teamName': widget.teamName,
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'university': _universityController.text.trim(),
        'major': _majorController.text.trim(),
        'skills': _skillsController.text.trim(),
        'desiredRole': _desiredRoleController.text.trim(),
        'motivation': _motivationController.text.trim(),
        'portfolioLink': _portfolioController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request submitted successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit join request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
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
        title: const Text('Request to Join'),
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
                'Join Team Request',
                'Fill in your information to request joining ${widget.teamName}.',
              ),
              _buildSectionCard([
                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Skills',
                    'Minimum 20 characters.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Skills are required';
                    }
                    if (text.length < 20) {
                      return 'Skills must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _desiredRoleController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Desired Role',
                    'Enter the role you want in this team.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Desired role is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _motivationController,
                  maxLines: 4,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Why do you want to join this team?',
                    'Minimum 20 characters.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Motivation is required';
                    }
                    if (text.length < 20) {
                      return 'Motivation must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _portfolioController,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    'Portfolio Link (Optional)',
                    'GitHub, LinkedIn, portfolio, or any useful link.',
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitJoinRequest,
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Join Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}