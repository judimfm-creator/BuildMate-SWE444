import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/org_hackathons_view_model.dart';
import '../../model/hackathon.dart';
import 'hackathon_details_view.dart';
import 'explore_user_view.dart';
import 'create_team_post_view.dart'; 
import 'hackathon_teams_view.dart' as teams_view;
import 'my_team_post_view.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _teamsKey = GlobalKey();

  static const Color _purple = Color(0xFF6D56B3);

  void _navigateToExplore(int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreUserView(initialTabIndex: tabIndex),
      ),
    );
  }

  // دالة البحث عن الفريق
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getUserTeamPost(String uid, String hid) async {
    final firestore = FirebaseFirestore.instance;
    final leader = await firestore.collection('team_posts').where('hackathonId', isEqualTo: hid).where('createdBy', isEqualTo: uid).limit(1).get();
    if (leader.docs.isNotEmpty) return leader.docs.first;
    
    final member = await firestore.collection('team_posts').where('hackathonId', isEqualTo: hid).where('members', arrayContains: uid).limit(1).get();
    if (member.docs.isNotEmpty) return member.docs.first;
    return null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserSection(
              title: "Open Hackathons 🚀",
              onExploreTap: () => _navigateToExplore(0),
              child: _buildHackathonsList(),
            ),
            const SizedBox(height: 30),
            _UserSection(
              key: _teamsKey,
              title: "Teams 👥",
              onExploreTap: () => _navigateToExplore(1),
              child: _buildEmptyTeamsState(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHackathonsList() {
    final vm = context.watch<OrgHackathonsViewModel>();

    return StreamBuilder<List<Hackathon>>(
      stream: vm.exploreHackathonsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator(color: _purple)));
        }

        final now = DateTime.now();
        final openList = (snapshot.data ?? []).where((h) {
          return now.isAfter(h.applicationOpenDate) && now.isBefore(h.applicationDeadline);
        }).toList();

        if (openList.isEmpty) {
          return _buildEmptyHackathonsState();
        }

        return SizedBox(
          height: 350,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: openList.length,
            itemBuilder: (context, index) {
              return _buildProfessionalMiniCard(openList[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildProfessionalMiniCard(Hackathon h) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String hid = h.id ?? ""; // نضمن أن الـ ID ليس null

    return Container(
      width: 300, 
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.organizationName ?? "Organizer", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: _purple.withOpacity(0.8), fontSize: 10)),
                      Text(h.name, 
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), 
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _miniStatusBadge("Registration Open", Colors.green),
              ],
            ),
            const Divider(height: 20),

            _compactInfoRow(Icons.category_outlined, h.domain),
            const SizedBox(height: 8),
            _compactInfoRow(Icons.location_on_outlined, "${h.city}, ${h.mode}"),
            const SizedBox(height: 8),
            _compactInfoRow(Icons.groups_outlined, h.teamSize > 2 ? "2 - ${h.teamSize} members" : "2 members"),
            
            const SizedBox(height: 16), 

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5), 
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: Colors.redAccent),
                      SizedBox(width: 4),
                      Text("Deadline:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  Text(
                    "${h.applicationDeadline.day} ${_getMonthName(h.applicationDeadline.month)}", 
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // زر التفاصيل
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HackathonDetailsView(hackathon: h)));
                },
                child: const Text("View Full Details", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 10),

            // منطق الأزرار الذكي
            if (currentUid != null)
              FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
                future: _getUserTeamPost(currentUid, hid),
                builder: (context, teamSnap) {
                  if (teamSnap.connectionState == ConnectionState.waiting) return const SizedBox(height: 38);

                  if (teamSnap.hasData && teamSnap.data != null) {
                    final bool isOwner = teamSnap.data!.data()['createdBy'] == currentUid;
                    return _buildActionBtnOutlined(
                      label: isOwner ? "Manage My Team" : "View My Team",
                      icon: isOwner ? Icons.edit_note_rounded : Icons.visibility_outlined,
                      color: _purple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MyTeamPostView(
                          teamPostId: teamSnap.data!.id, 
                          hackathonId: hid, 
                          hackathonTeamSize: h.teamSize
                        ))).then((_) => setState(() {})); 
                      },
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildActionBtnOutlined(
                          label: "Create Team Post",
                          icon: Icons.add_circle_outline,
                          color: _purple,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTeamPostScreen(hackathonId: hid, hackathonTeamSize: h.teamSize)));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtnOutlined(
                          label: "Join Team",
                          icon: Icons.person_add_alt_1_outlined,
                          color: _purple,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => teams_view.ExploreTeamsView(hackathonId: hid, hackathonTeamSize: h.teamSize)));
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtnOutlined({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _compactInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _purple),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _miniStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildEmptyHackathonsState() {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
      child: const Text("No registration-open hackathons", style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildEmptyTeamsState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: const Column(children: [Icon(Icons.group_off_outlined, color: Colors.grey, size: 40), SizedBox(height: 10), Text("No teams yet", style: TextStyle(color: Colors.grey))]),
    );
  }
}

class _UserSection extends StatelessWidget {
  final String title;
  final VoidCallback onExploreTap;
  final Widget child;
  const _UserSection({super.key, required this.title, required this.onExploreTap, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              GestureDetector(onTap: onExploreTap, child: const Text("Explore more", style: TextStyle(color: Color(0xFFFFA726), fontSize: 12))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}