import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_team_post_view.dart';

class ExploreTeamsView extends StatelessWidget {
  final String hackathonId;
  final int hackathonTeamSize;

  const ExploreTeamsView({
    super.key,
    required this.hackathonId,
    required this.hackathonTeamSize,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  // Helper to fetch names and roles without causing overflow
  Future<List<Map<String, dynamic>>> _getMemberData(List<dynamic> ids, String leaderId, String leaderRole, Map<String, dynamic> memberRolesMap) async {
    List<Map<String, dynamic>> members = [];
    for (var id in ids) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      String name = doc.data()?['fullName'] ?? 'User';
      String role = (id == leaderId) ? leaderRole : (memberRolesMap[id] ?? 'Member');
      members.add({'name': name, 'isLeader': id == leaderId, 'role': role});
    }
    return members;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Explore Teams', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _purple));
          
          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data();
            final List members = data['members'] ?? [];
            return data['createdBy'] != currentUserId && !members.contains(currentUserId);
          }).toList();

          if (docs.isEmpty) return const Center(child: Text("No open teams available."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final String teamId = docs[index].id;
              final List memberIds = data['members'] ?? [];
              final Map<String, dynamic> memberRolesMap = data['memberRoles'] ?? {};
              final List<String> roles = _parseStringList(data['neededRoles']);
              
              final bool isFull = memberIds.length >= hackathonTeamSize;
              final bool isRegistered = data['submittedToInstitution'] == true;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header: Name & Clear Capacity ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data['teamName'] ?? 'Team', 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _badge("${memberIds.length} / $hackathonTeamSize Members Joined", isFull ? Colors.red : _purple),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Members & Roles (Overflow Fixed) ---
                      const Text("Team Members", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getMemberData(memberIds, data['createdBy'], data['myRole'] ?? 'Leader', memberRolesMap),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox(height: 20);
                          return Column(
                            children: snap.data!.map((m) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 6, color: _purple),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "${m['name']} (${m['role']})", 
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis, maxLines: 1,
                                    ),
                                  ),
                                  if (m['isLeader']) _miniBadge("Leader"),
                                ],
                              ),
                            )).toList(),
                          );
                        },
                      ),
                      
                      const Divider(height: 32),

                      // --- Project Idea (Null/Empty Check) ---
                      const Text("Project Idea", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        (data['projectIdea'] == null || data['projectIdea'].toString().isEmpty) 
                            ? "No project idea added yet." 
                            : data['projectIdea'],
                        style: TextStyle(
                          color: (data['projectIdea'] == null || data['projectIdea'].toString().isEmpty) ? Colors.grey : Colors.black87,
                          fontSize: 13, height: 1.4,
                          fontStyle: (data['projectIdea'] == null || data['projectIdea'].toString().isEmpty) ? FontStyle.italic : FontStyle.normal,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),

                      // --- Looking For Roles ---
                      const Text("Looking For", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _purple)),
                      const SizedBox(height: 8),
                      _buildRolesList(roles),

                      const SizedBox(height: 24),

                      // --- Action Button ---
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isFull || isRegistered) ? Colors.grey.shade300 : _purple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: (isFull || isRegistered) ? null : () => _showJoinDialog(context, teamId, data['teamName'], roles),
                          child: Text(
                            isRegistered ? "Registration Submitted" : (isFull ? "TEAM FULL" : "JOIN TEAM"), 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
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

  // --- UI Helpers ---
  Widget _badge(String txt, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(txt, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 10)));
  Widget _miniBadge(String txt) => Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)), child: Text(txt, style: TextStyle(fontSize: 9, color: Colors.orange.shade900, fontWeight: FontWeight.bold)));
  
  Widget _buildRolesList(List<String> roles) {
    if (roles.isEmpty) return const Text("No specific roles needed", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic));
    return Wrap(spacing: 8, runSpacing: 8, children: roles.map((role) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _lightPurple, borderRadius: BorderRadius.circular(8), border: Border.all(color: _purple.withOpacity(0.2))), child: Text(role, style: const TextStyle(fontSize: 11, color: _purple, fontWeight: FontWeight.bold)))).toList());
  }

  void _showJoinDialog(BuildContext context, String teamId, String? name, List<String> roles) {
    String? selected;
    // Capture the current context's navigator to use after async calls
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Join $name"),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Pick your role"),
          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => selected = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            onPressed: () async {
  if (selected != null) {
    // 1. CAPTURE the navigator and scaffoldMessenger IMMEDIATELY
    // Do this before any 'await' happens
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 2. Perform the update
      await FirebaseFirestore.instance.collection('team_posts').doc(teamId).update({
        'members': FieldValue.arrayUnion([uid]),
        'memberRoles.$uid': selected,
        'neededRoles': FieldValue.arrayRemove([selected]),
      });

      // 3. Close the Join Dialog using the dialog's own context (ctx)
      if (ctx.mounted) {
        Navigator.pop(ctx);
      }

      // 4. Use the PRE-CAPTURED navigator to change pages
      // This is the "magic" that ensures you actually move to the next screen
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
      messenger.showSnackBar(SnackBar(content: Text("Error joining: $e")));
    }
  }
},
            child: const Text("Confirm Join", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<String> _parseStringList(dynamic value) => value is List ? value.map((e) => e.toString()).toList() : [];
}