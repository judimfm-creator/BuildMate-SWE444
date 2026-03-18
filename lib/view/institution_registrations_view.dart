import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/team_model.dart';

class InstitutionRegistrationsView extends StatelessWidget {
  final TeamModel team;

  const InstitutionRegistrationsView({
    super.key,
    required this.team,
  });

  static const Color purple = Color(0xFF6D56B3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration Forms"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('registrations')
            .where(
              'userId',
              whereIn: team.memberIds.isEmpty ? [''] : team.memberIds,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No registration forms found"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row("Name", data['fullName']?.toString() ?? ''),
                    _row("Email", data['email']?.toString() ?? ''),
                    _row("University", data['university']?.toString() ?? ''),
                    _row("Major", data['major']?.toString() ?? ''),
                    _row("Skills", data['skills']?.toString() ?? ''),
                    _row("Motivation", data['motivation']?.toString() ?? ''),
                    _row("Status", data['status']?.toString() ?? 'pending'),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _updateStatus(docs[index].id, "accepted");
                            },
                            child: const Text("Accept"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _updateStatus(docs[index].id, "rejected");
                            },
                            child: const Text("Reject"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('registrations')
        .doc(docId)
        .update({'status': status});
  }
}