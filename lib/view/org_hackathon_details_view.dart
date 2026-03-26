import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/hackathon.dart';
import '../widgets/buildmate_app_bar.dart';
import 'institution_team_post_details_view.dart';

class OrgHackathonDetailsView extends StatelessWidget {
  final Hackathon hackathon;

  const OrgHackathonDetailsView({
    super.key,
    required this.hackathon,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  String _formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Hackathon Details",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 اسم الهاكثون
            Text(
              hackathon.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "${_formatDate(hackathon.startDate)} - ${_formatDate(hackathon.endDate)}",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            // 🔹 Description
            const Text("Description",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              hackathon.description,
              style: TextStyle(color: Colors.grey.shade700),
            ),

            const SizedBox(height: 24),

            // 🔥 Registered Teams
            const Text(
              "Registered Teams",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('team_posts')
                  .where('hackathonId', isEqualTo: hackathon.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final teams = snapshot.data!.docs;

                if (teams.isEmpty) {
                  return const Text("No teams yet");
                }

                return Column(
                  children: teams.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final teamName =
                        data['teamName'] ?? 'Team';
                    final members =
                        (data['members'] as List?)?.length ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _lightPurple,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.group,
                              color: _purple),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              "$teamName - $members Members",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _purple,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      InstitutionTeamPostDetailsView(
                                    teamPostId: doc.id,
                                  ),
                                ),
                              );
                            },
                            child: const Text("View Team"),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}