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
        title: const Text('Review Team Members', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0.5,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('team_posts').doc(teamPostId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _purple));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data not found.'));
          }

          final data = snapshot.data!.data() ?? {};
          final List<dynamic> memberIds = data['members'] ?? [];
          final String status = data['status'] ?? 'pending';
          final String hackathonId = data['hackathonId'] ?? '';

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('hackathons').doc(hackathonId).get(),
            builder: (context, hackSnap) {
              bool isDeadlinePassed = false;
              
              if (hackSnap.hasData && hackSnap.data!.exists) {
                final hackData = hackSnap.data!.data() as Map<String, dynamic>?;
                if (hackData != null && hackData['applicationDeadline'] != null) {
                  final dynamic deadlineRaw = hackData['applicationDeadline'];
                  
                  DateTime? deadlineDate;
                  if (deadlineRaw is Timestamp) {
                    deadlineDate = deadlineRaw.toDate();
                  } else if (deadlineRaw is String) {
                    deadlineDate = DateTime.tryParse(deadlineRaw);
                  }

                  if (deadlineDate != null) {
                    isDeadlinePassed = DateTime.now().isAfter(deadlineDate);
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Team Members Details", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    ...memberIds.map((id) => _buildMemberCard(id.toString())),

                    const SizedBox(height: 32),

                    // الأزرار أولاً
                    _buildDecisionButtons(context, status, isDeadlinePassed),

                    // الملاحظة تحت الأزرار مباشرة
                    if (!isDeadlinePassed && (status == 'pending' || status == 'pending_approval'))
                      _buildClearDeadlineNote(),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(String uid) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator());
        if (!userSnap.data!.exists) return const SizedBox.shrink();

        final u = userSnap.data!.data() ?? {};
        final skills = u['skills'] is List ? (u['skills'] as List).join(", ") : (u['skills']?.toString() ?? "N/A");

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _lightPurple,
                    child: Text(u['fullName'] != null ? u['fullName'][0] : '?', 
                      style: const TextStyle(color: _purple, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u['fullName'] ?? 'fullName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text("@${u['username'] ?? 'username'}", style: TextStyle(color: _purple.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              _dataLine(Icons.email_outlined, "Email", u['email']),
              _dataLine(Icons.phone_outlined, "Phone", u['phoneNumber']),
              _dataLine(Icons.location_city_outlined, "City", u['city']),
              _dataLine(Icons.wc_outlined, "Gender", u['gender']),
              _dataLine(Icons.psychology_outlined, "Skills", skills),
              
              // الروابط مع خط أزرق تحتها
              const SizedBox(height: 10),
              _underlineLink(Icons.link, "LinkedIn", u['linkedin']),
              _underlineLink(Icons.code, "GitHub", u['github']),
            ],
          ),
        );
      },
    );
  }

  Widget _dataLine(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
          Expanded(child: Text(value?.toString() ?? "N/A", style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _underlineLink(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade400),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 12, 
                color: Colors.blue, 
                decoration: TextDecoration.underline, // الخط تحت الرابط
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionButtons(BuildContext context, String status, bool isDeadlinePassed) {
    if (status == 'accepted' || status == 'rejected') {
      Color c = status == 'accepted' ? Colors.green : Colors.red;
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text("APPLICATION ${status.toUpperCase()}", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: c)),
      );
    }
    return Row(
      children: [
        Expanded(child: _actionBtn("Accept Team", Colors.green, isDeadlinePassed ? () => _updateStatus(context, 'accepted') : null)),
        const SizedBox(width: 12),
        Expanded(child: _actionBtn("Reject Team", Colors.redAccent, isDeadlinePassed ? () => _updateStatus(context, 'rejected') : null)),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await FirebaseFirestore.instance.collection('team_posts').doc(teamPostId).update({'status': newStatus});
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Team status updated: $newStatus")));
  }

  Widget _actionBtn(String l, Color c, VoidCallback? a) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: c, 
      disabledBackgroundColor: Colors.grey.shade300, 
      foregroundColor: Colors.white, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      elevation: 0, 
      padding: const EdgeInsets.symmetric(vertical: 16)
    ),
    onPressed: a, child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)));

  // الملاحظة بشكل أوضح وتحت الأزرار
  Widget _buildClearDeadlineNote() => Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3))
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Buttons are available after registration deadline", 
              style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    ),
  );
}