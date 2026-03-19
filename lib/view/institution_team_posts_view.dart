import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'institution_team_post_details_view.dart';

class InstitutionTeamPostsView extends StatelessWidget {
  final String hackathonId;

  const InstitutionTeamPostsView({
    super.key,
    required this.hackathonId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submitted Team Posts'),
        centerTitle: true,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .where('hackathonId', isEqualTo: hackathonId)
            .where('submittedToInstitution', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong while loading submitted teams.',
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No submitted teams yet.',
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

              final String teamName =
                  (data['teamName'] ?? 'Unnamed Team').toString();
              final String leaderName =
                  (data['leaderName'] ?? 'Unknown Leader').toString();
              final String status = (data['status'] ?? 'submitted').toString();
              final int currentMembers = _parseInt(data['currentMembers']);
              final int maxMembers = _parseInt(data['maxMembers']);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InstitutionTeamPostDetailsView(
                        teamPostId: doc.id,
                      ),
                    ),
                  );
                },
                child: Container(
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
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.person_outline,
                        label: 'Leader',
                        value: leaderName,
                      ),
                      _infoRow(
                        icon: Icons.groups_outlined,
                        label: 'Members',
                        value: '$currentMembers / $maxMembers',
                      ),
                      _infoRow(
                        icon: Icons.info_outline,
                        label: 'Status',
                        value: status,
                      ),
                      const SizedBox(height: 10),

                      FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('registrations')
                            .where('teamPostId', isEqualTo: doc.id)
                            .limit(1)
                            .get(),
                        builder: (context, regSnapshot) {
                          if (regSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          if (regSnapshot.hasError) {
                            return Text(
                              'Failed to load registration form.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade600,
                              ),
                            );
                          }

                          final regDocs = regSnapshot.data?.docs ?? [];

                          if (regDocs.isEmpty) {
                            return Text(
                              'No registration form found.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            );
                          }

                          final regData = regDocs.first.data();
                          final String ideaName =
                              (regData['ideaName'] ?? '-').toString();
                          final String briefDescription =
                              (regData['briefDescription'] ?? '-').toString();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                icon: Icons.lightbulb_outline,
                                label: 'Idea Name',
                                value: ideaName,
                              ),
                              _infoRow(
                                icon: Icons.description_outlined,
                                label: 'Brief Description',
                                value: briefDescription,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InstitutionTeamPostDetailsView(
                                  teamPostId: doc.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: _purple,
                          ),
                          label: const Text(
                            'View Team',
                            style: TextStyle(
                              color: _purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
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
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}