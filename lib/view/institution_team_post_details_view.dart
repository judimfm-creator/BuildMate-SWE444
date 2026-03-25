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
          'Team Registration',
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

          final String teamName =
              (data['teamName'] ?? 'Unnamed Team').toString();

          final String ideaName =
              (data['ideaName'] ??
                      data['projectIdea'] ??
                      data['idea'] ??
                      'N/A')
                  .toString();

          final String description =
              (data['description'] ??
                      data['ideaDescription'] ??
                      data['projectDescription'] ??
                      'N/A')
                  .toString();

          final String status = (data['status'] ?? 'pending').toString();

          final List<dynamic> memberIdsDynamic =
              (data['members'] as List?) ??
              (data['memberIds'] as List?) ??
              [];

          final List<String> memberIds =
              memberIdsDynamic.map((e) => e.toString()).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _purple,
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Column(
                      children: [
                        _boxedInfoRow(
                          label: 'Idea Name:',
                          value: ideaName,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _boxedInfoRow(
                          label: 'Description:',
                          value: description,
                          maxLines: 6,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),
                  const Divider(height: 1),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Text(
                      'Team Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _purple,
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  if (memberIds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No team members found.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  else
                    ...memberIds.map(
                      (id) => _buildMemberRow(context, id),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    child: _buildDecisionButtons(
                      context,
                      status,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _boxedInfoRow({
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment:
          maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 95,
          child: Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _purple,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              value,
              maxLines: maxLines,
              overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberRow(BuildContext context, String uid) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: LinearProgressIndicator(),
          );
        }

        if (!userSnap.hasData || !userSnap.data!.exists) {
          return const SizedBox.shrink();
        }

        final u = userSnap.data!.data() ?? {};

        final String fullName = (u['fullName'] ?? 'Unknown User').toString();
        final String role =
            (u['role'] ?? u['myRole'] ?? u['desiredRole'] ?? 'Member')
                .toString();

        final String? photoUrl =
            (u['profilePhotoPath'] ?? u['profileImage'] ?? u['photoUrl'])
                ?.toString();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE9EDF2)),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _lightPurple,
                backgroundImage: (photoUrl != null &&
                        photoUrl.isNotEmpty &&
                        (photoUrl.startsWith('http://') ||
                            photoUrl.startsWith('https://')))
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null ||
                        photoUrl.isEmpty ||
                        (!photoUrl.startsWith('http://') &&
                            !photoUrl.startsWith('https://')))
                    ? Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: _purple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: " - $role",
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtherUserProfilePage(
                        userId: uid,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View Profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDecisionButtons(
    BuildContext context,
    String status,
  ) {
    if (status == 'accepted' || status == 'rejected') {
      final Color c = status == 'accepted' ? Colors.green : Colors.red;

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

    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            "Accept Team",
            Colors.green,
            () => _updateStatus(context, 'accepted'),
          ),
        ),
        const SizedBox(width: 14),
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
        SnackBar(content: Text("Team status updated: $newStatus")),
      );
    }
  }

  Widget _actionBtn(String label, Color color, VoidCallback? onPressed) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}