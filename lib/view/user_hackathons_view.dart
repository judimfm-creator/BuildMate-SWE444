import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/hackathon.dart';
import 'hackathon_details_view.dart';

class UserHackathonsView extends StatelessWidget {
  const UserHackathonsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hackathons')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No hackathons available"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final hackathon = Hackathon.fromFirestore(docs[index]);
              return Card(
                child: ListTile(
                  title: Text(hackathon.name),
                  subtitle: Text(hackathon.city),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HackathonDetailsView(hackathon: hackathon),
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