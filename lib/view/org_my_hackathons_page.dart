import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/hackathon.dart';
import 'org_hackathon_details_page.dart';

class OrgMyHackathonsPage extends StatelessWidget {
  const OrgMyHackathonsPage({super.key});

  static const Color _pageBg = Color(0xFFF8F7FB);
  static const Color _titleColor = Color(0xFF111827);
  static const Color _buttonPurple = Color(0xFF6D56B3);
  static const Color _cardBorder = Color(0xFFE6E1F3);
  static const Color _lightPurple = Color(0xFFF0EEFF);
  static const Color _orange = Color(0xFFFFA726);

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;

      final parts = value.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date not available";

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

  String _buildDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return "Date not available";
    return "${_formatDate(start)} - ${_formatDate(end)}";
  }

  Hackathon _buildHackathonFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return Hackathon(
      id: doc.id,
      organizationId: data['organizationId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      domain: data['domain'] ?? '',
      teamSize: data['teamSize'] is int
          ? data['teamSize']
          : int.tryParse('${data['teamSize']}') ?? 0,
      city: data['city'] ?? '',
      location: data['location'] ?? '',
      mode: data['mode'] ?? '',
      rolesNeeded: List<String>.from(data['rolesNeeded'] ?? []),
      educationCriteria: data['educationCriteria'] ?? '',
      applicationOpenDate:
          _parseDate(data['applicationOpenDate']) ?? DateTime.now(),
      applicationDeadline:
          _parseDate(data['applicationDeadline']) ?? DateTime.now(),
      startDate: _parseDate(data['startDate']) ?? DateTime.now(),
      endDate: _parseDate(data['endDate']) ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentOrgId = FirebaseAuth.instance.currentUser?.uid;

    if (currentOrgId == null) {
      return const Center(
        child: Text("No organization found"),
      );
    }

    return Container(
      color: _pageBg,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('hackathons')
            .where('organizationId', isEqualTo: currentOrgId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _buttonPurple,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went wrong:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
                  const Text(
                    "Available Hackathons",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: const Color(0xFFE9EDF2),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: docs.isEmpty
                        ? const Center(
                            child: Text(
                              "No hackathons yet",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data = docs[index].data();

                              final String hackathonName =
                                  (data['name'] ?? 'Untitled Hackathon')
                                      .toString();

                              final DateTime? openDate =
                                  _parseDate(data['applicationOpenDate']);
                              final DateTime? deadlineDate =
                                  _parseDate(data['applicationDeadline']);

                              final now = DateTime.now();

                              final bool isOpen = openDate != null &&
                                  deadlineDate != null &&
                                  !now.isBefore(openDate) &&
                                  !now.isAfter(deadlineDate);

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _cardBorder),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hackathonName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _buildDateRange(openDate, deadlineDate),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: isOpen
                                                      ? Colors.green
                                                      : Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  isOpen
                                                      ? "Open for Registration"
                                                      : "Closed",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isOpen
                                                        ? Colors.black87
                                                        : Colors.red,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 118,
                                          height: 38,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _buttonPurple,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () {
                                              final hackathon =
                                                  _buildHackathonFromDoc(
                                                docs[index],
                                              );

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      OrgHackathonDetailsPage(
                                                    hackathon: hackathon,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              "View Details",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _lightPurple,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_month_outlined,
                                            size: 14,
                                            color: _orange,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              "Registration: ${_buildDateRange(openDate, deadlineDate)}",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}