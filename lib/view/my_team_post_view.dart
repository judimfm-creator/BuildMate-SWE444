import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'other_user_profile_page.dart';
import 'team_registration_form_view.dart';
import 'leader_join_requests_view.dart';
import 'leader_vote_banner.dart';       // from file 1
import '../services/chat_service.dart'; // from file 1

class MyTeamPostView extends StatelessWidget {
  DateTime? _parseFirestoreDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
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
          (id == leaderId) ? leaderRole : (memberRoles[id] ?? 'Member');
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

  // ─────────────────────────────────────────────────────────────
  // DELETE TEAM
  // ─────────────────────────────────────────────────────────────

  Future<void> _deleteTeamPost(BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final teamRef = firestore.collection('team_posts').doc(teamPostId);
      final teamDoc = await teamRef.get();

      if (!teamDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Team post not found.'),
            backgroundColor: Colors.red));
        return;
      }

      final data = teamDoc.data() ?? {};
      if (data['submittedToInstitution'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You cannot delete a team after registration.'),
            backgroundColor: Colors.red));
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Team deleted successfully.'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting team: $e'),
              backgroundColor: Colors.red));
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text(
            'Are you sure you want to delete this team before registration?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: Colors.deepOrange.shade400)),
          ),
        ],
      ),
    );
    if (confirm == true) await _deleteTeamPost(context);
  }

  // ─────────────────────────────────────────────────────────────
  // EDIT TEAM INFO — from file 2 (full _EditTeamInfoDialog)
  // ─────────────────────────────────────────────────────────────

  Future<void> _editTeamInfo(
      BuildContext context, Map<String, dynamic> data) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _EditTeamInfoDialog(
        data: data,
        teamPostId: teamPostId,
        hackathonId: hackathonId,
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Team info updated successfully.'),
          backgroundColor: Colors.green));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REMOVE MEMBER
  // ─────────────────────────────────────────────────────────────

  Future<void> _removeMember(
      BuildContext context, String memberId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $memberName from the team?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .update({
          'members': FieldValue.arrayRemove([memberId]),
          'memberRoles.$memberId': FieldValue.delete(),
          'removedMembers': FieldValue.arrayUnion([memberId]),
          'removedAt.$memberId': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Member removed.'),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'),
                  backgroundColor: Colors.red));
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LEAVE TEAM — from file 1 (vote poll for leader)
  // Leader → initiates vote poll via ChatService
  // Regular member → original flow unchanged
  // ─────────────────────────────────────────────────────────────

  Future<void> _leaveTeam(BuildContext context) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final teamDoc = await FirebaseFirestore.instance
        .collection('team_posts')
        .doc(teamPostId)
        .get();
    if (!teamDoc.exists) return;

    final data = teamDoc.data()!;
    final String leaderId = data['createdBy'] ?? '';
    final List<String> members = List<String>.from(data['members'] ?? []);
    final bool isLeader = uid == leaderId;

    if (!context.mounted) return;

    if (isLeader) {
      final otherMembers = members.where((m) => m != uid).toList();

      if (otherMembers.isEmpty) {
        // Only member → dissolve team
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Leave Team'),
            content: const Text(
                'You are the only member. Leaving will dissolve the team. Continue?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Leave',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm != true) return;
        await _deleteTeamPost(context);
        return;
      }

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.how_to_vote_rounded, color: purple, size: 22),
              SizedBox(width: 10),
              Text('Leave Team', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: const Text(
            'Are you sure you want to leave this team?',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, leave the team'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await ChatService().initiateLeaderVote(
          teamPostId: teamPostId,
          leavingLeaderId: uid,
          eligibleVoters: otherMembers,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'),
                  backgroundColor: Colors.red));
        }
      }
    } else {
      // Regular member — original flow
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Leave Team'),
          content:
              const Text('Are you sure you want to leave this team?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirm != true) return;

      try {
        await FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .update({
          'members': FieldValue.arrayRemove([uid]),
          'memberRoles.$uid': FieldValue.delete(),
          'removedMembers': FieldValue.arrayUnion([uid]),
          'removedAt.$uid': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('You have left the team.'),
              backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'),
                  backgroundColor: Colors.red));
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Team Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                child: CircularProgressIndicator(color: purple));
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
          final List<String> removedMembers =
              List<String>.from(data['removedMembers'] ?? []);
          final bool isRemovedUser = removedMembers.contains(currentUserId);

          // ── Vote state (file 1) ────────────────────────────
          final Map<String, dynamic>? leaderVoteData =
              data['leaderVote'] as Map<String, dynamic>?;
          final bool hasActiveVote =
              leaderVoteData != null && leaderVoteData['active'] == true;

          // Auto-resolve if timer expired
          if (hasActiveVote) {
            final expiresAt =
                (leaderVoteData['expiresAt'] as Timestamp?)?.toDate();
            if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
              ChatService()
                  .resolveLeaderVote(teamPostId: teamPostId)
                  .ignore();
            }
          }

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('hackathons')
                .doc(hackathonId)
                .get(),
            builder: (context, hackathonSnapshot) {
              if (hackathonSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: purple));
              }

              final hackathonData =
                  hackathonSnapshot.data?.data() ?? {};
              final DateTime? openDate =
                  _parseFirestoreDate(hackathonData['applicationOpenDate']);
              final DateTime? deadline =
                  _parseFirestoreDate(hackathonData['applicationDeadline']);
              final now = DateTime.now();
              final DateTime? effectiveDeadline = deadline != null
                  ? DateTime(deadline.year, deadline.month, deadline.day,
                      23, 59, 59)
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

                    // ── Vote banner (file 1) ─────────────────
                    if (hasActiveVote &&
                        currentUserId != null &&
                        !isRemovedUser) ...[
                      const SizedBox(height: 16),
                      LeaderVoteBanner(
                        teamPostId: teamPostId,
                        leaderVoteData: leaderVoteData!,
                        currentMembers: List<String>.from(
                            memberIds.map((e) => e.toString())),
                      ),
                    ],

                    const SizedBox(height: 24),
                    _sectionTitle('Team Overview'),
                    _infoBox([
                      _dataRow('Team Name', data['teamName'] ?? 'Unnamed'),
                      _dataRow('Team Capacity',
                          '$currentMembers / $hackathonTeamSize members'),
                      const Divider(height: 20),
                      _genderPreferenceRow(
                          data['genderPreference'] ?? 'Any'),
                    ]),
                    const SizedBox(height: 24),
                    _sectionTitle('Project Idea'),
                    _infoBox([
                      Text(
                        (data['projectIdea'] != null &&
                                data['projectIdea']
                                    .toString()
                                    .trim()
                                    .isNotEmpty)
                            ? data['projectIdea']
                            : (data['idea'] != null &&
                                    data['idea']
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                ? data['idea']
                                : 'No project idea added yet.',
                        style: const TextStyle(
                          color: purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionTitle('Current Members & Roles'),
                    FutureBuilder<List<Map<String, String>>>(
                      future: _getMemberDetails(
                          memberIds, leaderId, leaderRole, memberRoles),
                      builder: (context, nameSnapshot) {
                        if (!nameSnapshot.hasData) {
                          return const Center(
                              child: LinearProgressIndicator(
                                  color: purple));
                        }
                        return Column(
                          children: nameSnapshot.data!
                              .map((member) => _memberTile(
                                    context: context,
                                    uid: member['uid']!,
                                    name: member['name']!,
                                    isLeader:
                                        member['isLeader'] == 'true',
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
                                  ))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // ── Leader actions ────────────────────────
                    if (isLeader) ...[
                      if (!isSubmitted && currentMembers < 2)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_clock_outlined,
                                  size: 18,
                                  color: Colors.orange.shade800),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Registration is locked. You need at least 2 members to finalize.',
                                  style: TextStyle(
                                      color: Color(0xFFD35400),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Edit + Join Requests side by side (file 2) ──
                      if (!isSubmitted) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                label: 'Edit Team Info',
                                icon: Icons.edit_outlined,
                                color: purple,
                                onPressed: () =>
                                    _editTeamInfo(context, data),
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
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              LeaderJoinRequestsView(
                                                  teamPostId:
                                                      teamPostId)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        // After submission: Join Requests full-width
                        StreamBuilder<int>(
                          stream: _pendingRequestsCountStream(),
                          builder: (context, snapshot) {
                            final int count = snapshot.data ?? 0;
                            return _actionButton(
                              label: 'View Join Requests',
                              icon: Icons.group_add_outlined,
                              color: purple,
                              badgeCount: count,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        LeaderJoinRequestsView(
                                            teamPostId: teamPostId)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Finalize button — purple (file 2) ───
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
                                ? purple
                                : Colors.grey.shade400),
                        onPressed: canFinalize
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TeamRegistrationFormView(
                                      hackathonId: hackathonId,
                                      teamPostId: teamPostId,
                                      teamName: data['teamName'] ??
                                          'Unnamed Team',
                                      members:
                                          List<String>.from(memberIds),
                                      hackathonTeamSize:
                                          hackathonTeamSize,
                                    ),
                                  ),
                                )
                            : null,
                      ),

                      if (!isSubmitted) ...[
                        // ── Leave Team button (file 1) ───────
                        const SizedBox(height: 12),
                        _actionButton(
                          label: 'Leave Team',
                          icon: Icons.exit_to_app_rounded,
                          color: Colors.orange.shade700,
                          onPressed: () => _leaveTeam(context),
                        ),

                        // ── Delete button — OutlinedButton deepOrange (file 2) ──
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade200, height: 1),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepOrange.shade400,
                              side: BorderSide(
                                  color: Colors.deepOrange.shade300,
                                  width: 1.2),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            onPressed: () =>
                                _showDeleteConfirmation(context),
                            icon: Icon(Icons.delete_outline,
                                size: 18,
                                color: Colors.deepOrange.shade400),
                            label: Text('Delete Team',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.deepOrange.shade400)),
                          ),
                        ),
                      ],

                      // ── Pro tip ──────────────────────────────
                      if (!isSubmitted)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 12, left: 4, right: 4),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.amber.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.tips_and_updates_outlined,
                                    color: Colors.amber.shade900,
                                    size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Pro tip: Make sure all members have completed their profiles before registering. Incomplete profiles may affect your acceptance.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      // ── Member actions ────────────────────────
                      _buildMemberNotice(isSubmitted, currentMembers),
                      if (!isSubmitted) ...[
                        const SizedBox(height: 12),
                        _actionButton(
                          label: isRemovedUser
                              ? 'Removed from Team'
                              : 'Leave Team',
                          icon: Icons.exit_to_app_rounded,
                          color: isRemovedUser ? Colors.grey : Colors.red,
                          onPressed: isRemovedUser
                              ? null
                              : () => _leaveTeam(context),
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

  // ─────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────

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
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => OtherUserProfilePage(userId: uid))),
            child: CircleAvatar(
              backgroundColor: lightPurple,
              radius: 18,
              child: Text(name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      color: purple, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => OtherUserProfilePage(userId: uid))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ),
                      if (isLeader)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: purple,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('Leader',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  Text(role,
                      style: TextStyle(
                          fontSize: 12,
                          color: purple.withOpacity(0.7),
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
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
      noticeText = 'Success! Your team is registered.';
      color = Colors.green;
      icon = Icons.verified;
    } else if (currentMembers >= hackathonTeamSize) {
      noticeText =
          "Team is full! We're just waiting for the leader to finalize registration.";
      color = Colors.orange.shade800;
      icon = Icons.pending_actions;
    } else {
      noticeText =
          'Welcome to the team! We are currently looking for more teammates.';
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
            child: Text(noticeText,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(
      bool isSubmitted, int currentMembers, String? adminStatus) {
    String statusText;
    Color statusColor;
    IconData icon;

    if (isSubmitted) {
      switch (adminStatus) {
        case 'accepted':
          statusText = 'Status: Team Accepted! 🎉';
          statusColor = Colors.green;
          icon = Icons.check_circle_outline;
          break;
        case 'rejected':
          statusText = 'Status: Team Rejected';
          statusColor = Colors.red;
          icon = Icons.error_outline;
          break;
        default:
          statusText = 'Status: Registered & Under Review';
          statusColor = Colors.blue;
          icon = Icons.hourglass_empty_rounded;
      }
    } else {
      if (currentMembers >= hackathonTeamSize) {
        statusText = 'Status: Team Full (Ready to Register)';
        statusColor = Colors.orange.shade800;
        icon = Icons.stars_outlined;
      } else {
        statusText = 'Status: Building Team...';
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
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      );

  Widget _infoBox(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(children: children),
      );

  Widget _dataRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: purple,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

  Widget _genderPreferenceRow(String gender) => Row(
        children: [
          Expanded(
            child: Text('Teammate Gender',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: lightPurple,
                borderRadius: BorderRadius.circular(20)),
            child: Text(gender,
                style: const TextStyle(
                    color: purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      );

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
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: color,
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
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
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditTeamInfoDialog — from file 2 (full StatefulWidget)
// ─────────────────────────────────────────────────────────────────────────────

class _EditTeamInfoDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final String teamPostId;
  final String hackathonId;

  const _EditTeamInfoDialog({
    required this.data,
    required this.teamPostId,
    required this.hackathonId,
  });

  @override
  State<_EditTeamInfoDialog> createState() => _EditTeamInfoDialogState();
}

class _EditTeamInfoDialogState extends State<_EditTeamInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _teamNameController;
  late final TextEditingController _customRoleController;
  late String _selectedGender;
  String? _selectedRole;
  bool _isLoading = false;
  bool _isFetchingRoles = true;
  List<String> _availableRoles = [];
  bool _allowCustomRole = false;

  static const Color purple = Color(0xFF6D56B3);

  @override
  void initState() {
    super.initState();
    _teamNameController =
        TextEditingController(text: widget.data['teamName'] ?? '');
    _customRoleController =
        TextEditingController(text: widget.data['myRole'] ?? '');
    _selectedGender = widget.data['genderPreference'] ?? 'Any';
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hackathons')
          .doc(widget.hackathonId)
          .get();

      if (doc.exists) {
        final List<dynamic>? roles = doc.data()?['rolesNeeded'];
        if (roles != null) {
          setState(() {
            _availableRoles = roles.map((e) => e.toString()).toList();
            _allowCustomRole =
                _availableRoles.any((r) => r.toLowerCase() == 'any');

            final currentRole = widget.data['myRole'] ?? '';
            if (_availableRoles.contains(currentRole)) {
              _selectedRole = currentRole;
            } else if (_allowCustomRole) {
              _selectedRole = 'Any';
              _customRoleController.text = currentRole;
            } else {
              _selectedRole =
                  _availableRoles.isNotEmpty ? _availableRoles.first : null;
            }
          });
        }
      }
    } finally {
      setState(() => _isFetchingRoles = false);
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _customRoleController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required String helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      errorMaxLines: 2,
      prefixIcon: Icon(icon, color: purple),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String newName = _teamNameController.text.trim();
      final String finalRole =
          (_allowCustomRole && _selectedRole == 'Any')
              ? _customRoleController.text.trim()
              : _selectedRole ?? 'Leader';

      final List<String> updatedNeeded =
          List<String>.from(_availableRoles)..remove(finalRole);

      await FirebaseFirestore.instance
          .collection('team_posts')
          .doc(widget.teamPostId)
          .update({
        'teamName': newName,
        'myRole': finalRole,
        'genderPreference': _selectedGender,
        'neededRoles': updatedNeeded,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error updating team: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Team Info',
          style: TextStyle(fontWeight: FontWeight.bold, color: purple)),
      content: _isFetchingRoles
          ? const SizedBox(
              height: 100,
              child: Center(
                  child: CircularProgressIndicator(color: purple)),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _teamNameController,
                      maxLength: 25,
                      decoration: _fieldDecoration(
                        label: 'Team Name',
                        icon: Icons.groups_rounded,
                        helper: 'Letters & numbers only',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Team name cannot be empty';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9 ]+$')
                            .hasMatch(v.trim())) {
                          return 'Letters & numbers only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: _fieldDecoration(
                        label: 'Gender Preference',
                        icon: Icons.wc_rounded,
                        helper: 'Select Preference',
                      ),
                      items: ['Male', 'Female', 'Any']
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedGender = v!),
                      validator: (v) =>
                          v == null ? 'Select Preference' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      decoration: _fieldDecoration(
                        label: 'My role in the team',
                        icon: Icons.person_search_rounded,
                        helper: 'Specify Your Role',
                      ),
                      items: _availableRoles
                          .map((r) => DropdownMenuItem(
                              value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedRole = v),
                      validator: (v) =>
                          v == null ? 'Specify Your Role' : null,
                    ),
                    if (_allowCustomRole && _selectedRole == 'Any') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customRoleController,
                        decoration: _fieldDecoration(
                          label: 'Specify Your Role',
                          icon: Icons.edit_note_rounded,
                          helper: 'Specify Your Role',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Specify Your Role'
                                : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _save,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline, size: 16),
          label: Text(_isLoading ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
