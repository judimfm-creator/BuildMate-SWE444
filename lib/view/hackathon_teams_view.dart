import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'other_user_profile_page.dart';

class ExploreTeamsView extends StatelessWidget {
  final String hackathonId;
  final int hackathonTeamSize;
  final String? teamId;

  const ExploreTeamsView({
    super.key,
    required this.hackathonId,
    required this.hackathonTeamSize,
    this.teamId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  Future<List<Map<String, dynamic>>> _getMemberData(
    List<dynamic> ids,
    String leaderId,
    String leaderRole,
    Map<String, dynamic> memberRolesMap,
  ) async {
    List<Map<String, dynamic>> members = [];

    for (var id in ids) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();

      String name = doc.data()?['fullName'] ?? 'User';
      String role =
          (id == leaderId) ? leaderRole : (memberRolesMap[id] ?? 'Member');

      members.add({
        'uid': id,
        'name': name,
        'isLeader': id == leaderId,
        'role': role,
      });
    }

    return members;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Explore Teams',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('join_requests')
            .where('hackathonId', isEqualTo: hackathonId)
            .where('requesterId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, pendingSnapshot) {
          if (pendingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          final bool hasPendingInHackathon =
              pendingSnapshot.hasData && pendingSnapshot.data!.docs.isNotEmpty;

          if (hasPendingInHackathon) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        color: _purple,
                        size: 42,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Request Sent",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _purple,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Your join request has been sent successfully. Please wait for the team leader to accept or reject your request",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('team_posts')
                .where('hackathonId', isEqualTo: hackathonId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _purple),
                );
              }

              final docs = (snapshot.data?.docs ?? []).where((doc) {
                final data = doc.data();
                final List members = data['members'] ?? [];

                if (teamId != null) {
                  return doc.id == teamId;
                }

                return data['createdBy'] != currentUserId &&
                    !members.contains(currentUserId);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No open teams available."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final String teamId = docs[index].id;
                  final List memberIds = data['members'] ?? [];
                  final Map<String, dynamic> memberRolesMap =
                      data['memberRoles'] ?? {};
                  final List<String> roles =
                      _parseStringList(data['neededRoles']);

                  final bool isFull = memberIds.length >= hackathonTeamSize;
                  final bool isRegistered =
                      data['submittedToInstitution'] == true;

                  final String projectIdea =
                      (data['projectIdea'] ?? data['idea'] ?? '')
                          .toString()
                          .trim();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  data['teamName'] ?? 'Team',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _badge(
                                "${memberIds.length} / $hackathonTeamSize Members",
                                isFull ? Colors.red : _purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          const Text(
                            "Team Members",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getMemberData(
                              memberIds,
                              data['createdBy'],
                              data['myRole'] ?? 'Leader',
                              memberRolesMap,
                            ),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: LinearProgressIndicator(
                                    color: _purple,
                                  ),
                                );
                              }

                              return Column(
                                children: snap.data!
                                    .map(
                                      (m) => _memberTile(
                                        context,
                                        m['uid'].toString(),
                                        m['name'].toString(),
                                        m['isLeader'] == true,
                                        m['role'].toString(),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Project Idea",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              projectIdea.isEmpty
                                  ? "No project idea added yet."
                                  : projectIdea,
                              style: TextStyle(
                                color: projectIdea.isEmpty
                                    ? Colors.grey
                                    : Colors.black87,
                                fontSize: 13,
                                height: 1.4,
                                fontStyle: projectIdea.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Looking For",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _purple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRolesList(roles),
                          const SizedBox(height: 22),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('join_requests')
                                .where('teamPostId', isEqualTo: teamId)
                                .where('requesterId', isEqualTo: currentUserId)
                                .where('status', isEqualTo: 'pending')
                                .snapshots(),
                            builder: (context, requestSnapshot) {
                              final bool hasPendingRequest =
                                  requestSnapshot.hasData &&
                                      requestSnapshot.data!.docs.isNotEmpty;
                              final String? requestDocId = hasPendingRequest
                                  ? requestSnapshot.data!.docs.first.id
                                  : null;

                              if (hasPendingRequest) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade50,
                                      foregroundColor: Colors.orange.shade800,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        side: BorderSide(
                                            color: Colors.orange.shade300),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Withdraw Request?'),
                                          content: const Text(
                                              'Are you sure you want to cancel your join request?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Yes, Withdraw',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true &&
                                          requestDocId != null) {
                                        await FirebaseFirestore.instance
                                            .collection('join_requests')
                                            .doc(requestDocId)
                                            .delete();
                                        final notifs =
                                            await FirebaseFirestore.instance
                                                .collection('notifications')
                                                .where('senderId',
                                                    isEqualTo: currentUserId)
                                                .where('teamPostId',
                                                    isEqualTo: teamId)
                                                .where('type',
                                                    isEqualTo: 'join_request')
                                                .get();
                                        for (final doc in notifs.docs) {
                                          await doc.reference.delete();
                                        }
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Request withdrawn successfully.')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'WITHDRAW REQUEST',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }

                              return SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (isFull || isRegistered)
                                        ? Colors.grey.shade300
                                        : _purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: (isFull || isRegistered)
                                      ? null
                                      : () => _showJoinDialog(
                                            context,
                                            teamId,
                                            hackathonId,
                                            data['teamName'],
                                            roles,
                                          ),
                                  child: Text(
                                    isRegistered
                                        ? "TEAM REGISTERED"
                                        : (isFull ? "TEAM FULL" : "JOIN TEAM"),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _badge(String txt, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        txt,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _miniBadge(String txt) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        txt,
        style: TextStyle(
          fontSize: 9,
          color: Colors.orange.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _memberTile(
    BuildContext context,
    String memberId,
    String name,
    bool isLeader,
    String role,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserProfilePage(userId: memberId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _lightPurple,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isLeader) _miniBadge("Leader"),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: _purple.withOpacity(0.75),
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

  Widget _buildRolesList(List<String> roles) {
    if (roles.isEmpty) {
      return const Text(
        "No specific roles needed",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles
          .map(
            (role) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _lightPurple,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _purple.withOpacity(0.2)),
              ),
              child: Text(
                role,
                style: const TextStyle(
                  fontSize: 11,
                  color: _purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _showJoinDialog(
    BuildContext context,
    String teamId,
    String hackathinId,
    String? name,
    List<String> roles,
  ) {
    String? selected;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text("Join $name"),
          content: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Pick your role"),
            items: roles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) {
              setDialogState(() {
                selected = v;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _purple),
              onPressed: (selected == null || isSubmitting)
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final String uid =
                          FirebaseAuth.instance.currentUser!.uid;

                      try {
                        setDialogState(() {
                          isSubmitting = true;
                        });

                        final existingRequest = await FirebaseFirestore.instance
                            .collection('join_requests')
                            .where('teamPostId', isEqualTo: teamId)
                            .where('requesterId', isEqualTo: uid)
                            .limit(1)
                            .get();

                        if (existingRequest.docs.isNotEmpty) {
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "You already sent a request to this team.",
                              ),
                            ),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('join_requests')
                            .add({
                          'teamPostId': teamId,
                          'hackathonId': hackathinId,
                          'requesterId': uid,
                          'desiredRole': selected,
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        final results = await Future.wait([
                          FirebaseFirestore.instance
                              .collection('team_posts')
                              .doc(teamId)
                              .get(),
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get(),
                        ]);

                        final teamData = results[0].data();
                        final requesterName =
                            (results[1].data()?['fullName'] ?? 'Someone')
                                .toString();

                        if (teamData != null) {
                          final String leaderId =
                              (teamData['createdBy'] ?? '').toString();
                          final String teamName =
                              (teamData['teamName'] ?? 'your team').toString();

                          if (leaderId.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .add({
                              'receiverId': leaderId,
                              'type': 'join_request',
                              'teamPostId': teamId,
                              'hackathonId': hackathinId,
                              'senderId': uid,
                              'title': 'New join request',
                              'message':
                                  '$requesterName wants to join $teamName as $selected',
                              'isRead': false,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          }
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx, true);
                        }

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Join request sent successfully.",
                            ),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text("Error joining: $e")),
                        );
                      }
                    },
              child: const Text(
                "Confirm Join",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseStringList(dynamic value) {
    return value is List ? value.map((e) => e.toString()).toList() : [];
  }
}