import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'other_user_profile_page.dart';
import 'team_registration_form_view.dart';
import 'leader_join_requests_view.dart';

class MyTeamPostView extends StatelessWidget {
  // 👇 هنا مكانها الصحيح
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
      var doc =
          await FirebaseFirestore.instance.collection('users').doc(id).get();

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

  Stream<int> _pendingRequestsCountStream() {
    return FirebaseFirestore.instance
        .collection('join_requests')
        .where('teamPostId', isEqualTo: teamPostId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _deleteTeamPost(BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final teamRef = firestore.collection('team_posts').doc(teamPostId);
      final teamDoc = await teamRef.get();

      if (!teamDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team post not found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = teamDoc.data() ?? {};
      final bool isSubmitted = data['submittedToInstitution'] == true;

      if (isSubmitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot delete a team after registration.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final batch = firestore.batch();

      final joinRequests = await firestore
          .collection('join_requests')
          .where('teamPostId', isEqualTo: teamPostId)
          .get();

      for (final doc in joinRequests.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(teamRef);

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting team: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text(
          'Are you sure you want to delete this team before registration?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.deepOrange.shade400),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteTeamPost(context);
    }
  }

  Future<void> _editTeamInfo(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final nameCtrl = TextEditingController(text: data['teamName'] ?? '');
    final roleCtrl = TextEditingController(text: data['myRole'] ?? '');
    String selectedGender = data['genderPreference'] ?? 'Any';
    const genderOptions = ['Any', 'Male', 'Female', 'Mixed'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Team Info',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Team Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: 'Teammate Gender'),
                items: genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setS(() => selectedGender = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Your Role'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: purple),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .update({
          'teamName': nameCtrl.text.trim(),
          'genderPreference': selectedGender,
          'myRole': roleCtrl.text.trim(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team info updated.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
    nameCtrl.dispose();
    roleCtrl.dispose();
  }
Future<void> _removeMember(
    BuildContext context,
    String memberId,
    String memberName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        // 🔴 غيرنا الرسالة لتكون أوضح
        content: Text('Are you sure you want to remove $memberName? They will be moved to the archive and can no longer participate in new chats.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final teamRef = FirebaseFirestore.instance.collection('team_posts').doc(teamPostId);
        final userRef = FirebaseFirestore.instance.collection('users').doc(memberId);

        // 1️⃣ تحديث بيانات الفريق
        batch.update(teamRef, {
          'members': FieldValue.arrayRemove([memberId]), // حذفه من النشطين
          'removedMembers': FieldValue.arrayUnion([memberId]), // 🔴 إضافته للأرشيف (المطرودين)
          'memberRoles.$memberId': FieldValue.delete(), // حذف دوره
        });

        // 2️⃣ تحديث بيانات المستخدم (تحريره)
        batch.update(userRef, {
          'hasActiveTeam': false,
          'currentTeamId': null,
        });

        // تنفيذ كل العمليات مرة واحدة (Batch) لضمان الدقة
        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Member moved to archive successfully.'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _leaveTeam(BuildContext context) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text('Are you sure you want to leave this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .update({
          'members': FieldValue.arrayRemove([uid]),
          'memberRoles.$uid': FieldValue.delete(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You have left the team.'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('hackathons')
                .doc(hackathonId)
                .get(),
            builder: (context, hackathonSnapshot) {
              if (hackathonSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: purple),
                );
              }

              final hackathonData = hackathonSnapshot.data?.data() ?? {};

              final DateTime? openDate =
                  _parseFirestoreDate(hackathonData['applicationOpenDate']);
              final DateTime? deadline =
                  _parseFirestoreDate(hackathonData['applicationDeadline']);

              final now = DateTime.now();

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

              final bool isRegistrationOpen = openDate != null &&
                  effectiveDeadline != null &&
                  !now.isBefore(openDate) &&
                  !now.isAfter(effectiveDeadline);

              final bool canFinalize =
                  !isSubmitted && currentMembers >= 2 && isRegistrationOpen;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(
                        isSubmitted, currentMembers, data['status']),
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
                        (data['projectIdea'] != null &&
                                data['projectIdea']
                                    .toString()
                                    .trim()
                                    .isNotEmpty)
                            ? data['projectIdea']
                            : (data['idea'] != null &&
                                    data['idea'].toString().trim().isNotEmpty)
                                ? data['idea']
                                : "No project idea added yet.",
                        style: const TextStyle(
                          color: purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                                  onRemove: (isLeader &&
                                          !isSubmitted &&
                                          member['isLeader'] != 'true')
                                      ? () => _removeMember(
                                            context,
                                            member['uid']!,
                                            member['name']!,
                                          )
                                      : null,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    if (isLeader) ...[
                      if (!isSubmitted && currentMembers < 2)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_clock_outlined,
                                size: 18,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                 "Registration is locked. You need at least 2 members to finalize.",
                                  style: TextStyle(
                                    color: Color(0xFFD35400),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isSubmitted) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                label: 'Edit Team Info',
                                icon: Icons.edit_outlined,
                                color: purple,
                                onPressed: () => _editTeamInfo(context, data),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StreamBuilder<int>(
                                stream: _pendingRequestsCountStream(),
                                builder: (context, snapshot) {
                                  final int count = snapshot.data ?? 0;
                                  return _actionButton(
                                    label: 'Join Requests',
                                    icon: Icons.group_add_outlined,
                                    color: purple,
                                    badgeCount: count,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LeaderJoinRequestsView(
                                            teamPostId: teamPostId,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        StreamBuilder<int>(
                          stream: _pendingRequestsCountStream(),
                          builder: (context, snapshot) {
                            final int count = snapshot.data ?? 0;
                            return _actionButton(
                              label: 'View Join Requests',
                              icon: Icons.group_add_outlined,
                              color: purple,
                              badgeCount: count,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LeaderJoinRequestsView(
                                      teamPostId: teamPostId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      _actionButton(
                        label: isSubmitted
                            ? 'Registration Submitted'
                            : (isRegistrationOpen
                                ? 'Finalize & Register Team'
                                : 'Registration Closed'),
                        icon: isSubmitted
                            ? Icons.verified_user
                            : Icons.rocket_launch,
                        color: isSubmitted
                            ? Colors.grey
                            : (canFinalize
                                ? const Color(0xFF6D56B3)
                                : Colors.grey.shade400),
                        onPressed: canFinalize
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeamRegistrationFormView(
                                      hackathonId: hackathonId,
                                      teamPostId: teamPostId,
                                      teamName:
                                          data['teamName'] ?? 'Unnamed Team',
                                      members: List<String>.from(memberIds),
                                      hackathonTeamSize: hackathonTeamSize,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                      if (!isSubmitted) ...[
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade200, height: 1),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepOrange.shade400,
                              side: BorderSide(color: Colors.deepOrange.shade300, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showDeleteConfirmation(context),
                            icon: Icon(Icons.delete_outline, size: 18, color: Colors.deepOrange.shade400),
                            label: Text('Delete Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepOrange.shade400)),
                          ),
                        ),
                      ],
                      if (!isSubmitted)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 12, left: 4, right: 4),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.tips_and_updates_outlined,
                                  color: Colors.amber.shade900,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Pro tip: Make sure all members have completed their profiles before registering. Incomplete profiles may affect your acceptance.",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      _buildMemberNotice(isSubmitted, currentMembers),
                      if (!isSubmitted) ...[
                        const SizedBox(height: 12),
                        _actionButton(
                          label: 'Leave Team',
                          icon: Icons.exit_to_app_rounded,
                          color: Colors.red,
                          onPressed: () => _leaveTeam(context),
                        ),
                      ],
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
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
    VoidCallback? onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OtherUserProfilePage(userId: uid)),
            ),
            child: CircleAvatar(
              backgroundColor: lightPurple,
              radius: 18,
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style:
                    const TextStyle(color: purple, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OtherUserProfilePage(userId: uid)),
              ),
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
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isLeader)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: purple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Leader",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
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
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 20),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
        ],
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
          "Welcome to the team! We are currently looking for more teammates.";
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

  Widget _buildStatusHeader(
    bool isSubmitted,
    int currentMembers,
    String? adminStatus,
  ) {
    String statusText;
    Color statusColor;
    IconData icon;

    if (isSubmitted) {
      switch (adminStatus) {
        case 'accepted':
          statusText = "Status: Team Accepted! 🎉";
          statusColor = Colors.green;
          icon = Icons.check_circle_outline;
          break;
        case 'rejected':
          statusText = "Status: Team Rejected";
          statusColor = Colors.red;
          icon = Icons.error_outline;
          break;
        default:
          statusText = "Status: Registered & Under Review";
          statusColor = Colors.blue;
          icon = Icons.hourglass_empty_rounded;
      }
    } else {
      if (currentMembers >= hackathonTeamSize) {
        statusText = "Status: Team Full (Ready to Register)";
        statusColor = Colors.orange.shade800;
        icon = Icons.stars_outlined;
      } else {
        statusText = "Status: Building Team...";
        statusColor = purple;
        icon = Icons.groups_outlined;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _infoBox(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: purple,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderPreferenceRow(String gender) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Teammate Gender",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: lightPurple,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            gender,
            style: const TextStyle(
              color: purple,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    int badgeCount = 0,
  }) {
    final bool disabled = onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: disabled ? color : color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: color,
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 24),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
