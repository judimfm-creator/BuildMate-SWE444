import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'join_team_request_view.dart';

class HackathonTeamsView extends StatelessWidget {
  final String hackathonId;
  final int hackathonTeamSize;

  const HackathonTeamsView({
    super.key,
    required this.hackathonId,
    required this.hackathonTeamSize,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hackathon Teams'),
        centerTitle: true,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .where('hackathonId', isEqualTo: hackathonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong while loading teams.'),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          final docs = allDocs.where((doc) {
            final data = doc.data();

            final int currentMembers = _parseInt(data['currentMembers']);
            final int storedMaxMembers = _parseInt(data['maxMembers']);
            final int maxMembers =
                storedMaxMembers > 0 ? storedMaxMembers : hackathonTeamSize;

            final bool submittedToInstitution =
                data['submittedToInstitution'] == true;

            final bool isComplete = currentMembers >= maxMembers;

            return !submittedToInstitution && !isComplete;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No available team posts for this hackathon.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final String teamPostId = doc.id;
              final String teamName =
                  (data['teamName'] ?? 'Unnamed Team').toString();
              final String leaderName =
                  (data['leaderName'] ?? 'Unknown Leader').toString();
              final String leaderId = (data['leaderId'] ?? '').toString();
              final String description =
                  (data['description'] ?? 'No description provided.')
                      .toString();

              final List<String> neededRoles =
                  _parseStringList(data['neededRoles']);

              final int currentMembers = _parseInt(data['currentMembers']);
              final int storedMaxMembers = _parseInt(data['maxMembers']);
              final int maxMembers =
                  storedMaxMembers > 0 ? storedMaxMembers : hackathonTeamSize;

              return Container(
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
                      teamName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.person_outline, 'Leader', leaderName),
                    _infoRow(
                      Icons.groups_outlined,
                      'Members',
                      '$currentMembers / $maxMembers',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Needed Roles',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    neededRoles.isEmpty
                        ? Text(
                            'No specific roles listed.',
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
                                    color: _purple.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: const TextStyle(
                                    color: _purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: leaderId.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JoinTeamRequestView(
                                      hackathonId: hackathonId,
                                      teamPostId: teamPostId,
                                      leaderId: leaderId,
                                      teamName: teamName,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Request to Join'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _purple),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}