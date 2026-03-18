import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'institution_team_post_details_view.dart';

class InstitutionTeamPostsView extends StatelessWidget {
  final String hackathonId;

  const InstitutionTeamPostsView({
    super.key,
    required this.hackathonId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Posts'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .where('hackathonId', isEqualTo: hackathonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No team posts found'),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final data = {
                ...post.data() as Map<String, dynamic>,
                'id': post.id,
              };

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['teamName'] ?? 'No Team Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Gender Preference: ${data['genderPreference'] ?? ''}',
                      ),
                      Text(
                        'Role: ${data['myRole'] ?? ''}',
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InstitutionTeamPostDetailsView(
                          teamPostData: data,
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