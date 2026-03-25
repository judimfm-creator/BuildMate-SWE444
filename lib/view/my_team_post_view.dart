import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'other_user_profile_page.dart';

class MyTeamPostView extends StatelessWidget {
  final String teamPostId;
  final String hackathonId;
  final int hackathonTeamSize;

  const MyTeamPostView({
    super.key,
    required this.teamPostId,
    required this.hackathonId,
    required this.hackathonTeamSize,
  });

  static const Color purple = Color(0xFF6D56B3);
  static const Color lightPurple = Color(0xFFF0EEFF);

  Future<List<Map<String, String>>> _getMemberDetails(
      List<dynamic> memberIds,
      String leaderId,
      String leaderRole,
      Map<String, dynamic> memberRoles,
      ) async {
    List<Map<String, String>> members = [];

    for (var id in memberIds) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();

      String displayRole =
      (id == leaderId) ? leaderRole : (memberRoles[id] ?? "Member");

      members.add({
        'uid': id.toString(),
        'name': doc.data()?['fullName'] ?? 'Unknown Member',
        'isLeader': (id == leaderId).toString(),
        'role': displayRole.toString(),
      });
    }

    return members;
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Team Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: purple,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .snapshots(),
        builder: (context, streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: purple),
            );
          }
          if (!streamSnapshot.hasData || !streamSnapshot.data!.exists) {
            return const Center(child: Text('Team post not found.'));
          }

          final data = streamSnapshot.data!.data() ?? {};
          final List<dynamic> memberIds = data['members'] ?? [];
          final int currentMembers = memberIds.length;
          final String leaderId = data['createdBy'] ?? '';
          final bool isLeader = currentUserId == leaderId;
          final bool isSubmitted = data['submittedToInstitution'] == true;
          final Map<String, dynamic> memberRoles = data['memberRoles'] ?? {};
          final String leaderRole = data['myRole'] ?? 'Leader';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(isSubmitted, currentMembers),
                const SizedBox(height: 24),

                _sectionTitle("Team Overview"),
                _infoBox([
                  _dataRow("Team Name", data['teamName'] ?? 'Unnamed'),
                  _dataRow(
                    "Team Capacity",
                    "$currentMembers / $hackathonTeamSize members",
                  ),
                  const Divider(height: 20),
                  _genderPreferenceRow(data['genderPreference'] ?? 'Any'),
                ]),

                const SizedBox(height: 24),

                _sectionTitle("Project Idea"),
                _infoBox([
                  Text(
                    data['projectIdea'] != null &&
                        data['projectIdea'].toString().isNotEmpty
                        ? data['projectIdea']
                        : "No project idea added yet.",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                _sectionTitle("Current Members & Roles"),
                FutureBuilder<List<Map<String, String>>>(
                  future: _getMemberDetails(
                    memberIds,
                    leaderId,
                    leaderRole,
                    memberRoles,
                  ),
                  builder: (context, nameSnapshot) {
                    if (!nameSnapshot.hasData) {
                      return const Center(
                        child: LinearProgressIndicator(color: purple),
                      );
                    }

                    return Column(
                      children: nameSnapshot.data!
                          .map(
                            (member) => _memberTile(
                          context: context,
                          uid: member['uid']!,
                          name: member['name']!,
                          isLeader: member['isLeader'] == 'true',
                          role: member['role']!,
                        ),
                      )
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),

                if (isLeader) ...[
                  _actionButton(
                    label: 'View Join Requests',
                    icon: Icons.group_add_outlined,
                    color: Colors.grey.shade300,
                    onPressed: null,
                  ),
                  const SizedBox(height: 12),
                  _actionButton(
                    label: isSubmitted
                        ? 'Registration Submitted'
                        : 'Finalize & Register Team',
                    icon: isSubmitted
                        ? Icons.verified_user
                        : Icons.rocket_launch,
                    color: isSubmitted
                        ? Colors.grey
                        : (currentMembers >= 2
                        ? Colors.green
                        : Colors.grey.shade400),
                    onPressed: (!isSubmitted && currentMembers >= 2)
                        ? () => _handleRegistration(context, currentMembers)
                        : null,
                  ),
                  if (!isSubmitted && currentMembers < 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Registration opens when you have at least 2 members.",
                            style: TextStyle(
                              color: Color(0xFFD35400),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  _buildMemberNotice(isSubmitted, currentMembers),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _memberTile({
    required BuildContext context,
    required String uid,
    required String name,
    required bool isLeader,
    required String role,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserProfilePage(userId: uid),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: lightPurple,
              radius: 18,
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(
                  color: purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isLeader)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: purple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Leader",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: purple.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberNotice(bool isSubmitted, int currentMembers) {
    String noticeText;
    IconData icon = Icons.info_outline;
    Color color = purple;

    if (isSubmitted) {
      noticeText = "Success! Your team is registered.";
      color = Colors.green;
      icon = Icons.verified;
    } else if (currentMembers >= hackathonTeamSize) {
      noticeText =
      "Team is full! We're just waiting for the leader to finalize registration.";
      color = Colors.orange.shade800;
      icon = Icons.pending_actions;
    } else {
      noticeText =
      "Welcome to the team! We are currently looking for more teammates to join the fun.";
      icon = Icons.celebration_outlined;
      color = purple;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              noticeText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(bool isSubmitted, int currentMembers) {
    String statusText = isSubmitted
        ? "Status: Registered & Locked"
        : (currentMembers >= hackathonTeamSize
        ? "Status: Team is Full"
        : "Status: Building Team");

    Color statusColor = isSubmitted
        ? Colors.green
        : (currentMembers >= hackathonTeamSize
        ? Colors.orange.shade800
        : purple);

    IconData icon = isSubmitted
        ? Icons.lock_outline
        : (currentMembers >= hackathonTeamSize
        ? Icons.stars_outlined
        : Icons.groups_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );

  Widget _dataRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: purple,
          ),
        ),
      ],
    ),
  );

  Widget _genderPreferenceRow(String pref) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        "Teammate Gender",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          fontSize: 13,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          pref,
          style: const TextStyle(
            color: purple,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );

  Widget _actionButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    Color? color,
  }) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? purple,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
    ),
  );

  Future<void> _handleRegistration(BuildContext context, int currentMembers) async {
    bool? confirm = await _showConfirmDialog(context, currentMembers);
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('team_posts').doc(teamPostId).update({
        'submittedToInstitution': true,
        'status': 'pending_approval',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Team successfully registered!")),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Registration"),
        content: Text(
          "You have $count members. Once finalized, your team will be sent for review. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: purple),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Finalize"),
          ),
        ],
      ),
    );
  }
}