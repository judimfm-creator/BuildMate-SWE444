import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_chat_view.dart';
import 'my_team_post_view.dart';

class TeamWorkspaceView extends StatelessWidget {
  final String teamPostId;
  final String hackathonId;

  const TeamWorkspaceView({
    super.key,
    required this.teamPostId,
    required this.hackathonId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _pageBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          "Team Workspace",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
      ),
      // 👈 استخدام Snapshots بدلاً من Future ليحس التطبيق فوراً بأي تغيير في الحالة
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _purple));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Team workspace not found."));
          }

          final data = snapshot.data!.data()!;
          final String teamName = data['teamName'] ?? 'Our Team';
          final String leaderId = data['createdBy'] ?? '';
          final List members = data['members'] ?? [];
          final List<String> removedMembers =
              List<String>.from(data['removedMembers'] ?? []);

          // 🔴 التحقق من حالة المستخدم الحالي
          final bool isLeader = currentUid == leaderId;
          final bool isRemoved = removedMembers.contains(currentUid);

          // فقط لو مو ليدر ومو عضو ومو مطرود = دخل بالخطأ
          if (!isLeader && !members.contains(currentUid) && !isRemoved) {
            return const Center(child: Text("Access Denied."));
          }

          // لو المستخدم أخفى الـ workspace عنده
          final List<String> hiddenFor =
              List<String>.from(data['hiddenFor'] ?? []);
          if (hiddenFor.contains(currentUid)) {
            return const Center(child: Text("Workspace not available."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernHeader(teamName, isRemoved),
                // زر إخفاء الـ workspace (لنفس المستخدم فقط)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Hide Workspace'),
                          content: const Text(
                              'This will hide the workspace from your list.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hide',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('team_posts')
                            .doc(teamPostId)
                            .update({
                          'hiddenFor': FieldValue.arrayUnion([currentUid]),
                        });
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 16),
                    label: const Text('Hide Workspace',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),

                const SizedBox(height: 25),

                // زر تفاصيل الفريق
                _buildActionCard(
                  context,
                  title: "Team Details",
                  subtitle:
                      isRemoved ? "View-only mode" : "View roles and members",
                  icon: Icons.auto_awesome_mosaic_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyTeamPostView(
                          teamPostId: teamPostId,
                          hackathonId: hackathonId,
                          hackathonTeamSize: data['hackathonTeamSize'] ?? 5,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _buildSectionContainer(
                  title: "Current Tasks",
                  icon: Icons.task_alt_rounded,
                  child: Column(
                    children: [
                      _TaskRow(
                          title: "Define Project Scope", deadline: "Today"),
                      const SizedBox(height: 12),
                      _TaskRow(title: "Design User Flow", deadline: "Tomorrow"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // كارد المحادثة
                _buildActionCard(
                  context,
                  title: "Group Chat",
                  subtitle: isRemoved
                      ? "Read-only"
                      : "Discuss ideas with your team",
                  icon: Icons.forum_rounded,
                  isPrimary: true,
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

                const SizedBox(height: 20),

                _buildSectionContainer(
                  title: "Team Resources",
                  icon: Icons.folder_copy_rounded,
                  child: Column(
                    children: [
                      _DocumentRow(fileName: "Project_Proposal.pdf"),
                      const SizedBox(height: 12),
                      _DocumentRow(fileName: "Reference_Links.txt"),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(String teamName, bool isRemoved) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isRemoved
            ? Colors.grey.withOpacity(0.05)
            : _purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: isRemoved
                ? Colors.grey.withOpacity(0.1)
                : _purple.withOpacity(0.1),
            width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isRemoved ? Colors.grey : _purple,
            child:
                const Icon(Icons.groups_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: isRemoved ? Colors.grey : Colors.black87),
                ),
                Text(
                  isRemoved ? "Read-only" : "Collaboration Hub",
                  style: TextStyle(
                      color: isRemoved ? Colors.grey : _purple.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purple.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _purple, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _purple)),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
      bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? _purple.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _purple.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: _purple.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: _purple, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _purple.withOpacity(0.4)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked,
              size: 18, color: Color(0xFF6D56B3)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(deadline,
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String fileName;
  const _DocumentRow({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 18, color: Color(0xFF6D56B3)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(fileName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
          Icon(Icons.download_for_offline_rounded,
              size: 20, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
