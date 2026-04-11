import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/buildmate_app_bar.dart';
import 'other_user_profile_page.dart';


class LeaderJoinRequestsView extends StatelessWidget {
  final String teamPostId;

  const LeaderJoinRequestsView({
    super.key,
    required this.teamPostId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);
  static const Color _pageBg = Color(0xFFF8F9FD);

  Future<void> _acceptRequest(
      BuildContext context,
      String requestDocId,
      String requesterId,
      String desiredRole,
      ) async {
    final messenger = ScaffoldMessenger.of(context);

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final requestRef = firestore.collection('join_requests').doc(requestDocId);
    batch.update(requestRef, {'status': 'accepted'});

    final teamPostRef = firestore.collection('team_posts').doc(teamPostId);
    batch.update(teamPostRef, {
      'members': FieldValue.arrayUnion([requesterId]),
    });

    await batch.commit();

    messenger.showSnackBar(
      const SnackBar(content: Text('Request accepted ✓'), backgroundColor: _purple),
    );
    }


  Future<void> _rejectRequest(BuildContext context, String requestDocId) async {

    final messenger = ScaffoldMessenger.of(context);

    await FirebaseFirestore.instance
        .collection('join_requests')
        .doc(requestDocId)
        .update({'status': 'rejected'});

      messenger.showSnackBar(
        const SnackBar(content: Text('Request rejected'), backgroundColor: Color(0xFF616161), ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: BuildMateAppBar(
        titleText: 'Join Requests',
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('join_requests')
            .where('teamPostId', isEqualTo: teamPostId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load join requests.'),
            );
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 42,
                        color: _purple,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Pending Requests',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have not received any join requests yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data();
              final String requestDocId = doc.id;

              final String requesterId =
              (data['requesterId'] ?? '').toString();

              final String desiredRole =
              (data['desiredRole'] ?? 'No role selected').toString();

              final String motivation =
              (data['motivation'] ?? '').toString();

              final Timestamp? createdAt = data['createdAt'] as Timestamp?;
              final String submittedText = createdAt != null
                  ? _formatDate(createdAt.toDate())
                  : 'Recently';

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(requesterId)
                    .get(),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data?.data() ?? {};
                  final String fullName =
                  (userData['fullName'] ?? 'Unknown Applicant').toString();

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: requesterId.isEmpty
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtherUserProfilePage(
                            userId: requesterId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _lightPurple,
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: _purple,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                       const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _lightPurple,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    desiredRole,
                                    style: const TextStyle(
                                      color: _purple,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (motivation.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    motivation,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                  submittedText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    // Accept — filled purple
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _acceptRequest(context, requestDocId, requesterId, desiredRole),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _purple,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Accept', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    // Reject — outlined purple
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _rejectRequest(context, requestDocId),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _purple,
                                          side: const BorderSide(color: _purple, width: 1.5),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Reject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}