import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/hackathon.dart';
import 'org_hackathon_details_page.dart';

class OrgMyHackathonsPage extends StatelessWidget {
  const OrgMyHackathonsPage({super.key});

  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _titleColor = Color(0xFF1E293B);
  static const Color _statusGreen = Color(0xFF22C55E);
  static const Color _statusRed = Color(0xFFEF4444);
  static const Color _statusOrange = Color(0xFFF59E0B);
  static const Color _blue = Color(0xFF3B82F6);

  String _formatDate(DateTime date) {
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
      'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}";
  }

  @override
  Widget build(BuildContext context) {
    final currentOrgId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _pageBg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hackathons')
            .where('organizationId', isEqualTo: currentOrgId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          List<Hackathon> hackathons = docs
              .where((d) =>
                  ((d.data() as Map<String, dynamic>)['isCancelled'] != true))
              .map((d) => Hackathon.fromFirestore(d))
              .toList();

          hackathons.sort((a, b) {
            final now = DateTime.now();
            final aEnd =
                DateTime(a.endDate.year, a.endDate.month, a.endDate.day, 23, 59, 59);
            final bEnd =
                DateTime(b.endDate.year, b.endDate.month, b.endDate.day, 23, 59, 59);

            bool aFinished = now.isAfter(aEnd);
            bool bFinished = now.isAfter(bEnd);

            if (aFinished && !bFinished) return 1;
            if (!aFinished && bFinished) return -1;
            return a.applicationDeadline.compareTo(b.applicationDeadline);
          });

          final int totalHackathons = hackathons.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Hackathons",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _titleColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "View your hackathons and manage participating teams",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "TOTAL",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$totalHackathons",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: hackathons.isEmpty
                    ? const Center(child: Text("No hackathons found."))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: hackathons.length,
                        itemBuilder: (context, index) {
                          return _buildHackathonCard(context, hackathons[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHackathonCard(BuildContext context, Hackathon hackathon) {
    final now = DateTime.now();

    final deadlineDateTime = DateTime(
      hackathon.applicationDeadline.year,
      hackathon.applicationDeadline.month,
      hackathon.applicationDeadline.day,
      23,
      59,
      59,
    );

    final eventEndDateTime = DateTime(
      hackathon.endDate.year,
      hackathon.endDate.month,
      hackathon.endDate.day,
      23,
      59,
      59,
    );

    String statusText;
    Color statusColor;

    if (now.isAfter(eventEndDateTime)) {
      statusText = "Event Ended";
      statusColor = Colors.blueGrey;
    } else if (now.isBefore(hackathon.applicationOpenDate)) {
      statusText = "Registration Upcoming Soon";
      statusColor = _statusOrange;
    } else if (now.isAfter(deadlineDateTime)) {
      statusText = "Registration Closed";
      statusColor = _statusRed;
    } else {
      statusText = "Registration Open";
      statusColor = _statusGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _purple.withOpacity(0.1),
              child: const Icon(Icons.emoji_events_rounded, color: _purple),
            ),
            title: Text(
              hackathon.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _titleColor,
                height: 1.2,
              ),
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: statusColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('team_posts')
                .where('hackathonId', isEqualTo: hackathon.id)
                .where('status',
                    whereIn: ['opened', 'pending_approval', 'accepted', 'rejected'])
                .snapshots(),
            builder: (context, teamSnapshot) {
              if (teamSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final teamDocs = teamSnapshot.data?.docs ?? [];
              int totalRegistered = teamDocs.length;
              int accepted =
                  teamDocs.where((d) => d.data()['status'] == 'accepted').length;
              int rejected =
                  teamDocs.where((d) => d.data()['status'] == 'rejected').length;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _pageBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Registered", totalRegistered, _blue),
                      _buildStatItem("Accepted", accepted, _statusGreen),
                      _buildStatItem("Rejected", rejected, _statusRed),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateLine(
                        Icons.edit_calendar,
                        "Registration: ${_formatDate(hackathon.applicationOpenDate)} - ${_formatDate(hackathon.applicationDeadline)}",
                      ),
                      const SizedBox(height: 4),
                      _buildDateLine(
                        Icons.rocket_launch,
                        "Event: ${_formatDate(hackathon.startDate)} - ${_formatDate(hackathon.endDate)}",
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OrgHackathonDetailsPage(hackathon: hackathon),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Manage Teams",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          "$count",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black45,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDateLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.black38),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}