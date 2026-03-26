

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
  static const Color _titleColor = Color.fromARGB(255, 3, 9, 17);
  static const Color _borderColor = Color(0xFFE5E7EB);

  String _formatDate(DateTime? date) {
    if (date == null) return "Date not available";

    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];

    return "${months[date.month - 1]} ${date.day}";
  }

  String _buildDateRange() {
    return "${_formatDate(hackathon.applicationOpenDate)} - ${_formatDate(hackathon.applicationDeadline)} ${hackathon.applicationDeadline.year}";
  }

  int _getMembersCount(Map<String, dynamic> data) {
    final members = data['memberIds'];
    if (members is List) return members.length;

    final membersCount = data['membersCount'];
    if (membersCount is int) return membersCount;

    return 0;
  }

  String _getTeamName(Map<String, dynamic> data) {
    final name = data['teamName'];
    if (name is String && name.trim().isNotEmpty) return name;
    return 'Unnamed Team';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _purple, // 💜
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
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hackathon.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _buildDateRange(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(height: 1, color: const Color(0xFFE9EDF2)),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: const Color(0xFFE9EDF2)),
                      const SizedBox(height: 12),
                      Text(
                        hackathon.description.isNotEmpty
                            ? hackathon.description
                            : "No description available.",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(height: 10, color: const Color(0xFFF7F8FB)),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Registered Teams",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: const Color(0xFFE9EDF2)),
                      const SizedBox(height: 14),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('team_posts')
                            .where('hackathonId', isEqualTo: hackathon.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Text(
                              "Something went wrong while loading teams.",
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _borderColor),
                              ),
                              child: const Text(
                                "No registered teams yet.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _borderColor),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: List.generate(docs.length, (index) {
                                final data = docs[index].data();
                                final teamName = _getTeamName(data);
                                final membersCount = _getMembersCount(data);
                                final isFirst = index == 0;
                                final isLast = index == docs.length - 1;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isFirst ? _purple : Colors.white, // 💜
                                    borderRadius: BorderRadius.vertical(
                                      top: isFirst
                                          ? const Radius.circular(14)
                                          : Radius.zero,
                                      bottom: isLast
                                          ? const Radius.circular(14)
                                          : Radius.zero,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isFirst
                                                  ? Icons.lock_outline
                                                  : Icons.diamond_outlined,
                                              color: isFirst
                                                  ? Colors.white
                                                  : _purple,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                "$teamName - $membersCount Members",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isFirst
                                                      ? Colors.white
                                                      : _titleColor,
                                                ),
                                              ),
                                            ),
                                            if (isFirst)
                                              const Icon(
                                                Icons.chevron_right,
                                                color: Colors.white,
                                              )
                                            else
                                              SizedBox(
                                                height: 36,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: _purple, // 💜
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 16,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            InstitutionTeamPostDetailsView(
                                                          teamPostId:
                                                              docs[index].id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                    "View Team",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!isLast)
                                        Container(
                                          height: 1,
                                          color: const Color(0xFFE9EDF2),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}