import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'other_user_profile_page.dart';

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
                        "Team Members",
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
                        (uid) => _buildMemberCard(context, uid),
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

  Widget _buildMemberCard(BuildContext context, String uid) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
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
        final ImageProvider? profileImage = _resolveProfileImage(u);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _lightPurple,
                backgroundImage: profileImage,
                child: profileImage == null
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      username.isNotEmpty ? "@$username" : "@username",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _purple.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _purple, width: 1.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtherUserProfilePage(userId: uid),
                      ),
                    );
                  },
                  child: const Text(
                    "View Profile",
                    style: TextStyle(
                      color: _purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
      final c = status == 'accepted' ? Colors.green : Colors.red;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "APPLICATION ${status.toUpperCase()}",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: c,
          ),
        ),
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
        child: Row(
          children: const [
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