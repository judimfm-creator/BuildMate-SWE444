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

  // Color Palette - BuildMate Style
  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _titleColor = Color(0xFF1E293B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _lightPurple = Color(0xFFF3F0FF);
  static const Color _statusGreen = Color(0xFF22C55E);
  static const Color _statusRed = Color(0xFFEF4444);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _statusBlue = Color(0xFF3B82F6);

  String _formatDate(DateTime? date) {
    if (date == null) return "TBD";
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  bool get _isRegistrationClosed {
    return DateTime.now().isAfter(hackathon.applicationDeadline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          hackathon.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // ✅ التعديل الجذري هنا: أضفنا الحالات الأربعة الصحيحة كما هي في قاعدة بياناتك
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .where('hackathonId', isEqualTo: hackathon.id)
            .where('status', whereIn: ['opened', 'pending_approval', 'accepted', 'rejected']) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _purple));
          }

          final docs = snapshot.data?.docs ?? [];
          final int totalTeams = docs.length;

          return Column(
            children: [
              // --- Header Section (Dates & Stats) ---
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                child: Column(
                  children: [
                    _buildDateRow(
                      Icons.assignment_turned_in_outlined,
                      "Registration:",
                      "${_formatDate(hackathon.applicationOpenDate)} - ${_formatDate(hackathon.applicationDeadline)}",
                    ),
                    const SizedBox(height: 12),
                    _buildDateRow(
                      Icons.event_available,
                      "Event Dates:",
                      "${_formatDate(hackathon.startDate)} - ${_formatDate(hackathon.endDate)}",
                    ),
                    const SizedBox(height: 20),
                    
                    // --- TOTAL TEAMS STAT CARD ---
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics_outlined, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            "Total Registered Teams: ",
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "$totalTeams",
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (_isRegistrationClosed)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(5)),
                              child: const Text("FINAL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- TEAMS LIST SECTION ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "Registered Teams List",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _titleColor),
                      ),
                      const SizedBox(height: 12),
                      if (docs.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              "No teams have completed registration yet.",
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: docs.length,
                            padding: const EdgeInsets.only(bottom: 20),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data = docs[index].data();
                              return _buildTeamCard(context, docs[index].id, data);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateRow(IconData icon, String label, String dateRange) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(dateRange, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final teamName = data['teamName']?.toString() ?? 'Unnamed Team';
    final members = data['members'] is List ? (data['members'] as List).length : 0;
    final String status = data['status']?.toString().toLowerCase() ?? 'opened';

    // ✅ تخصيص الألوان بناءً على حالاتك الأربعة
    Color statusColor;
    String displayStatus = status;

    switch (status) {
      case 'accepted':
        statusColor = _statusGreen;
        break;
      case 'rejected':
        statusColor = _statusRed;
        break;
      case 'opened':
        statusColor = _statusBlue;
        displayStatus = "Registered";
        break;
      case 'pending_approval':
        statusColor = _orange;
        displayStatus = "Pending";
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _lightPurple,
            child: const Icon(Icons.groups_rounded, color: _purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        teamName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _titleColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayStatus.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text("$members members", style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InstitutionTeamPostDetailsView(teamPostId: docId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("View Team", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}