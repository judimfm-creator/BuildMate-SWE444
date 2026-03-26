/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/hackathon.dart';
import 'hackathon_details_view.dart';

class OrgAnnouncedHackathonsPage extends StatelessWidget {
  const OrgAnnouncedHackathonsPage({super.key});

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);
  static const Color _bgColor = Color(0xFFF3F5FA);
  static const Color _titleColor = Color(0xFF183B6B);

  String _monthName(int month) {
    const months = [
      '',
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
    return months[month];
  }

  String _formatRange(Timestamp? start, Timestamp? end) {
    if (start == null || end == null) return 'Date not available';

    final s = start.toDate();
    final e = end.toDate();

    return "${_monthName(s.month)} ${s.day} - ${_monthName(e.month)} ${e.day} ${e.year}";
  }

  bool _isOpen(Timestamp? openDate, Timestamp? deadline) {
    if (openDate == null || deadline == null) return false;

    final now = DateTime.now();
    final open = openDate.toDate();
    final close = deadline.toDate();

    return now.isAfter(open) && now.isBefore(close);
  }

  Hackathon _hackathonFromDoc(String id, Map<String, dynamic> data) {
    return Hackathon(
      id: id,
      organizationId: data['organizationId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      domain: data['domain'] ?? '',
      teamSize: (data['teamSize'] ?? 0) as int,
      city: data['city'] ?? '',
      location: data['location'] ?? '',
      mode: data['mode'] ?? '',
      rolesNeeded: List<String>.from(data['rolesNeeded'] ?? []),
      educationCriteria: data['educationCriteria'] ?? '',
      applicationOpenDate:
          (data['applicationOpenDate'] as Timestamp).toDate(),
      applicationDeadline:
          (data['applicationDeadline'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      organizationName: data['organizationName'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hackathons',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: _lightPurple,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _purple.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available Hackathons',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFD9DDE7)),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('hackathons')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _purple),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Something went wrong.'),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hackathons available.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();

                        final String name =
                            data['name'] ?? 'Unnamed Hackathon';

                        final Timestamp? openDate =
                            data['applicationOpenDate'] as Timestamp?;
                        final Timestamp? deadline =
                            data['applicationDeadline'] as Timestamp?;

                        final bool isOpen = _isOpen(openDate, deadline);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _titleColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _formatRange(openDate, deadline),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color:
                                          isOpen ? Colors.green : Colors.red,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isOpen
                                          ? 'Open for Registration'
                                          : 'Closed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isOpen
                                            ? Colors.black87
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: 130,
                                      height: 42,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  HackathonDetailsView(
                                                hackathon: _hackathonFromDoc(
                                                  doc.id,
                                                  data,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'View Details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/