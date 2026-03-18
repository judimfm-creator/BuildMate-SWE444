import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'institution_registrations_view.dart';
import 'other_user_profile_page.dart';

class InstitutionTeamPostDetailsView extends StatelessWidget {
  final Map<String, dynamic> teamPostData;

  const InstitutionTeamPostDetailsView({
    super.key,
    required this.teamPostData,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  @override
  Widget build(BuildContext context) {
    final String teamPostId = teamPostData['id'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Details'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('registrations')
            .where('teamPostId', isEqualTo: teamPostId)
            .snapshots(),
        builder: (context, registrationSnapshot) {
          if (registrationSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (registrationSnapshot.hasError) {
            return const Center(
              child: Text('Something went wrong while loading registrations'),
            );
          }

          final registrationDocs = registrationSnapshot.data?.docs ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  "Team Information",
                  "Basic information submitted when creating the team post.",
                ),
                const SizedBox(height: 10),
                _infoCard([
                  _row("Team Name", teamPostData['teamName']?.toString() ?? 'N/A'),
                  _row(
                    "Gender Preference",
                    teamPostData['genderPreference']?.toString() ?? 'N/A',
                  ),
                  _row("Creator Role", teamPostData['myRole']?.toString() ?? 'N/A'),
                ]),

                const SizedBox(height: 20),

                _sectionTitle(
                  "Team Members",
                  "Profiles and submitted registration forms for all team members.",
                ),
                const SizedBox(height: 10),

                if (registrationDocs.isEmpty)
                  _infoCard([
                    _row("Members", "No submitted registrations yet"),
                  ])
                else
                  Column(
                    children: registrationDocs.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final doc = entry.value;
                      final data = doc.data() as Map<String, dynamic>;
                      final status =
                          (data['status']?.toString().toLowerCase() ?? 'pending');
                      final userId = data['userId']?.toString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _lightPurple,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _row("Member", "Member $index"),
                              const Divider(height: 16),

                              _row("Full Name", data['fullName']?.toString() ?? 'N/A'),
                              const Divider(height: 16),

                              _row("Email", data['email']?.toString() ?? 'N/A'),
                              const Divider(height: 16),

                              _row("University", data['university']?.toString() ?? 'N/A'),
                              const Divider(height: 16),

                              _row("Major", data['major']?.toString() ?? 'N/A'),
                              const Divider(height: 16),

                              _row("Skills", data['skills']?.toString() ?? 'N/A'),
                              const Divider(height: 16),

                              _row("Motivation", data['motivation']?.toString() ?? 'N/A'),
                              const Divider(height: 16),

                              _statusRow(status),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: userId.isEmpty
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => OtherUserProfilePage(
                                                userId: userId,
                                              ),
                                            ),
                                          );
                                        },
                                  child: const Text("View Profile"),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            Colors.green.withOpacity(0.4),
                                        disabledForegroundColor: Colors.white,
                                      ),
                                      onPressed: status == 'accepted'
                                          ? null
                                          : () async {
                                              await _updateStatus(
                                                context,
                                                doc.id,
                                                'accepted',
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
                                            Colors.red.withOpacity(0.4),
                                        disabledForegroundColor: Colors.white,
                                      ),
                                      onPressed: status == 'rejected'
                                          ? null
                                          : () async {
                                              await _updateStatus(
                                                context,
                                                doc.id,
                                                'rejected',
                                              );
                                            },
                                      child: const Text("Reject"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
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
            color: color.withOpacity(0.12),
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

  Widget _infoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: rows
            .expand(
              (w) => [
                w,
                Divider(
                  color: _purple.withOpacity(0.1),
                  height: 16,
                ),
              ],
            )
            .toList()
          ..removeLast(),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('registrations')
          .doc(docId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration $status successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update registration status'),
        ),
      );
    }
  }
}