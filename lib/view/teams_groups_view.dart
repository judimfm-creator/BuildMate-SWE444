import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'team_workspace_view.dart';

class TeamsGroupsView extends StatelessWidget {
  const TeamsGroupsView({super.key});

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);
  static const Color _pageBg = Colors.white;

  Future<String> _getHackathonName(String hackathonId) async {
    if (hackathonId.isEmpty) return 'Deleted Hackathon';

    final doc = await FirebaseFirestore.instance
        .collection('hackathons')
        .doc(hackathonId)
        .get();

    if (!doc.exists) return 'Deleted Hackathon';

    final data = doc.data() ?? {};
    return data['hackathonName'] ??
        data['title'] ??
        data['name'] ??
        'Deleted Hackathon';
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in first.")),
      );
    }

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          "Teams and Groups",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('team_posts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _purple));
          }

          if (snapshot.hasError) {
            return const Center(
                child:
                    Text("Something went wrong while loading teams."));
          }

          var docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data();
            final List members = data['members'] ?? [];
            final String createdBy = data['createdBy'] ?? '';
            final List<String> removedMembers =
                List<String>.from(data['removedMembers'] ?? []);

            // الليدر أو عضو حالي أو مطرود — كلهم يشوفون الـ workspace
            final bool isMyTeam = createdBy == currentUid ||
                members.contains(currentUid) ||
                removedMembers.contains(currentUid);

            // لو أخفى الـ workspace ما يظهر في قائمته
            final List<String> hiddenFor =
                List<String>.from(data['hiddenFor'] ?? []);
            final bool isHidden = hiddenFor.contains(currentUid);

            return isMyTeam && !isHidden;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
                child: Text("You are not part of any team yet."));
          }

          // ── Sort: active teams first, completed teams at the bottom ──
          docs.sort((a, b) {
            final aCompleted = a.data()['isCompleted'] == true;
            final bCompleted = b.data()['isCompleted'] == true;
            if (aCompleted == bCompleted) return 0;
            return aCompleted ? 1 : -1; // completed → bottom
          });

          // Brand colors for active teams
          final List<Color> brandColors = [
            const Color(0xFF6D56B3), // موف
            const Color(0xFFFFA726), // برتقالي
            const Color(0xFF26C6DA), // تركواز
          ];

          // Track active-team index separately so color cycling
          // isn't broken by completed teams being interspersed
          int activeIndex = 0;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final String teamPostId = docs[index].id;
              final String teamName = data['teamName'] ?? 'Team';
              final String hackathonId = data['hackathonId'] ?? '';
              final List members = data['members'] ?? [];
              final bool isCompleted = data['isCompleted'] == true;

              // Completed teams get gray; active teams cycle brand colors
              final Color currentColor = isCompleted
                  ? Colors.grey.shade400
                  : brandColors[activeIndex % brandColors.length];

              if (!isCompleted) activeIndex++;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.grey.shade50
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: currentColor.withOpacity(
                          isCompleted ? 0.3 : 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: currentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.diversity_3_rounded,
                      color: currentColor,
                      size: 26,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          teamName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isCompleted
                                ? Colors.grey.shade500
                                : Colors.black87,
                          ),
                        ),
                      ),
                      // ── Completed badge ──────────────────────
                      if (isCompleted)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: const Text(
                            '✅ Completed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: FutureBuilder<String>(
                    future: _getHackathonName(hackathonId),
                    builder: (context, snapshot) {
                      final hackathonName =
                          snapshot.data ?? 'Loading...';
                      return Text(
                        "$hackathonName • ${members.length} members",
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: currentColor.withOpacity(0.6),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamWorkspaceView(
                          teamPostId: teamPostId,
                          hackathonId: hackathonId,
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
