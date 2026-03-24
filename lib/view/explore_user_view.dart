import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodel/org_hackathons_view_model.dart';
import '../model/hackathon.dart';
import 'hackathon_details_view.dart';
import 'create_team_post_view.dart'; 
import 'hackathon_teams_view.dart' as teams_view;
import 'my_team_post_view.dart';

class ExploreUserView extends StatefulWidget {
  final int initialTabIndex;
  const ExploreUserView({super.key, this.initialTabIndex = 0});

  @override
  State<ExploreUserView> createState() => _ExploreUserViewState();
}

class _ExploreUserViewState extends State<ExploreUserView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBg = Color(0xFFF0EEFF);
  static const Color _screenBg = Color(0xFFF8F9FD);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  String _format(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _purple,
          indicatorWeight: 3,
          labelColor: _purple,
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: "Hackathons"), Tab(text: "Teams")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHackathonList(),
          const Center(child: Text("Teams Feature Coming Soon")),
        ],
      ),
    );
  }
  
Widget _buildHackathonList() {
  final vm = context.watch<OrgHackathonsViewModel>();

  return Column(
    children: [
      // 1. هنا مربع البحث في أعلى الصفحة يكلم الـ ViewModel
      _buildSearchBar(vm), 

      // 2. القائمة تأخذ بقية المساحة
      Expanded(
        child: StreamBuilder<List<Hackathon>>(
          // ✅ نستخدم filteredHackathonsStream لكي يعمل البحث
          stream: vm.filteredHackathonsStream, 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _purple));
            }

            final list = snapshot.data ?? [];

            if (list.isEmpty) return const Center(child: Text("No matching hackathons found."));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: list.length,
              itemBuilder: (context, index) => _buildPremiumHackathonCard(list[index]),
            );
          },
        ),
      ),
    ],
  );
}

// 3. دالة البحث المحدثة لربط النص بالـ ViewModel
Widget _buildSearchBar(OrgHackathonsViewModel vm) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: TextField(
      decoration: InputDecoration(
        hintText: "Search hackathons,institutions,domain",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF6D56B3)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6D56B3), width: 1.5),
        ),
      ),
      onChanged: (value) {
        // ✅ تحديث البحث فورا في الـ ViewModel
        vm.updateSearchQuery(value);
      },
    ),
  );
}

  Widget _buildPremiumHackathonCard(Hackathon h) {
    final DateTime now = DateTime.now();
    final bool regNotStarted = now.isBefore(h.applicationOpenDate);
    final bool regClosed = now.isAfter(h.applicationDeadline);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header & Badge ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("By ${h.organizationName ?? "Organizer"}", 
                          style: TextStyle(fontWeight: FontWeight.w600, color: _purple.withOpacity(0.7), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _statusBadge(regNotStarted, regClosed),
              ],
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),

            _buildInfoRow(Icons.category_outlined, "Domain", h.domain),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.location_on_outlined, "Location", "${h.city}, ${h.mode}"),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.groups_outlined, "Team Size", h.teamSize > 2 ? "2 - ${h.teamSize} members" : "2 members"),            
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _lightBg.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _dateRow("Registration Starts", _format(h.applicationOpenDate), "Registration Deadline", _format(h.applicationDeadline), isDeadline: true),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white)),
                  _dateRow("Event Starts", _format(h.startDate), "Event Ends", _format(h.endDate)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _btn("View Full Details", _purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => HackathonDetailsView(hackathon: h)));
            }),

            const SizedBox(height: 12),

            // ─── منطق الأزرار الذكي (كلها White/Outlined) ───
            if (currentUid != null)
              FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
                future: _getUserTeamPost(currentUid, h.id ?? ""),
                builder: (context, teamSnap) {
                  if (teamSnap.connectionState == ConnectionState.waiting) return const SizedBox();

                  // 1. إذا المستخدم مسجل (Manage/View) - زر أبيض بحدود بنفسجية
                  if (teamSnap.hasData && teamSnap.data != null) {
                    final bool isOwner = teamSnap.data!.data()['createdBy'] == currentUid;
                    return _outlinedBtn(
                      isOwner ? "Manage My Team" : "View My Team", 
                      _purple, 
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MyTeamPostView(
                          teamPostId: teamSnap.data!.id, 
                          hackathonId: h.id ?? "", 
                          hackathonTeamSize: h.teamSize
                        ))).then((_) => setState(() {})); 
                      }
                    );
                  }

                  // 2. إذا لم يكن مسجلاً - أزرار بجانب بعض (كلها Outlined)
                  return Column(
                    children: [
                      if (regClosed)
                        _outlinedBtn("Registration Closed", Colors.grey, null)
                      
                      else if (regNotStarted)
                        Row(
                          children: [
                            Expanded(child: _outlinedBtn("Create Team Post", Colors.grey, null)),
                            const SizedBox(width: 10),
                            Expanded(child: _outlinedBtn("Join Team", Colors.grey, null)),
                          ],
                        )
                      
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _outlinedBtn("Create Team Post", _purple, () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTeamPostScreen(hackathonId: h.id ?? "", hackathonTeamSize: h.teamSize)));
                              }),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _outlinedBtn("Join Existing Team", _purple, () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => teams_view.ExploreTeamsView(hackathonId: h.id ?? "", hackathonTeamSize: h.teamSize)));
                              }),
                            ),
                          ],
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

  // --- Helper Methods ---

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getUserTeamPost(String uid, String hid) async {
    final firestore = FirebaseFirestore.instance;
    final leader = await firestore.collection('team_posts').where('hackathonId', isEqualTo: hid).where('createdBy', isEqualTo: uid).limit(1).get();
    if (leader.docs.isNotEmpty) return leader.docs.first;
    
    final member = await firestore.collection('team_posts').where('hackathonId', isEqualTo: hid).where('members', arrayContains: uid).limit(1).get();
    if (member.docs.isNotEmpty) return member.docs.first;
    return null;
  }

  Widget _btn(String label, Color color, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _outlinedBtn(String label, Color color, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color, 
          side: BorderSide(
            color: onTap == null ? Colors.grey.shade300 : color, 
            width: 1.5
          ),
          disabledForegroundColor: Colors.grey.shade500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _statusBadge(bool ns, bool cl) {
    String label = "Registration Open";
    Color color = Colors.green;
    if (ns) { label = "Registration Opening Soon"; color = Colors.orange; }
    else if (cl) { label = "Registration Closed"; color = Colors.red; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _purple),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }

  Widget _dateRow(String l1, String d1, String l2, String d2, {bool isDeadline = false}) {
    return Row(
      children: [
        Expanded(child: _dateItem(l1, d1)),
        Container(width: 1, height: 20, color: _purple.withOpacity(0.2)),
        const SizedBox(width: 16),
        Expanded(child: _dateItem(l2, d2, isCritical: isDeadline)),
      ],
    );
  }

  Widget _dateItem(String label, String date, {bool isCritical = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCritical ? Colors.redAccent : Colors.black)),
      ],
    );
  }
}