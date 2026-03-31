import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/team_post_model.dart';
import '../model/hackathon.dart';

class RequestToJoinView extends StatelessWidget {
  final TeamPostModel team;
  final Hackathon? hackathon;

  const RequestToJoinView({
    super.key,
    required this.team,
    this.hackathon,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBg = Color(0xFFF0EEFF);
  static const Color _screenBg = Color(0xFFF8F9FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: _screenBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Explore Teams",
          style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Team Name & Members Count
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      team.teamName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${team.members.length} / ${hackathon?.teamSize ?? '?'} Members",
                      style: const TextStyle(color: _purple, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200, thickness: 1.5),
              const SizedBox(height: 20),

              // 2. Team Members
              const Text("Team Members", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildMembersList(),

              const SizedBox(height: 24),

              // 3. Project Idea
              const Text("Project Idea", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  team.idea.isNotEmpty ? team.idea : "No project idea added yet.",
                  style: TextStyle(
                    color: team.idea.isEmpty ? Colors.grey.shade500 : Colors.black87,
                    fontSize: 13,
                    fontStyle: team.idea.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Looking For (Roles)
              if (hackathon != null && hackathon!.rolesNeeded.isNotEmpty) ...[
                const Text("Looking For", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hackathon!.rolesNeeded.map((role) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(role, style: const TextStyle(color: _purple, fontSize: 12, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],

              // 5. Join Team Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Coming Soon"),
                        backgroundColor: _purple,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text("REQUEST TO JOIN TEAM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    if (team.members.isEmpty) {
      return const Text("No members found.", style: TextStyle(color: Colors.grey));
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: team.members).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No members found.", style: TextStyle(color: Colors.grey));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isLeader = doc.id == team.createdBy;
            final String name = data['fullName'] ?? 'Unknown';
            final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

            // استخراج التخصص كأول مهارة كمثال
            String roleText = isLeader ? "Leader" : "Member";
            if (data['skills'] != null && data['skills'] is List && data['skills'].isNotEmpty) {
              roleText = data['skills'][0];
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _lightBg,
                    child: Text(firstLetter, style: const TextStyle(color: _purple, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text(roleText, style: TextStyle(color: _purple.withOpacity(0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isLeader)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text("Leader", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}