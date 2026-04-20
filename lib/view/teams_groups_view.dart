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
        body: Center(
          child: Text("Please sign in first."),
        ),
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
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong while loading teams."),
            );
          }

          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data();
            final List members = data['members'] ?? [];
            final String createdBy = data['createdBy'] ?? '';

            final bool isMyTeam =
                createdBy == currentUid || members.contains(currentUid);

            final bool workspaceReady = members.length >= 2;

            return isMyTeam && workspaceReady;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text("You are not part of any team yet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final String teamPostId = docs[index].id;
              final String teamName = data['teamName'] ?? 'Team';
              final String hackathonId = data['hackathonId'] ?? '';
              final List members = data['members'] ?? [];

              // 1. تعريف الألوان الثلاثة (موف، برتقالي، تركواز)
              final List<Color> brandColors = [
                const Color(0xFF6D56B3), // الموف
                const Color(0xFFFFA726), // البرتقالي
                const Color(0xFF26C6DA), // التركواز
              ];

              // اختيار اللون بناءً على الترتيب
              final Color currentColor = brandColors[index % brandColors.length];

              // 2. تصميم البوكس الملون (Container)
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  // إطار نحيف جداً بلون الفريق يعطي فخامة
                  border: Border.all(color: currentColor.withOpacity(0.15)),
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
                  // 3. الأيقونة الجديدة بدلاً من الحرف (Leading)
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: currentColor.withOpacity(0.1), // خلفية هادئة من لون الفريق
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.diversity_3_rounded, // أيقونة "ترابط" احترافية
                      color: currentColor,
                      size: 26,
                    ),
                  ),
                  title: Text(
                    teamName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: FutureBuilder<String>(
                    future: _getHackathonName(hackathonId),
                    builder: (context, snapshot) {
                      final hackathonName = snapshot.data ?? 'Loading...';

                      return Text(
                        "$hackathonName • ${members.length} members",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  // 4. تغيير لون السهم ليناسب لون الفريق
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