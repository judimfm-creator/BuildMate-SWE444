import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InstitutionTeamPostDetailsView extends StatelessWidget {
  final String teamPostId;

  const InstitutionTeamPostDetailsView({
    super.key,
    required this.teamPostId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Details'),
        centerTitle: true,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .snapshots(),
        builder: (context, teamSnapshot) {
          if (teamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (teamSnapshot.hasError) {
            return const Center(
              child: Text('Something went wrong while loading the team.'),
            );
          }

          final teamData = teamSnapshot.data?.data();

          if (teamData == null) {
            return const Center(
              child: Text('Team post not found.'),
            );
          }

          final String teamName =
              (teamData['teamName'] ?? 'Unnamed Team').toString();
          final String leaderName =
              (teamData['leaderName'] ?? 'Unknown Leader').toString();
          final String myRole =
              (teamData['myRole'] ?? 'Not specified').toString();
          final String genderPreference =
              (teamData['genderPreference'] ?? 'Not specified').toString();
          final String description =
              (teamData['description'] ?? 'No description provided.')
                  .toString();
          final String teamStatus =
              (teamData['status'] ?? 'open').toString();

          final int currentMembers = _parseInt(teamData['currentMembers']);
          final int maxMembers = _parseInt(teamData['maxMembers']);

          final List<String> neededRoles =
              _parseStringList(teamData['neededRoles']);
          final List<String> members = _parseStringList(teamData['members']);

          final String hackathonId =
              (teamData['hackathonId'] ?? '').toString();

          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('registrations')
                .where('teamPostId', isEqualTo: teamPostId)
                .limit(1)
                .get(),
            builder: (context, registrationSnapshot) {
              if (registrationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final registrationDocs = registrationSnapshot.data?.docs ?? [];
              final Map<String, dynamic>? registrationData =
                  registrationDocs.isNotEmpty
                      ? registrationDocs.first.data()
                      : null;

              final String? registrationId =
                  registrationDocs.isNotEmpty ? registrationDocs.first.id : null;

              final String ideaName =
                  (registrationData?['ideaName'] ?? 'Not submitted').toString();
              final String briefDescription =
                  (registrationData?['briefDescription'] ?? 'Not submitted')
                      .toString();

              final String registrationStatus =
                  (registrationData?['status'] ?? 'pending').toString();

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: hackathonId.isEmpty
                    ? null
                    : FirebaseFirestore.instance
                        .collection('hackathons')
                        .doc(hackathonId)
                        .get(),
                builder: (context, hackathonSnapshot) {
                  if (hackathonSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  DateTime? applicationDeadline;
                  bool decisionAllowed = false;

                  if (hackathonSnapshot.hasData &&
                      hackathonSnapshot.data != null &&
                      hackathonSnapshot.data!.exists) {
                    final hackathonData = hackathonSnapshot.data!.data() ?? {};
                    final deadlineValue = hackathonData['applicationDeadline'];

                    if (deadlineValue is Timestamp) {
                      applicationDeadline = deadlineValue.toDate();
                    }

                    if (applicationDeadline != null) {
                      decisionAllowed =
                          DateTime.now().isAfter(applicationDeadline) ||
                              DateTime.now().isAtSameMomentAs(
                                applicationDeadline,
                              );
                    }
                  }

                  final bool alreadyDecided =
                      registrationStatus == 'accepted' ||
                          registrationStatus == 'rejected';

                  final bool canDecide =
                      registrationId != null &&
                      decisionAllowed &&
                      !alreadyDecided &&
                      registrationStatus == 'pending';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Team Name
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _lightPurple,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            teamName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _purple,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Team info
                        _infoRow(Icons.person_outline, 'Leader', leaderName),
                        _infoRow(Icons.badge_outlined, 'Leader Role', myRole),
                        _infoRow(
                          Icons.groups_outlined,
                          'Members',
                          maxMembers > 0
                              ? '$currentMembers / $maxMembers'
                              : currentMembers.toString(),
                        ),
                        _infoRow(Icons.wc_outlined, 'Gender', genderPreference),
                        _infoRow(Icons.info_outline, 'Team Status', teamStatus),
                        _infoRow(
                          Icons.assignment_outlined,
                          'Registration Status',
                          registrationStatus,
                        ),

                        const SizedBox(height: 16),

                        /// Team description
                        const Text(
                          'Team Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Registration form
                        const Text(
                          'Hackathon Registration Form',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _lightPurple,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                Icons.lightbulb_outline,
                                'Idea Name',
                                ideaName,
                              ),
                              _infoRow(
                                Icons.description_outlined,
                                'Brief Description',
                                briefDescription,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Needed roles
                        const Text(
                          'Needed Roles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        neededRoles.isEmpty
                            ? Text(
                                'No roles listed.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: neededRoles.map((role) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            _purple.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Text(
                                      role,
                                      style: const TextStyle(
                                        color: _purple,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                        const SizedBox(height: 16),

                        /// Member profiles
                        const Text(
                          'Team Member Profiles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),

                        members.isEmpty
                            ? Text(
                                'No members found.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : Column(
                                children: members.map((memberId) {
                                  return FutureBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(memberId)
                                        .get(),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: _lightPurple,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      final userData =
                                          userSnapshot.data?.data() ?? {};

                                      final String fullName =
                                          (userData['fullName'] ??
                                                  'Unknown User')
                                              .toString();
                                      final String email =
                                          (userData['email'] ?? 'N/A')
                                              .toString();
                                      final String phone =
                                          (userData['phoneNumber'] ?? 'N/A')
                                              .toString();
                                      final String city =
                                          (userData['city'] ?? 'N/A')
                                              .toString();
                                      final String bio =
                                          (userData['bio'] ?? 'No bio')
                                              .toString();
                                      final String skills =
                                          _formatSkills(userData['skills']);

                                      return Container(
                                        width: double.infinity,
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: _lightPurple,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.person,
                                                  color: _purple,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    fullName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: _purple,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            _infoRow(
                                              Icons.email_outlined,
                                              'Email',
                                              email,
                                            ),
                                            _infoRow(
                                              Icons.phone_outlined,
                                              'Phone',
                                              phone,
                                            ),
                                            _infoRow(
                                              Icons.location_city_outlined,
                                              'City',
                                              city,
                                            ),
                                            _infoRow(
                                              Icons.psychology_outlined,
                                              'Skills',
                                              skills,
                                            ),
                                            _infoRow(
                                              Icons.notes_outlined,
                                              'Bio',
                                              bio,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),

                        const SizedBox(height: 20),

                        /// Decision message
                        if (!decisionAllowed)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.shade200,
                              ),
                            ),
                            child: Text(
                              applicationDeadline == null
                                  ? 'The registration deadline could not be verified yet. Team decisions are unavailable.'
                                  : 'You can accept or reject this team only after the registration deadline ends.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),

                        if (alreadyDecided)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: registrationStatus == 'accepted'
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: registrationStatus == 'accepted'
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              registrationStatus == 'accepted'
                                  ? 'This team has already been accepted.'
                                  : 'This team has already been rejected.',
                              style: TextStyle(
                                fontSize: 12,
                                color: registrationStatus == 'accepted'
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),

                        if (!decisionAllowed || alreadyDecided)
                          const SizedBox(height: 12),

                        /// Accept / Reject
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.green.withValues(alpha: 0.35),
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: canDecide
                                    ? () async {
                                        await _updateTeamDecision(
                                          context,
                                          registrationId: registrationId!,
                                          newStatus: 'accepted',
                                        );
                                      }
                                    : null,
                                child: const Text('Accept Team'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.red.withValues(alpha: 0.35),
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: canDecide
                                    ? () async {
                                        await _updateTeamDecision(
                                          context,
                                          registrationId: registrationId!,
                                          newStatus: 'rejected',
                                        );
                                      }
                                    : null,
                                child: const Text('Reject Team'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
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

  Future<void> _updateTeamDecision(
    BuildContext context, {
    required String registrationId,
    required String newStatus,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final registrationRef =
          firestore.collection('registrations').doc(registrationId);
      final teamRef = firestore.collection('team_posts').doc(teamPostId);

      await firestore.runTransaction((transaction) async {
        final registrationSnapshot = await transaction.get(registrationRef);
        final teamSnapshot = await transaction.get(teamRef);

        if (!registrationSnapshot.exists) {
          throw Exception('Registration not found.');
        }

        if (!teamSnapshot.exists) {
          throw Exception('Team post not found.');
        }

        final registrationData =
            registrationSnapshot.data() as Map<String, dynamic>;
        final currentStatus =
            (registrationData['status'] ?? 'pending').toString().toLowerCase();

        if (currentStatus != 'pending') {
          throw Exception('This team decision has already been made.');
        }

        transaction.update(registrationRef, {
          'status': newStatus,
          'reviewedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(teamRef, {
          'status': newStatus,
        });
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'accepted'
                ? 'Team accepted successfully.'
                : 'Team rejected successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update team decision: $e'),
        ),
      );
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

  static String _formatSkills(dynamic skillsValue) {
    if (skillsValue is List) {
      final items = skillsValue.map((e) => e.toString()).toList();
      return items.isEmpty ? 'N/A' : items.join(', ');
    }
    final text = (skillsValue ?? '').toString().trim();
    return text.isEmpty ? 'N/A' : text;
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _purple),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}