import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InstitutionTeamPostDetailsView extends StatelessWidget {
  final String teamPostId;

  const InstitutionTeamPostDetailsView({
    super.key,
    required this.teamPostId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Review Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('team_posts').doc(teamPostId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _purple));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Team not found.'));
          }

          final data = snapshot.data!.data() ?? {};
          final List<dynamic> memberIds = data['members'] ?? [];
          final String leaderId = data['createdBy'] ?? '';
          final String leaderRole = data['myRole'] ?? 'Leader';
          final Map<String, dynamic> memberRoles = data['memberRoles'] ?? {};
          final String status = data['status'] ?? 'pending_approval';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(status),
                const SizedBox(height: 24),

                _sectionTitle("Team Overview"),
                _infoBox([
                  _dataRow("Team Name", data['teamName'] ?? 'Unnamed'),
                  _dataRow("Team Size", "${memberIds.length} Members"),
                  _dataRow("Gender Preference", data['genderPreference'] ?? 'Any'),
                ]),

                const SizedBox(height: 24),

                _sectionTitle("Project Idea"),
                _infoBox([
                  Text(
                    data['projectIdea'] ?? "No description provided.",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
                  ),
                ]),

                const SizedBox(height: 24),

                // قسم الأعضاء - الآن يحتوي على "كل شيء"
                _sectionTitle("Detailed Member Profiles"),
                ...memberIds.map((id) => _buildFullMemberProfile(id, id == leaderId, memberRoles, leaderRole)),

                const SizedBox(height: 32),

                _buildActionButtons(context, status),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- كارت البروفايل الكامل (كل التفاصيل) ---
  Widget _buildFullMemberProfile(String uid, bool isLeader, Map<String, dynamic> roles, String lRole) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator());
        
        final u = userSnap.data!.data() ?? {};
        String displayRole = isLeader ? lRole : (roles[uid] ?? "Member");

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر: الاسم والدور
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: _lightPurple,
                      child: Text(u['fullName']?[0] ?? '?', style: const TextStyle(color: _purple, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['fullName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(displayRole, style: TextStyle(color: _purple.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (isLeader) _badge("Leader", Colors.orange),
                  ],
                ),
              ),
              const Divider(height: 1),

              // التفاصيل الشخصية
              _profileSectionTitle("Contact & Identity"),
              _detailRow(Icons.email_outlined, "Email", u['email']),
              _detailRow(Icons.phone_outlined, "Phone", u['phoneNumber']),
              _detailRow(Icons.location_city_outlined, "City", u['city']),
              _detailRow(Icons.wc_outlined, "Gender", u['gender']),

              // التعليم والخبرة
              _profileSectionTitle("Education & Expertise"),
              _detailRow(Icons.school_outlined, "Major", u['major']),
              _detailRow(Icons.workspace_premium_outlined, "Education Level", u['educationLevel']),
              _detailRow(Icons.psychology_outlined, "Skills", (u['skills'] as List?)?.join(", ")),

              // السيرة الذاتية والروابط
              _profileSectionTitle("Portfolio & Links"),
              _detailRow(Icons.description_outlined, "Bio", u['bio']),
              _detailRow(Icons.link_outlined, "GitHub", u['github']),
              _detailRow(Icons.link_outlined, "LinkedIn", u['linkedin']),
              _detailRow(Icons.language_outlined, "Portfolio", u['portfolio']),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // --- مساعدات التصميم ---

  Widget _profileSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _purple.withOpacity(0.6), letterSpacing: 1)),
    );
  }

  Widget _detailRow(IconData icon, String label, dynamic value) {
    final String text = (value == null || value.toString().isEmpty) ? "Not provided" : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  // (بقية الـ Helpers اللي تحبينها: StatusBanner, Buttons, etc.)
  Widget _buildStatusBanner(String status) {
    Color color = status.contains('approve') ? Colors.green : (status.contains('reject') ? Colors.red : Colors.orange);
    String label = status.replaceAll('_', ' ').toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [Icon(Icons.info_outline, color: color), const SizedBox(width: 12), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    if (status != 'pending_approval') return const SizedBox();
    return Row(
      children: [
        Expanded(child: _btn("Approve Team", Colors.green, () => _updateStatus(context, 'approved'))),
        const SizedBox(width: 12),
        Expanded(child: _btn("Reject Team", Colors.redAccent, () => _updateStatus(context, 'rejected'))),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await FirebaseFirestore.instance.collection('team_posts').doc(teamPostId).update({'status': newStatus});
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Team $newStatus successfully")));
  }

  Widget _btn(String l, Color c, VoidCallback a) => ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: a, child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)));
  Widget _infoBox(List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));
  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)));
  Widget _dataRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _purple))]));
  Widget _badge(String t, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)));
}