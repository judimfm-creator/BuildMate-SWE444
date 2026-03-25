import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'hackathon_details_view.dart';

class InstitutionTeamPostsView extends StatelessWidget {
  final String hackathonId;

  const InstitutionTeamPostsView({
    super.key,
    required this.hackathonId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);
  static const Color _bgColor = Color(0xFFF8F5FF);
  static const Color _titleColor = Color(0xFF4B3F72);
  static const Color _cardBorder = Color(0xFFD8CCF3);
  static const Color _softText = Color(0xFF7B6D9C);
  static const Color _closedColor = Color(0xFFB86A6A);
  static const Color _openColor = Color(0xFF6D56B3);

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date not available';
    final d = timestamp.toDate();
    return "${_monthName(d.month)} ${d.day} - ${_monthName(d.month)} ${d.day}, ${d.year}";
  }

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
      'Dec'
    ];
    return months[month];
  }

  bool _isOpen(Timestamp? openDate, Timestamp? deadline) {
    if (openDate == null || deadline == null) return false;
    final now = DateTime.now();
    final open = openDate.toDate();
    final close = deadline.toDate();
    return now.isAfter(open) && now.isBefore(close);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Available Hackathons',
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
                color: _purple.withOpacity(0.08),
                blurRadius: 14,
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
              Divider(
                height: 1,
                color: _purple.withOpacity(0.15),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('hackathons')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _purple),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Something went wrong.',
                          style: TextStyle(
                            color: _titleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hackathons available.',
                          style: TextStyle(
                            color: _softText,
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
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _cardBorder,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _purple.withOpacity(0.06),
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
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: _softText,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatDate(deadline),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: _softText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: isOpen ? _openColor : _closedColor,
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
                                            ? _titleColor
                                            : _closedColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: 130,
                                      height: 44,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _purple,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
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
                                            fontSize: 14,
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

  dynamic _hackathonFromDoc(String id, Map<String, dynamic> data) {
    return HackathonFake(
      id: id,
      organizationId: data['organizationId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      domain: data['domain'] ?? '',
      teamSize: data['teamSize'] ?? 0,
      city: data['city'] ?? '',
      location: data['location'] ?? '',
      mode: data['mode'] ?? '',
      rolesNeeded: List<String>.from(data['rolesNeeded'] ?? []),
      educationCriteria: data['educationCriteria'] ?? '',
      applicationOpenDate:
          (data['applicationOpenDate'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      applicationDeadline:
          (data['applicationDeadline'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class HackathonFake {
  final String id;
  final String organizationId;
  final String name;
  final String description;
  final String domain;
  final int teamSize;
  final String city;
  final String location;
  final String mode;
  final List<String> rolesNeeded;
  final String educationCriteria;
  final DateTime applicationOpenDate;
  final DateTime applicationDeadline;
  final DateTime startDate;
  final DateTime endDate;

  HackathonFake({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.description,
    required this.domain,
    required this.teamSize,
    required this.city,
    required this.location,
    required this.mode,
    required this.rolesNeeded,
    required this.educationCriteria,
    required this.applicationOpenDate,
    required this.applicationDeadline,
    required this.startDate,
    required this.endDate,
  });
}