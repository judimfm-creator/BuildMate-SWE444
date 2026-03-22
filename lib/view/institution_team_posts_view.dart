import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'institution_team_post_details_view.dart';

class InstitutionTeamPostsView extends StatelessWidget {
  final String hackathonId;

  const InstitutionTeamPostsView({
    super.key,
    required this.hackathonId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Submitted Teams', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .where('hackathonId', isEqualTo: hackathonId)
            .where('submittedToInstitution', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _purple));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No teams have submitted yet.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final String teamName = data['teamName'] ?? 'Unnamed Team';
              final List members = data['members'] ?? [];
              final int currentMembers = members.length; 
              final int maxMembers = data['maxMembers'] ?? 0;
              
              // التعديل هنا: نأخذ الحالة ونخلي أول حرف كبير فقط (بدل الكابيتال الكامل)
              String status = data['status'] ?? 'pending_approval';
              status = status.replaceAll('_', ' '); // استبدال الـ underscore بمسافة

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InstitutionTeamPostDetailsView(teamPostId: doc.id),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  teamName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // استدعاء الـ Badge المعدل
                              _statusBadge(status),
                            ],
                          ),
                          const Divider(height: 30),

                          _infoRow(Icons.groups_outlined, "Team Size", "$currentMembers / $maxMembers Members"),
                          const SizedBox(height: 8),
                         
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _purple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InstitutionTeamPostDetailsView(teamPostId: doc.id),
                                ),
                              ),
                              child: const Text(
                                "Review Team Details",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _statusBadge(String status) {
    Color color = _purple;
    String displayStatus = status;

    // تغيير الألوان بناءً على الكلمات
    if (status.toLowerCase().contains('approve')) {
      color = Colors.green;
      displayStatus = "Approved";
    } else if (status.toLowerCase().contains('reject')) {
      color = Colors.red;
      displayStatus = "Rejected";
    } else if (status.toLowerCase().contains('pending')) {
      color = Colors.orange;
      displayStatus = "Pending Approval";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayStatus, // تظهر الحين بشكل طبيعي (Approved, Pending Approval)
        style: TextStyle(
          color: color, 
          fontSize: 11, // كبرنا الخط شوي عشان يوضح
          fontWeight: FontWeight.w600 // خليناه أنحف شوي من الـ Bold الكامل
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _purple),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}