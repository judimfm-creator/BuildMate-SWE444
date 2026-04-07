import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_team_post_view.dart';
import 'other_user_profile_page.dart';

class ExploreTeamsView extends StatelessWidget {
  final String hackathonId;
  final int hackathonTeamSize;
  final String? teamId; // 🔴 أضيفي هذا السطر

  const ExploreTeamsView({
    super.key,
    required this.hackathonId,
    required this.hackathonTeamSize,
    this.teamId, // 🔴 وأضيفي هذا السطر
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  Future<List<Map<String, dynamic>>> _getMemberData(
      List<dynamic> ids,
      String leaderId,
      String leaderRole,
      Map<String, dynamic> memberRolesMap,
      ) async {
    List<Map<String, dynamic>> members = [];

    for (var id in ids) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      String name = doc.data()?['fullName'] ?? 'User';
      String role =
      (id == leaderId) ? leaderRole : (memberRolesMap[id] ?? 'Member');

      members.add({
        'uid': id,
        'name': name,
        'isLeader': id == leaderId,
        'role': role,
      });
    }

    return members;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Explore Teams',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .where('hackathonId', isEqualTo: hackathonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data();
            final List members = data['members'] ?? [];

            // إذا كان فيه teamId محدد، نتحقق إنه يطابق الـ ID حق الدوكيمينت الحالي
            if (teamId != null) {
              return doc.id == teamId;
            }

            return data['createdBy'] != currentUserId &&
                !members.contains(currentUserId);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("No open teams available."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final String teamId = docs[index].id;
              final List memberIds = data['members'] ?? [];
              final Map<String, dynamic> memberRolesMap =
                  data['memberRoles'] ?? {};
              final List<String> roles = _parseStringList(data['neededRoles']);

              final bool isFull = memberIds.length >= hackathonTeamSize;
              final bool isRegistered = data['submittedToInstitution'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data['teamName'] ?? 'Team',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _badge(
                            "${memberIds.length} / $hackathonTeamSize Members",
                            isFull ? Colors.red : _purple,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      const Text(
                        "Team Members",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getMemberData(
                          memberIds,
                          data['createdBy'],
                          data['myRole'] ?? 'Leader',
                          memberRolesMap,
                        ),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(color: _purple),
                            );
                          }

                          return Column(
                            children: snap.data!
                                .map(
                                  (m) => _memberTile(
                                context,
                                m['uid'].toString(),
                                m['name'].toString(),
                                m['isLeader'] == true,
                                m['role'].toString(),
                              ),
                            )
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        "Project Idea",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          (data['projectIdea'] == null ||
                              data['projectIdea'].toString().isEmpty)
                              ? "No project idea added yet."
                              : data['projectIdea'],
                          style: TextStyle(
                            color: (data['projectIdea'] == null ||
                                data['projectIdea'].toString().isEmpty)
                                ? Colors.grey
                                : Colors.black87,
                            fontSize: 13,
                            height: 1.4,
                            fontStyle: (data['projectIdea'] == null ||
                                data['projectIdea'].toString().isEmpty)
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        "Looking For",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRolesList(roles),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isFull || isRegistered)
                                ? Colors.grey.shade300
                                : _purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (isFull || isRegistered)
                              ? null
                              : () => _showJoinDialog(
                            context,
                            teamId,
                            data['teamName'],
                            roles,
                          ),
                          child: Text(
                            isRegistered
                                ? "TEAM FULL"
                                : (isFull ? "TEAM FULL" : "JOIN TEAM"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _badge(String txt, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        txt,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _miniBadge(String txt) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        txt,
        style: TextStyle(
          fontSize: 9,
          color: Colors.orange.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _memberTile(
      BuildContext context,
      String memberId,
      String name,
      bool isLeader,
      String role,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserProfilePage(userId: memberId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _lightPurple,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isLeader) _miniBadge("Leader"),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: _purple.withOpacity(0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesList(List<String> roles) {
    if (roles.isEmpty) {
      return const Text(
        "No specific roles needed",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles
          .map(
            (role) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _lightPurple,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _purple.withOpacity(0.2)),
          ),
          child: Text(
            role,
            style: const TextStyle(
              fontSize: 11,
              color: _purple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  void _showJoinDialog(
      BuildContext context,
      String teamId,
      String? name,
      List<String> roles,
      ) {
    String? selected;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text("Join $name"),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Pick your role"),
          items: roles
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => selected = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            onPressed: () async {
              if (selected != null) {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
               final String uid = FirebaseAuth.instance.currentUser!.uid;

        try {
          await FirebaseFirestore.instance
              .collection('team_posts')
              .doc(teamId)
              .update({
            'members': FieldValue.arrayUnion([uid]),
            'memberRoles.$uid': selected,
            'neededRoles': FieldValue.arrayRemove([selected]),
          });

          if (ctx.mounted) {
            // ✅ التعديل الأول: نمرر true عشان صفحة الـ Explore تحس بالنجاح
            Navigator.pop(ctx, true); 
          }

          // ✅ التعديل الثاني: نفتح صفحة MyTeamPostView 
          // لكن التأكد من أن الهوم سيتحدث صار مسؤولية الـ Navigator.pop اللي فوق
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (c) => MyTeamPostView(
                teamPostId: teamId,
                hackathonId: hackathonId,
                hackathonTeamSize: hackathonTeamSize,
              ),
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text("Error joining: $e")),
          );
        }
              }
            },
            child: const Text(
              "Confirm Join",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseStringList(dynamic value) {
    return value is List ? value.map((e) => e.toString()).toList() : [];
  }
}