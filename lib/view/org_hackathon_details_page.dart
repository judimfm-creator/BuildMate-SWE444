
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/hackathon.dart';
import 'institution_team_post_details_view.dart';

class OrgHackathonDetailsPage extends StatelessWidget {
  final Hackathon hackathon;

  const OrgHackathonDetailsPage({
    super.key,
    required this.hackathon,
  });

  static const Color _pageBg = Color(0xFFF1F4F8);
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _titleColor = Color(0xFF111827);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  String _formatDate(DateTime? date) {
    if (date == null) return "";

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return "${months[date.month - 1]} ${date.day}";
  }

  String _buildDateRange() {
    return "${_formatDate(hackathon.applicationOpenDate)} - ${_formatDate(hackathon.applicationDeadline)}";
  }

  int _getMembersCount(Map<String, dynamic> data) {
    final members = data['members'];
    if (members is List) {
      return members.length;
    }
    return 0;
  }

  String _getTeamName(Map<String, dynamic> data) {
    final name = data['teamName'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }
    return 'Unnamed Team';
  }

  String _membersLabel(int count) {
    return count == 1 ? "1 member" : "$count members";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Hackathon Details",
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hackathon.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _buildDateRange(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: const Color(0xFFE9EDF2),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('team_posts')
                        .where('hackathonId', isEqualTo: hackathon.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: _purple,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            "Something went wrong while loading teams.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No teams submitted yet",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _lightPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Submitted Teams",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _titleColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data();

                                final teamName = _getTeamName(data);
                                final membersCount = _getMembersCount(data);

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _borderColor),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x12000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: _purple.withOpacity(0.10),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.groups_2_outlined,
                                          color: _purple,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              teamName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _titleColor,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _membersLabel(membersCount),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 34,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _purple,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
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
                                          child: const Text(
                                            "View",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}