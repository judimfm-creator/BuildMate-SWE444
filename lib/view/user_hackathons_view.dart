import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/hackathon.dart';
import 'hackathon_details_view.dart';

class UserHackathonsView extends StatelessWidget {
  const UserHackathonsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('hackathons')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final now = DateTime.now();

          final hackathons = (snapshot.data?.docs ?? [])
              .map((doc) => Hackathon.fromFirestore(doc))
              .where((h) => h.endDate.isAfter(now))
              .toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

          if (hackathons.isEmpty) {
            return const Center(
              child: Text("No hackathons available"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hackathons.length,
            itemBuilder: (context, index) {
              final hackathon = hackathons[index];

              return Card(
                child: ListTile(
                  title: Text(hackathon.name),
                  subtitle: Text(hackathon.city),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HackathonDetailsView(
                          hackathon: hackathon,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}