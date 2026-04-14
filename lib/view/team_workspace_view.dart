import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'group_chat_view.dart';

class TeamWorkspaceView extends StatelessWidget {
  final String teamPostId;
  final String hackathonId;

  const TeamWorkspaceView({
    super.key,
    required this.teamPostId,
    required this.hackathonId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBlue = Color(0xFFD9F3F7);
  static const Color _pageBg = Color(0xFFF8F9FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          "Team Workspace",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Team workspace not found."),
            );
          }

          final data = snapshot.data!.data()!;
          final String teamName = data['teamName'] ?? 'Team Workspace';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _lightBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "$teamName workspace",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _purple,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                _sectionCard(
                  title: "Tasks",
                  color: _purple,
                  child: Column(
                    children: const [
                      _TaskRow(title: "Task #1", deadline: "Next Sprint"),
                      SizedBox(height: 8),
                      _TaskRow(title: "Task #2", deadline: "Next Sprint"),
                      SizedBox(height: 8),
                      _TaskRow(title: "Task #3", deadline: "Next Sprint"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Group Chat — يفتح GroupChatView الحين ───────────────
                _clickCard(
                  context: context,
                  title: "Group Chat",
                  subtitle: "Connect with your BuildMates!",
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatView(
                          teamPostId: teamPostId,
                          teamName: teamName,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _sectionCard(
                  title: "Uploaded Documents",
                  color: _purple,
                  child: Column(
                    children: const [
                      _DocumentRow(fileName: "project_plan.pdf"),
                      SizedBox(height: 8),
                      _DocumentRow(fileName: "meeting_notes.docx"),
                      SizedBox(height: 8),
                      _DocumentRow(fileName: "design_mockup.png"),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _clickCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: _purple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _purple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String deadline;

  const _TaskRow({required this.title, required this.deadline});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.radio_button_unchecked,
            size: 18, color: Color(0xFF6D56B3)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Text(
          deadline,
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String fileName;

  const _DocumentRow({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.insert_drive_file_outlined,
            size: 18, color: Color(0xFF6D56B3)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            fileName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
