import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/buildmate_app_bar.dart';
import 'other_user_profile_page.dart';

class LeaderJoinRequestsView extends StatefulWidget {
  final String teamPostId;

  const LeaderJoinRequestsView({
    super.key,
    required this.teamPostId,
  });

  @override
  State<LeaderJoinRequestsView> createState() =>
      _LeaderJoinRequestsViewState();
}

class _LeaderJoinRequestsViewState extends State<LeaderJoinRequestsView> {
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _pageBg = Color(0xFFF8F9FD);
  static const Color _orange = Color(0xFFFFA726);
  static const Color _lightOrange = Color(0xFFFFF3E0);

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _markJoinRequestNotificationsAsRead();
  }

  Future<void> _markJoinRequestNotificationsAsRead() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverId', isEqualTo: currentUserId)
          .where('type', isEqualTo: 'join_request')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // إذا كان عندك teamPostId داخل notification بنعلّم فقط الخاص بهذا الفريق
        // وإذا ما كان موجود، بنعتبره تابع لطلبات الانضمام عامة
        final notifTeamPostId = (data['teamPostId'] ?? '').toString();

        if (notifTeamPostId.isEmpty || notifTeamPostId == widget.teamPostId) {
          batch.update(doc.reference, {'isRead': true});
        }
      }

      await batch.commit();
    } catch (_) {
      // نتجاهل الخطأ حتى ما تنكسر الصفحة
    }
  }

  Future<void> _acceptRequest(
      BuildContext context,
      String requestDocId,
      String requesterId,
      String desiredRole,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. جلب بيانات الفريق للتحقق من العدد الحالي
      final teamPostDoc = await firestore.collection('team_posts').doc(widget.teamPostId).get();

      if (!teamPostDoc.exists) return;

      final data = teamPostDoc.data()!;
      final List<dynamic> currentMembers = data['members'] ?? [];
      final int maxMembers = data['maxMembers'] ?? 4; // تأكد من اسم الحقل عندك

      // 2. التحقق من الشرط
      if (currentMembers.length >= maxMembers) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Cannot accept: The team has reached the maximum capacity!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 3. إذا كان العدد يسمح، نكمل عملية القبول
      final batch = firestore.batch();
      final requestRef = firestore.collection('join_requests').doc(requestDocId);
      final teamPostRef = firestore.collection('team_posts').doc(widget.teamPostId);

      batch.update(requestRef, {'status': 'accepted'});
      batch.update(teamPostRef, {
        'members': FieldValue.arrayUnion([requesterId]),
        'memberRoles.$requesterId': desiredRole,
        // لو كان مطرود ورجع — نظف removedMembers وسجل وقت انضمامه الجديد
        'removedMembers': FieldValue.arrayRemove([requesterId]),
        'memberJoinedAt.$requesterId': FieldValue.serverTimestamp(),
        // نظف removedAt لو كان مطروداً ورجع
        'removedAt.$requesterId': FieldValue.delete(),
      });

      await batch.commit();

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Request accepted ✓'),
          backgroundColor: _purple,
        ),
      );

    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    String requestDocId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    await FirebaseFirestore.instance
        .collection('join_requests')
        .doc(requestDocId)
        .update({
      'status': 'rejected',
    });

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Request rejected'),
        backgroundColor: Color(0xFF616161),
      ),
    );
  }

  Stream<int> _pendingRequestsCountStream() {
    return FirebaseFirestore.instance
        .collection('join_requests')
        .where('teamPostId', isEqualTo: widget.teamPostId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
      body: Column(
        children: [
          StreamBuilder<int>(
            stream: _pendingRequestsCountStream(),
            builder: (context, snapshot) {
              final int count = snapshot.data ?? 0;

              if (count == 0) return const SizedBox(height: 12);

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _lightOrange,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _orange.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: _orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        count == 1
                            ? "You have 1 pending join request"
                            : "You have $count pending join requests",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('join_requests')
                  .where('teamPostId', isEqualTo: widget.teamPostId)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _purple),
                  );
                }

                final requests = snapshot.data?.docs ?? [];

                if (requests.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Pending Requests',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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

                    final requesterId = (data['requesterId'] ?? '').toString();
                    final desiredRole = (data['desiredRole'] ?? 'Member').toString();
                    final motivation = (data['motivation'] ?? '').toString();

                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(requesterId)
                          .get(),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data?.data() ?? {};
                        final requesterName =
                            (userData['fullName'] ?? 'Unknown User').toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OtherUserProfilePage(
                                        userId: requesterId,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: _purple.withOpacity(0.12),
                                      child: Text(
                                        requesterName.isNotEmpty
                                            ? requesterName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: _purple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            requesterName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            desiredRole,
                                            style: TextStyle(
                                              color: _purple.withOpacity(0.85),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                              if (motivation.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FD),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    motivation,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _purple,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _acceptRequest(
                                        context,
                                        doc.id,
                                        requesterId,
                                        desiredRole,
                                      ),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text(
                                        'Accept',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: _purple,
                                        elevation: 0,
                                        side: const BorderSide(color: _purple, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _rejectRequest(context, doc.id),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text(
                                        'Reject',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}