import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeamRegistrationFormView extends StatefulWidget {
  final String hackathonId;
  final String teamPostId;
  final String teamName;
  final List<String> members;

  const TeamRegistrationFormView({
    super.key,
    required this.hackathonId,
    required this.teamPostId,
    required this.teamName,
    required this.members,
  });

  @override
  State<TeamRegistrationFormView> createState() =>
      _TeamRegistrationFormViewState();
}

class _TeamRegistrationFormViewState extends State<TeamRegistrationFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _ideaNameController = TextEditingController();
  final TextEditingController _briefDescriptionController =
      TextEditingController();

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBackground = Color(0xFFF8F7FB);
  static const Color _borderColor = Color(0xFFE6E1F3);

  final RegExp _lettersOnlyRegex = RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$');

  bool _isLoading = false;

  bool _containsOnlyLetters(String value) {
    return _lettersOnlyRegex.hasMatch(value.trim());
  }

  @override
  void dispose() {
    _ideaNameController.dispose();
    _briefDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistrationForm() async {
    if (_isLoading) return;

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
      final teamPostRef =
          firestore.collection('team_posts').doc(widget.teamPostId);

      final teamPostDoc = await teamPostRef.get();

      if (!teamPostDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team post not found.')),
        );
        return;
      }

      final teamData = teamPostDoc.data() ?? {};

      final String leaderId = (teamData['leaderId'] ?? '').toString();
      final bool submittedToInstitution =
          teamData['submittedToInstitution'] == true;

      final List<String> storedMembers = _parseStringList(teamData['members']);
      final int currentMembers = _parseInt(teamData['currentMembers']);
      final int maxMembers = _parseInt(teamData['maxMembers']);

      final int actualMembersCount =
          currentMembers > 0 ? currentMembers : storedMembers.length;

      if (leaderId.isEmpty || leaderId != currentUser.uid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only the team leader can register the team.'),
          ),
        );
        return;
      }

      if (submittedToInstitution) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('This team has already been registered for the hackathon.'),
          ),
        );
        return;
      }

      if (maxMembers <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid team size. Please contact support.'),
          ),
        );
        return;
      }

      if (actualMembersCount < maxMembers) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can register the team only after it becomes complete ($actualMembersCount / $maxMembers).',
            ),
          ),
        );
        return;
      }

      final existingRegistration = await firestore
          .collection('registrations')
          .where('teamPostId', isEqualTo: widget.teamPostId)
          .limit(1)
          .get();

      if (existingRegistration.docs.isNotEmpty) {
        await teamPostRef.update({
          'isTeamComplete': true,
          'submittedToInstitution': true,
          'status': 'submitted',
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This team has already been registered. Team status was updated.',
            ),
          ),
        );
        Navigator.pop(context);
        return;
      }

      await firestore.collection('registrations').add({
        'hackathonId': widget.hackathonId,
        'teamPostId': widget.teamPostId,
        'leaderId': currentUser.uid,
        'teamName': widget.teamName,
        'members': storedMembers.isNotEmpty ? storedMembers : widget.members,
        'membersCount': storedMembers.isNotEmpty
            ? storedMembers.length
            : widget.members.length,
        'ideaName': _ideaNameController.text.trim(),
        'briefDescription': _briefDescriptionController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      await teamPostRef.update({
        'isTeamComplete': true,
        'submittedToInstitution': true,
        'status': 'submitted',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team registered for hackathon successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register team: $e'),
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

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final int membersCount = widget.members.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Team for Hackathon'),
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
                'Team Registration Summary',
                'Register your complete team for this hackathon. Only the team leader can submit this form.',
              ),
              _buildSectionCard([
                _infoRow('Team Name', widget.teamName),
                const SizedBox(height: 10),
                _infoRow('Members Count', membersCount.toString()),
              ]),
              const SizedBox(height: 24),
              _sectionTitle(
                'Hackathon Registration Details',
                'Provide the idea information required before sending the team to the institution.',
              ),
              _buildSectionCard([
                TextFormField(
                  controller: _ideaNameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Idea Name',
                    'Letters only.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Idea name is required';
                    }

                    if (text.length < 3) {
                      return 'Idea name must be at least 3 characters';
                    }

                    if (!_containsOnlyLetters(text)) {
                      return 'Idea name must contain letters only';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _briefDescriptionController,
                  maxLines: 5,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    'Brief Description',
                    'Letters only. Minimum 20 characters.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Brief description is required';
                    }

                    if (text.length < 20) {
                      return 'Brief description must be at least 20 characters';
                    }

                    if (!_containsOnlyLetters(text)) {
                      return 'Brief description must contain letters only';
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
                  onPressed: _isLoading ? null : _submitRegistrationForm,
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
                      : const Text('Register Team for Hackathon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}