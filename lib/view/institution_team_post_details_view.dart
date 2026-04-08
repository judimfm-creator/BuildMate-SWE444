import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InstitutionTeamPostDetailsView extends StatelessWidget {
  final String teamPostId;

  const InstitutionTeamPostDetailsView({
    super.key,
    required this.teamPostId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);
  static const Color _pageBg = Color(0xFFF8F9FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          'Review Team Members',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0.5,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Data not found.'),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final List<dynamic> memberIdsDynamic =
              (data['members'] as List?) ?? (data['memberIds'] as List?) ?? [];
          final List<String> memberIds =
              memberIdsDynamic.map((e) => e.toString()).toList();

          final String status = (data['status'] ?? 'pending').toString();
          final String hackathonId = (data['hackathonId'] ?? '').toString();
          final String leaderId = (data['createdBy'] ?? '').toString();

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('hackathons')
                .doc(hackathonId)
                .get(),
            builder: (context, hackSnap) {
              bool isDeadlinePassed = false;

              if (hackSnap.hasData && hackSnap.data!.exists) {
                final hackData = hackSnap.data!.data();
                final dynamic deadlineRaw = hackData?['applicationDeadline'];

                DateTime? deadlineDate;

                if (deadlineRaw is Timestamp) {
                  deadlineDate = deadlineRaw.toDate();
                } else if (deadlineRaw is String) {
                  deadlineDate = DateTime.tryParse(deadlineRaw);
                } else if (deadlineRaw is DateTime) {
                  deadlineDate = deadlineRaw;
                }

                if (deadlineDate != null) {
                  isDeadlinePassed = DateTime.now().isAfter(deadlineDate);
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _lightPurple,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "Team Members Details",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _purple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (memberIds.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "No members found.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    else
                      ...memberIds.map(
                        (uid) => _buildMemberCard(context, uid, leaderId),
                      ),

                    const SizedBox(height: 24),

                    _buildDecisionSection(
                      context,
                      status,
                      isDeadlinePassed,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, String uid, String leaderId) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const LinearProgressIndicator(
              color: _purple,
            ),
          );
        }

        if (!userSnap.hasData || !userSnap.data!.exists) {
          return const SizedBox.shrink();
        }

        final u = userSnap.data!.data() ?? {};

        final String fullName = (u['fullName'] ?? 'User').toString();
        final String username = (u['username'] ?? '').toString();
        final String email = (u['email'] ?? '').toString();
        final String phone = (u['phoneNumber'] ?? '').toString();
        final String city = (u['city'] ?? '').toString();
        final String gender = (u['gender'] ?? '').toString();
        final String linkedin = (u['linkedin'] ?? '').toString();
        final String github = (u['github'] ?? '').toString();

        String skillsText = '';
        final dynamic skills = u['skills'];
        if (skills is List) {
          skillsText = skills.map((e) => e.toString()).join(', ');
        } else if (skills != null) {
          skillsText = skills.toString();
        }

        final bool isLeader = uid == leaderId;
        final ImageProvider? profileImage = _resolveProfileImage(u);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _lightPurple,
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? Text(
                            fullName.isNotEmpty
                                ? fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: _purple,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              if (isLeader)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _purple,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Leader',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            username.isNotEmpty ? "@$username" : "@username",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 14),
              _infoRow(
                context,
                Icons.email_outlined,
                'Email',
                email,
                isEmail: true,
              ),
              _infoRow(
                context,
                Icons.phone_outlined,
                'Phone',
                phone,
                isPhone: true,
              ),
              _infoRow(
                context,
                Icons.location_city_outlined,
                'City',
                city,
              ),
              _infoRow(
                context,
                Icons.wc_outlined,
                'Gender',
                gender,
              ),
              _infoRow(
                context,
                Icons.psychology_outlined,
                'Skills',
                skillsText,
              ),
              _infoRow(
                context,
                Icons.link_outlined,
                'LinkedIn',
                linkedin,
                isLink: true,
              ),
              _infoRow(
                context,
                Icons.code_outlined,
                'GitHub',
                github,
                isLink: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    bool isEmail = false,
    bool isPhone = false,
  }) {
    final String cleanValue = value.trim();
    final bool isEmpty = cleanValue.isEmpty;
    final bool isClickable = !isEmpty && (isLink || isEmail || isPhone);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: isClickable
                      ? () async {
                          if (isLink) {
                            await _openLink(context, cleanValue);
                          } else if (isEmail) {
                            await _openEmail(context, cleanValue);
                          } else if (isPhone) {
                            await _openPhone(context, cleanValue);
                          }
                        }
                      : null,
                  child: Text(
                    isEmpty ? 'Unprovided' : cleanValue,
                    style: TextStyle(
                      color: isEmpty
                          ? Colors.grey.shade400
                          : (isClickable ? Colors.blue : Colors.black87),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      decoration: isClickable
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    String fixedUrl = url.trim();

    if (fixedUrl.isEmpty) return;

    if (!fixedUrl.startsWith('http://') &&
        !fixedUrl.startsWith('https://')) {
      fixedUrl = 'https://$fixedUrl';
    }

    final Uri uri = Uri.parse(fixedUrl);

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the link'),
        ),
      );
    }
  }

  Future<void> _openEmail(BuildContext context, String email) async {
    final String cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: cleanEmail,
    );

    final bool launched = await launchUrl(emailUri);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open email app'),
        ),
      );
    }
  }

  Future<void> _openPhone(BuildContext context, String phone) async {
    final String cleanPhone = phone.trim();
    if (cleanPhone.isEmpty) return;

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );

    final bool launched = await launchUrl(phoneUri);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open phone app'),
        ),
      );
    }
  }

  ImageProvider? _resolveProfileImage(Map<String, dynamic> userData) {
    final candidates = [
      userData['profilePhoto'],
      userData['profilePhotoPath'],
      userData['photoUrl'],
      userData['imageUrl'],
      userData['avatar'],
    ];

    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        final path = value.trim();

        if (path.startsWith('http')) {
          return NetworkImage(path);
        }

        final file = File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
    }
    return null;
  }

  Widget _buildDecisionSection(
    BuildContext context,
    String status,
    bool isDeadlinePassed,
  ) {
    if (status == 'accepted' || status == 'rejected') {
      final Color color = status == 'accepted' ? Colors.green : Colors.red;

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "APPLICATION ${status.toUpperCase()}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditDecisionDialog(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "Edit Decision",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    if (!isDeadlinePassed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.30)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              color: Colors.orange,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "View only until registration closes.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            "Accept Team",
            Colors.green,
            () => _updateStatus(context, 'accepted'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(
            "Reject Team",
            Colors.redAccent,
            () => _updateStatus(context, 'rejected'),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDecisionDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Edit Decision"),
        content: const Text("Choose the new status"),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, 'accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Accept"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, 'rejected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Reject"),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == null) return;

    await _updateStatus(context, result);
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('team_posts')
        .doc(teamPostId)
        .update({'status': newStatus});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Team status updated: $newStatus"),
        ),
      );
    }
  }

  Widget _actionBtn(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}