import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/buildmate_app_bar.dart';

class TeamRegistrationFormView extends StatefulWidget {
  final String hackathonId;
  final String teamPostId;
  final String teamName;
  final List<String> members;
  final int hackathonTeamSize;

  const TeamRegistrationFormView({
    super.key,
    required this.hackathonId,
    required this.teamPostId,
    required this.teamName,
    required this.members,
    required this.hackathonTeamSize,
  });

  @override
  State<TeamRegistrationFormView> createState() =>
      _TeamRegistrationFormViewState();
}

class _TeamRegistrationFormViewState
    extends State<TeamRegistrationFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _ideaNameController =
  TextEditingController();
  final TextEditingController _briefDescriptionController =
  TextEditingController();

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBackground = Color(0xFFFAFAFA);
  static const Color _borderColor = Color(0xFFE6E1F3);

  bool _isLoading = false;
  bool _submittedOnce = false;

  final RegExp _allowedChars =
  RegExp(r'^[a-zA-Z0-9\u0600-\u06FF\s]+$');

  @override
  void dispose() {
    _ideaNameController.dispose();
    _briefDescriptionController.dispose();
    super.dispose();
  }

  DateTime? _parseFirestoreDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  Future<void> _submitRegistrationForm() async {
    if (_isLoading) return;

    setState(() {
      _submittedOnce = true;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final firestore = FirebaseFirestore.instance;

      final hackathonRef =
      firestore.collection('hackathons').doc(widget.hackathonId);

      final teamPostRef =
      firestore.collection('team_posts').doc(widget.teamPostId);

      final hackathonDoc = await hackathonRef.get();

      if (!hackathonDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This hackathon is no longer available'),
            backgroundColor: Colors.red,
          ),
        );

        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final hackathonData = hackathonDoc.data() ?? {};

      final DateTime? openDate =
      _parseFirestoreDate(hackathonData['applicationOpenDate']);
      final DateTime? deadline =
      _parseFirestoreDate(hackathonData['applicationDeadline']);

      final now = DateTime.now();

      if (openDate != null && now.isBefore(openDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration has not opened yet'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final DateTime? effectiveDeadline = deadline != null
          ? DateTime(
        deadline.year,
        deadline.month,
        deadline.day,
        23,
        59,
        59,
      )
          : null;

      if (effectiveDeadline != null && now.isAfter(effectiveDeadline)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration is closed'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }


      final teamDoc = await teamPostRef.get();

      if (!teamDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team post no longer exists'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final teamData = teamDoc.data() ?? {};

      final leaderId = teamData['createdBy'];
      final members =
      List<String>.from(teamData['members'] ?? widget.members);

      if (leaderId != currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only leader can register'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (members.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Need at least 2 members'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await firestore.collection('registrations').add({
        'hackathonId': widget.hackathonId,
        'teamPostId': widget.teamPostId,
        'leaderId': currentUser.uid,
        'teamName': widget.teamName,
        'members': members,
        'membersCount': members.length,
        'ideaName': _ideaNameController.text.trim(),
        'briefDescription':
        _briefDescriptionController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      await teamPostRef.update({
        'submittedToInstitution': true,
        'status': 'pending_approval',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String helper,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon, color: _purple),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
        const BorderSide(color: _purple, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: 'Team Registration',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Team Registration Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lightBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text("Team Name: "),
                        Text(widget.teamName),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("Members: "),
                        Text(widget.members.length.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Hackathon Registration Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ideaNameController,
                maxLength: 20,
                decoration: _inputDecoration(
                  label: "Idea Name",
                  helper: "3–20 characters",
                  icon: Icons.lightbulb_outline,
                ),
                validator: (value) {
                  if (!_submittedOnce) return null;

                  final text = value?.trim() ?? '';

                  if (text.isEmpty) return 'Required';

                  if (text.length < 3) {
                    return 'Min 3 characters';
                  }

                  if (!RegExp(r'[a-zA-Z\u0600-\u06FF]')
                      .hasMatch(text)) {
                    return 'Must include letters';
                  }

                  if (!_allowedChars.hasMatch(text)) {
                    return 'Invalid characters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _briefDescriptionController,
                maxLines: 4,
                maxLength: 120,
                decoration: _inputDecoration(
                  label: "Brief Description",
                  helper: "20–120 characters",
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (!_submittedOnce) return null;

                  final text = value?.trim() ?? '';

                  if (text.isEmpty) return 'Required';

                  if (text.length < 20) {
                    return 'Min 20 characters';
                  }

                  if (!RegExp(r'[a-zA-Z\u0600-\u06FF]')
                      .hasMatch(text)) {
                    return 'Must include letters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                  _isLoading ? null : _submitRegistrationForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    "Submit Registration",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}