import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/hackathon.dart';
import 'org_hackathon_details_page.dart';

class OrgMyHackathonsPage extends StatelessWidget {
  const OrgMyHackathonsPage({super.key});

  static const Color _pageBg = Color(0xFFF8FAFC);
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _titleColor = Color(0xFF1E293B);
  static const Color _statusGreen = Color(0xFF22C55E);
  static const Color _statusRed = Color(0xFFEF4444);
  static const Color _blue = Color(0xFF3B82F6);

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return "${months[date.month - 1]} ${date.day}";
  }

  @override
  Widget build(BuildContext context) {
    final currentOrgId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _pageBg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hackathons')
            .where('organizationId', isEqualTo: currentOrgId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _purple));
          }

          final docs = snapshot.data?.docs ?? [];
          final int totalHackathons = docs.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
             Padding(
  padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
  child: Row(
    children: [
      // Left Side: Texts
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Hackathons",
              style: TextStyle(
                fontSize: 22, // Slightly smaller font
                fontWeight: FontWeight.w900, 
                color: _titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "View your hackathons and manage participating teams",
              style: TextStyle(
                fontSize: 11, // Smaller for better fit
                color: Colors.black45, 
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      
      const SizedBox(width: 12),

      // Right Side: Slimmer Total Badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _purple,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.2), 
              blurRadius: 6, 
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row( // Changed from Column to Row for a "Slim" look
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "TOTAL", 
              style: TextStyle(
                color: Colors.white70, 
                fontSize: 9, 
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "$totalHackathons", 
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
              const SizedBox(height: 10),

              // --- LIST ---
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text("No hackathons found."))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final hackathon = Hackathon.fromFirestore(docs[index]);
                          return _buildHackathonCard(context, hackathon);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHackathonCard(BuildContext context, Hackathon hackathon) {
    final now = DateTime.now();
    final bool isOpen = now.isAfter(hackathon.applicationOpenDate) && 
                       now.isBefore(hackathon.applicationDeadline.add(const Duration(days: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _purple.withOpacity(0.1),
              child: const Icon(Icons.emoji_events_rounded, color: _purple),
            ),
            title: Text(hackathon.name, style: const TextStyle(fontWeight: FontWeight.w800, color: _titleColor)),
            subtitle: Row(
              children: [
                Icon(Icons.circle, size: 8, color: isOpen ? _statusGreen : _statusRed),
                const SizedBox(width: 6),
                Text(isOpen ? "Registration Open" : "Registration Closed", 
                  style: TextStyle(color: isOpen ? _statusGreen : _statusRed, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // --- STATS SECTION (ONLY REGISTERED, ACCEPTED, REJECTED) ---
         // --- STATS SECTION (Updated with your specific status keys) ---
StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: FirebaseFirestore.instance
      .collection('team_posts')
      .where('hackathonId', isEqualTo: hackathon.id)
      // ✅ أضفنا الحالات الخاصة بك هنا لضمان الظهور
      .where('status', whereIn: ['opened', 'pending_approval', 'accepted', 'rejected']) 
      .snapshots(),
  builder: (context, teamSnapshot) {
    if (teamSnapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    final teamDocs = teamSnapshot.data?.docs ?? [];
    
    // حساب الإحصائيات بناءً على مسمياتك
    int totalRegistered = teamDocs.length; 
    int accepted = teamDocs.where((d) => d.data()['status'] == 'accepted').length;
    int rejected = teamDocs.where((d) => d.data()['status'] == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: _pageBg, borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Registered", totalRegistered, _blue),
            _buildStatItem("Accepted", accepted, _statusGreen),
            _buildStatItem("Rejected", rejected, _statusRed),
          ],
        ),
      ),
    );
  },
),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // --- TIMELINE & ACTION ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateLine(Icons.edit_calendar, "Reg: ${_formatDate(hackathon.applicationOpenDate)} - ${_formatDate(hackathon.applicationDeadline)}"),
                      const SizedBox(height: 4),
                      _buildDateLine(Icons.rocket_launch, "Event: ${_formatDate(hackathon.startDate)} - ${_formatDate(hackathon.endDate)}"),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrgHackathonDetailsPage(hackathon: hackathon))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Manage Teams", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text("$count", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildDateLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.black38),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87)),
      ],
    );
  }
}