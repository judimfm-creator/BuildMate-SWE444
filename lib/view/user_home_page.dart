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
import '../../model/team_post_model.dart';
import 'team_post_details_view.dart';
import '../../home_screen.dart';

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
    targetExploreTab = tabIndex;
    homeScreenState?.changeTab(1);
    Future.delayed(const Duration(milliseconds: 100), () {
      exploreTabStream.add(tabIndex);
    });
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getUserTeamPost(
      String uid, String hid) async {
    final firestore = FirebaseFirestore.instance;
    final leader = await firestore
        .collection('team_posts')
        .where('hackathonId', isEqualTo: hid)
        .where('createdBy', isEqualTo: uid)
        .limit(1)
        .get();
    if (leader.docs.isNotEmpty) return leader.docs.first;

    final member = await firestore
        .collection('team_posts')
        .where('hackathonId', isEqualTo: hid)
        .where('members', arrayContains: uid)
        .limit(1)
        .get();
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
              title: "Hackathons 🚀",
              actionLabel: "View all hackathons",
              onExploreTap: () => _navigateToExplore(0),
              child: _buildHackathonsList(),
            ),
            const SizedBox(height: 30),
            _UserSection(
              key: _teamsKey,
              title: "My Teams 👥",
              actionLabel: "Find Teams to Join",
              onExploreTap: () => _navigateToExplore(1),
              child: _buildTeamsList(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ─── دوال بناء قائمة الهاكاثونات ───
  Widget _buildHackathonsList() {
    return StreamBuilder<QuerySnapshot>(
      key: UniqueKey(),
      stream: FirebaseFirestore.instance.collection('hackathons').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator(color: _purple)));
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = DateTime(now.year, now.month, now.day + 1);

        final all = snapshot.data?.docs.map((doc) => Hackathon.fromFirestore(doc)).toList() ?? [];

        final closingSoonList = all.where((h) {
          final deadline = h.applicationDeadline;
          final hackDate = DateTime(deadline.year, deadline.month, deadline.day);
          bool matchesDates = hackDate.isAtSameMomentAs(today) || hackDate.isAtSameMomentAs(tomorrow);
          bool isNotExpired = now.isBefore(DateTime(deadline.year, deadline.month, deadline.day, 23, 59, 59));
          return matchesDates && isNotExpired;
        }).toList();

        if (closingSoonList.isEmpty) {
          return Container(
            width: double.infinity, height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text("No hackathons closing in the next 2 days.", style: TextStyle(color: Colors.grey, fontSize: 12))),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 12, color: Colors.red),
                    SizedBox(width: 4),
                    Text("LAST CALL: CLOSING SOON", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 380,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: closingSoonList.length,
                itemBuilder: (context, index) => _buildProfessionalMiniCard(closingSoonList[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── دوال بناء قائمة وكروت الفرق ───
  Widget _buildTeamsList() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return _buildEmptyTeamsState();

    return StreamBuilder<QuerySnapshot>(
      // تنصت مباشر لكل بوستات الفرق بدون فلاتر فايربيز معقدة
      stream: FirebaseFirestore.instance.collection('team_posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator(color: _purple)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyTeamsState();

        // 1. التصفية محلياً: نجيب بس الفرق اللي اليوزر الحالي موجود في قائمة أعضاءها أو هو المؤسس
        final myTeams = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final members = List<String>.from(data['members'] ?? []);
          final createdBy = data['createdBy'] ?? '';
          return members.contains(currentUid) || createdBy == currentUid;
        }).toList();

        if (myTeams.isEmpty) return _buildEmptyTeamsState();

        // 2. دمج تفاصيل الهاكاثون مع الفريق
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(myTeams.map((doc) async {
            final data = doc.data() as Map<String, dynamic>;
            final team = TeamPostModel.fromMap(doc.id, data);
            final hackathonDoc = await FirebaseFirestore.instance.collection('hackathons').doc(team.hackathonId).get();

            Hackathon? hackathon;
            if (hackathonDoc.exists) {
              hackathon = Hackathon.fromFirestore(hackathonDoc);
            }
            return {
              'team': team,
              'hackathon': hackathon,
              'isSubmitted': data['submittedToInstitution'] == true
            };
          })),
          builder: (context, futureSnapshot) {
            if (!futureSnapshot.hasData) {
              return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator(color: _purple)));
            }

            // 🔴 شلنا الفلتر حق التواريخ اللي كان يخفي الفريق لو الهاكاثون انتهى تسجيله
            var list = futureSnapshot.data!.where((item) => item['hackathon'] != null).toList();

            // ترتيب الفرق من الأحدث للأقدم
            list.sort((a, b) => (b['team'] as TeamPostModel).createdAt.compareTo((a['team'] as TeamPostModel).createdAt));

            if (list.isEmpty) return _buildEmptyTeamsState();

            return SizedBox(
              height: 265,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: list.length > 10 ? 10 : list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _buildProfessionalTeamMiniCard(
                      item['team'] as TeamPostModel,
                      item['hackathon'] as Hackathon,
                      item['isSubmitted'] as bool
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfessionalMiniCard(Hackathon h) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String hid = h.id ?? "";
    final now = DateTime.now();
    final endOfDeadline = DateTime(h.applicationDeadline.year, h.applicationDeadline.month, h.applicationDeadline.day, 23, 59, 59);
    final bool regClosed = now.isAfter(endOfDeadline);
    final bool regNotStarted = now.isBefore(h.applicationOpenDate);

    return Container(
      width: 300, margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('hackathons').doc(hid).get(),
                      builder: (context, snap) {
                        String orgName = "Organizer";
                        if (snap.hasData && snap.data!.exists) {
                          final data = snap.data!.data() as Map<String, dynamic>;
                          orgName = data['orgName'] ?? data['organizationName'] ?? "Organizer";
                        }
                        return Text("By $orgName", style: TextStyle(fontWeight: FontWeight.bold, color: _purple.withOpacity(0.8), fontSize: 10, letterSpacing: 0.5), maxLines: 2, overflow: TextOverflow.ellipsis);
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(h.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                const SizedBox(width: 8),
                _miniStatusBadge(regClosed ? "Closed" : (regNotStarted ? "Upcoming" : "Open"), regClosed ? Colors.red : (regNotStarted ? Colors.orange : Colors.green)),
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
              decoration: BoxDecoration(color: const Color(0xFFFFF5F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(children: [Icon(Icons.timer_outlined, size: 12, color: Colors.redAccent), SizedBox(width: 4), Text("Registration Deadline:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))]),
                  Text("${h.applicationDeadline.day} ${_getMonthName(h.applicationDeadline.month)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 42, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HackathonDetailsView(hackathon: h))),
              child: const Text("View Full Details", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 10),
            if (currentUid != null)
              FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
                key: ValueKey('card_${h.id}_${DateTime.now().millisecondsSinceEpoch}'),
                future: _getUserTeamPost(currentUid, hid),
                builder: (context, teamSnap) {
                  if (teamSnap.connectionState == ConnectionState.waiting) return const SizedBox(height: 38);
                  if (teamSnap.hasData && teamSnap.data != null) {
                    final bool isOwner = teamSnap.data!.data()['createdBy'] == currentUid;
                    return _buildActionBtnOutlined(label: isOwner ? "Manage My Team" : "View My Team", icon: isOwner ? Icons.edit_note_rounded : Icons.visibility_outlined, color: _purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyTeamPostView(teamPostId: teamSnap.data!.id, hackathonId: hid, hackathonTeamSize: h.teamSize))).then((_) { if (mounted) setState(() {}); }));
                  }
                  if (regClosed) return _buildActionBtnOutlined(label: "Registration Closed", icon: Icons.lock_outline, color: Colors.grey, onTap: () {});
                  return Row(children: [
                    Expanded(child: _buildActionBtnOutlined(label: "Create Team", icon: Icons.add_circle_outline, color: _purple, onTap: regNotStarted ? () {} : () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTeamPostScreen(hackathonId: hid, hackathonTeamSize: h.teamSize))).then((_) { if (mounted) setState(() {}); }))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildActionBtnOutlined(label: "Join Team", icon: Icons.person_add_alt_1_outlined, color: _purple, onTap: regNotStarted ? () {} : () => Navigator.push(context, MaterialPageRoute(builder: (context) => teams_view.ExploreTeamsView(hackathonId: hid, hackathonTeamSize: h.teamSize))).then((_) { if (mounted) setState(() {}); }))),
                  ]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalTeamMiniCard(TeamPostModel team, Hackathon hackathon, bool isSubmitted) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final bool isLeader = team.createdBy == currentUid;

    // ✅ ألوان مميزة لحالة التسجيل (مستقلة تماماً عن ألوان الأدوار)
    String statusText;
    Color statusColor;

    if (!isSubmitted) {
      statusText = "Not Registered";
      statusColor = Colors.grey.shade600; // رمادي
    } else {
      if (team.status == 'accepted') {
        statusText = "Accepted Registration";
        statusColor = Colors.green.shade600; // أخضر
      } else if (team.status == 'rejected') {
        statusText = "Rejected Registration";
        statusColor = Colors.red.shade600; // أحمر
      } else {
        statusText = "Pending Registration";
        statusColor = Colors.blue.shade600; // أزرق صريح للانتظار
      }
    }

    return Container(
      width: 300, margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 1. اسم الفريق ياخذ راحته فوق بدون ما يزاحمه أي شيء
              Text("Team Name", style: TextStyle(fontWeight: FontWeight.bold, color: _purple.withOpacity(0.8), fontSize: 10)),
              Text(
                team.teamName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.2),
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12), // مسافة بسيطة لترتيب العين

              // ✅ 2. استخدام Wrap لترتيب الحالات (Tags) تحت الاسم بشكل أنيق ومستقر
              Wrap(
                spacing: 8, // المسافة الأفقية بين التاقات
                runSpacing: 8, // المسافة العمودية إذا كان النص طويل ونزلوا سطر جديد
                children: [
                  _miniStatusBadge(isLeader ? "Team Leader" : "Team Member", isLeader ? Colors.orange.shade700 : _purple),
                  _miniStatusBadge(statusText, statusColor),
                ],
              ),

              const Divider(height: 20),
              _compactInfoRow(Icons.emoji_events_outlined, hackathon.name),
              const SizedBox(height: 8),
              _compactInfoRow(Icons.group_outlined, "${team.members.length} / ${hackathon.teamSize} Members"),
              const SizedBox(height: 8),
              _compactInfoRow(Icons.event_outlined, "Event: ${hackathon.startDate.day} ${_getMonthName(hackathon.startDate.month)}"),

              const Spacer(), // يضمن نزول الزر للأسفل وتوحيد المحاذاة لكل الكروت

              _buildActionBtnOutlined(
                  label: isLeader ? "Manage My Team" : "View My Team",
                  icon: isLeader ? Icons.edit_note_rounded : Icons.visibility_outlined,
                  color: _purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyTeamPostView(teamPostId: team.id ?? "", hackathonId: hackathon.id ?? "", hackathonTeamSize: hackathon.teamSize))).then((_) { if (mounted) setState(() {}); })
              ),
            ]),
      ),
    );
  }

  // ─── الدوال المساعدة (Helper Methods) ───
  Widget _buildActionBtnOutlined({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(height: 38, width: double.infinity, child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 14), label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.zero)));
  }

  Widget _compactInfoRow(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 14, color: _purple), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis))]);
  }

  Widget _miniStatusBadge(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)));
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildEmptyTeamsState() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(40), width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)), child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.group_off_outlined, color: Colors.grey, size: 40), SizedBox(height: 12), Text("You haven't registered or created any team yet.", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center)]));
  }
}

class _UserSection extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onExploreTap;
  final Widget child;
  const _UserSection({super.key, required this.title, required this.actionLabel, required this.onExploreTap, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), GestureDetector(onTap: onExploreTap, child: Text(actionLabel, style: const TextStyle(color: Color(0xFFFFA726), fontSize: 12)))])),
      const SizedBox(height: 12),
      child,
    ]);
  }
}