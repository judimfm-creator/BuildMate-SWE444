import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/hackathon.dart';
import 'org_hackathon_details_page.dart';

class OrgMyHackathonsPage extends StatelessWidget {
  const OrgMyHackathonsPage({super.key});

  static const Color _pageBg = Color(0xFFF1F4F8);
  static const Color _titleColor = Color.fromARGB(255, 2, 7, 14);
  static const Color _buttonPurple = Color(0xFF6D56B3); 
  static const Color _cardBorder = Color(0xFFE5E7EB);
  static const Color _statusGreen = Color(0xFF4CAF50);

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
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];

    return "${months[date.month - 1]} ${date.day}";
  }

  String _buildDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return "Date not available";
    return "${_formatDate(start)} - ${_formatDate(end)} ${end.year}";
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
            return const Center(child: CircularProgressIndicator());
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
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Available Hackathons",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0xFFE9EDF2)),
                  const SizedBox(height: 14),
                  Expanded(
                    child: docs.isEmpty
                        ? const Center(
                            child: Text(
                              "No hackathons yet",
                              style: TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final data = docs[index].data();

                              final String hackathonName =
                                  (data['name'] ?? 'Untitled Hackathon').toString();

                              final DateTime? openDate =
                                  _parseDate(data['applicationOpenDate']);
                              final DateTime? deadlineDate =
                                  _parseDate(data['applicationDeadline']);

                              final bool isOpen = deadlineDate != null
                                  ? DateTime.now().isBefore(
                                      deadlineDate.add(const Duration(days: 1)))
                                  : false;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
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
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color.fromARGB(255, 3, 9, 16),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _buildDateRange(openDate, deadlineDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 14,
                                                height: 14,
                                                decoration: const BoxDecoration(
                                                  color: _statusGreen,
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
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: isOpen
                                                        ? Colors.black87
                                                        : Colors.red,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 128,
                                          height: 42,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _buttonPurple, // 💜
                                              foregroundColor: Colors.white,
                                              elevation: 0,
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
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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