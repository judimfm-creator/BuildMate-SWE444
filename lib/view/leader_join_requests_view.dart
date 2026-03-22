/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderJoinRequestsView extends StatelessWidget {
  final String teamPostId;
  final int hackathonTeamSize;

  const LeaderJoinRequestsView({
    super.key,
    required this.teamPostId,
    required this.hackathonTeamSize,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Requests'),
        centerTitle: true,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .get(),
        builder: (context, teamSnapshot) {
          if (teamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (teamSnapshot.hasError) {
            return const Center(
              child: Text('Failed to load team information.'),
            );
          }

          if (!teamSnapshot.hasData || !teamSnapshot.data!.exists) {
            return const Center(
              child: Text('Team post not found.'),
            );
          }

          final teamData = teamSnapshot.data!.data() ?? {};
          final List<String> currentMembers =
              _parseStringList(teamData['members']);

          final int storedCurrentMembers =
              _parseInt(teamData['currentMembers']);
          final int storedMaxMembers = _parseInt(teamData['maxMembers']);

          final int currentMembersCount = storedCurrentMembers > 0
              ? storedCurrentMembers
              : currentMembers.length;

          final int maxMembers =
              storedMaxMembers > 0 ? storedMaxMembers : hackathonTeamSize;

          final bool isTeamFull = currentMembersCount >= maxMembers;
          final bool submittedToInstitution =
              teamData['submittedToInstitution'] == true;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('join_requests')
                .where('teamPostId', isEqualTo: teamPostId)
                .snapshots(),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (requestSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load join requests.\n\nThis is usually caused by a Firestore query issue or missing fields in the request documents.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              }

              final requests = requestSnapshot.data?.docs.toList() ?? [];

              requests.sort((a, b) {
                final Timestamp? aTime = a.data()['createdAt'] as Timestamp?;
                final Timestamp? bTime = b.data()['createdAt'] as Timestamp?;

                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;

                return bTime.compareTo(aTime);
              });

              if (requests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _lightPurple,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _purple.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 42,
                            color: _purple,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Join Requests Yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _purple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            submittedToInstitution
                                ? 'This team has already been submitted to the institution, and requests can no longer be managed.'
                                : 'You have not received any join requests yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final requestDoc = requests[index];
                  final data = requestDoc.data();

                  final String status =
                      (data['status']?.toString().toLowerCase() ?? 'pending');
                  final String requesterId =
                      (data['requesterId'] ?? '').toString();

                  final String fullName =
                      (data['fullName'] ?? 'Unknown Applicant').toString();
                  final String email = (data['email'] ?? 'N/A').toString();
                  final String university =
                      (data['university'] ?? 'N/A').toString();
                  final String major = (data['major'] ?? 'N/A').toString();
                  final String desiredRole =
                      (data['desiredRole'] ?? 'N/A').toString();
                  final String skills = _formatSkills(data['skills']);
                  final String motivation =
                      (data['motivation'] ?? 'N/A').toString();
                  final String portfolioLink =
                      ((data['portfolioLink'] ?? '').toString().trim().isEmpty)
                          ? 'Not provided'
                          : data['portfolioLink'].toString();

                  final bool disableAccept = status != 'pending' ||
                      requesterId.isEmpty ||
                      isTeamFull ||
                      submittedToInstitution;

                  final bool disableReject =
                      status != 'pending' || submittedToInstitution;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _lightPurple,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _purple.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _purple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _row("Email", email),
                        const SizedBox(height: 8),
                        _row("University", university),
                        const SizedBox(height: 8),
                        _row("Major", major),
                        const SizedBox(height: 8),
                        _row("Desired Role", desiredRole),
                        const SizedBox(height: 8),
                        _row("Skills", skills),
                        const SizedBox(height: 8),
                        _row("Motivation", motivation),
                        const SizedBox(height: 8),
                        _row("Portfolio Link", portfolioLink),
                        const SizedBox(height: 14),
                        _statusRow(status),
                        const SizedBox(height: 14),

                        if (submittedToInstitution) ...[
                          Text(
                            'This team has already been submitted to the institution. Requests can no longer be managed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (isTeamFull &&
                            status == 'pending' &&
                            !submittedToInstitution) ...[
                          Text(
                            'This team is already full. No more members can be accepted.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.green.withValues(alpha: 0.4),
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: disableAccept
                                    ? null
                                    : () async {
                                        await _acceptRequest(
                                          context,
                                          requestId: requestDoc.id,
                                          requesterId: requesterId,
                                        );
                                      },
                                child: const Text("Accept"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.red.withValues(alpha: 0.4),
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: disableReject
                                    ? null
                                    : () async {
                                        await _rejectRequest(
                                          context,
                                          requestId: requestDoc.id,
                                        );
                                      },
                                child: const Text("Reject"),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatSkills(dynamic skillsValue) {
    if (skillsValue is List) {
      final items = skillsValue.map((e) => e.toString()).toList();
      return items.isEmpty ? 'N/A' : items.join(', ');
    }
    final text = (skillsValue ?? '').toString().trim();
    return text.isEmpty ? 'N/A' : text;
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
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

  Widget _statusRow(String status) {
    Color color;
    String text;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        text = 'accepted';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'rejected';
        break;
      default:
        color = Colors.orange;
        text = 'pending';
    }

    return Row(
      children: [
        const Text(
          "Status: ",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptRequest(
    BuildContext context, {
    required String requestId,
    required String requesterId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final teamRef = firestore.collection('team_posts').doc(teamPostId);
      final requestRef = firestore.collection('join_requests').doc(requestId);

      await firestore.runTransaction((transaction) async {
        final teamSnapshot = await transaction.get(teamRef);
        final requestSnapshot = await transaction.get(requestRef);

        if (!teamSnapshot.exists) {
          throw Exception('Team post not found.');
        }

        if (!requestSnapshot.exists) {
          throw Exception('Join request not found.');
        }

        final requestData = requestSnapshot.data() as Map<String, dynamic>;
        final String currentRequestStatus =
            (requestData['status'] ?? 'pending').toString().toLowerCase();

        if (currentRequestStatus != 'pending') {
          throw Exception('This request has already been processed.');
        }

        final teamData = teamSnapshot.data() as Map<String, dynamic>;
        final List<String> members = _parseStringList(teamData['members']);
        final int storedCurrentMembers = _parseInt(teamData['currentMembers']);
        final int storedMaxMembers = _parseInt(teamData['maxMembers']);

        final int currentMembersCount = storedCurrentMembers > 0
            ? storedCurrentMembers
            : members.length;

        final int maxMembers =
            storedMaxMembers > 0 ? storedMaxMembers : hackathonTeamSize;

        final bool submittedToInstitution =
            teamData['submittedToInstitution'] == true;

        if (submittedToInstitution) {
          throw Exception(
            'This team has already been submitted to the institution.',
          );
        }

        if (members.contains(requesterId)) {
          throw Exception('User is already a member of this team.');
        }

        if (currentMembersCount >= maxMembers) {
          throw Exception('This team is already full.');
        }

        members.add(requesterId);

        final int newCurrentMembers = members.length;
        final bool isTeamComplete = newCurrentMembers >= maxMembers;
        final String newStatus = isTeamComplete ? 'full' : 'open';

        transaction.update(teamRef, {
          'members': members,
          'currentMembers': newCurrentMembers,
          'isTeamComplete': isTeamComplete,
          'status': newStatus,
        });

        transaction.update(requestRef, {
          'status': 'accepted',
        });
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request accepted successfully.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
        ),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context, {
    required String requestId,
  }) async {
    try {
      final requestRef =
          FirebaseFirestore.instance.collection('join_requests').doc(requestId);

      final requestSnapshot = await requestRef.get();

      if (!requestSnapshot.exists) {
        throw Exception('Join request not found.');
      }

      final requestData = requestSnapshot.data() ?? {};
      final String currentStatus =
          (requestData['status'] ?? 'pending').toString().toLowerCase();

      if (currentStatus != 'pending') {
        throw Exception('This request has already been processed.');
      }

      await requestRef.update({
        'status': 'rejected',
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request rejected successfully.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject request: $e'),
        ),
      );
    }
  }
}*/