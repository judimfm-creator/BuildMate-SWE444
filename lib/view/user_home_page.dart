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
import '../../home_screen.dart'; // لتفعيل homeScreenState

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

    // ننقل اليوزر لصفحة الاكسبلور
    homeScreenState?.changeTab(1);

    // نأخر الأمر شوي عشان الشاشة تلحق تظهر
    Future.delayed(const Duration(milliseconds: 100), () {
      exploreTabStream.add(tabIndex);
    });
  }

  // دالة البحث عن الفريق (تستخدم في الـ FutureBuilder)
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
              title: "Hackathons 🚀",
              actionLabel: "View all hackathons",
              onExploreTap: () => _navigateToExplore(0),
              child: _buildHackathonsList(),
            ),
            const SizedBox(height: 30),
            _UserSection(
              key: _teamsKey,
              title: "My Teams 👥",
              actionLabel: "View all teams",
              onExploreTap: () => _navigateToExplore(1),
              child: _buildTeamsList(), // ✅ تم التعديل هنا
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ─── دوال بناء قائمة وكروت الفرق ───

  Widget _buildTeamsList() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) return _buildEmptyTeamsState();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('team_posts')
          .where('members', arrayContains: currentUid) // يجيب فرق اليوزر
          .snapshots()
          .asyncMap((snapshot) async {

        final futures = snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          final team = TeamPostModel.fromMap(doc.id, data);

          final hackathonDoc = await FirebaseFirestore.instance
              .collection('hackathons')
              .doc(team.hackathonId)
              .get();

          Hackathon? hackathon;
          if (hackathonDoc.exists) {
            hackathon = Hackathon.fromFirestore(hackathonDoc);
          }

          return {'team': team, 'hackathon': hackathon};
        });

        var results = await Future.wait(futures);
        results.sort((a, b) {
          final tA = a['team'] as TeamPostModel;
          final tB = b['team'] as TeamPostModel;
          return tB.createdAt.compareTo(tA.createdAt);
        });

        return results;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator(color: _purple)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyTeamsState();
        }

        // ✅ هنا ضفنا الشروط المنطقية الجديدة (Business Logic)
        final now = DateTime.now();
        var list = snapshot.data!.where((item) {
          final team = item['team'] as TeamPostModel;
          final h = item['hackathon'] as Hackathon?;

          if (h == null) return false; // إذا الهاكاثون محذوف نخفي الفريق

          final bool isFull = team.members.length >= h.teamSize;
          final bool registrationClosed = now.isAfter(h.applicationDeadline);
          final bool hackathonEnded = now.isAfter(h.endDate);

          // 1. لو الفريق "ما اكتمل" و "التسجيل انتهى" -> إخفاء
          if (!isFull && registrationClosed) return false;

          // 2. لو الفريق "مكتمل" و "الهاكاثون بكبره انتهى" -> إخفاء
          if (isFull && hackathonEnded) return false;

          // غير كذا، اعرض الفريق
          return true;
        }).toList();

        if (list.isEmpty) {
          return _buildEmptyTeamsState();
        }

        return SizedBox(
          height: 265,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: list.length > 10 ? 10 : list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildProfessionalTeamMiniCard(item['team'], item['hackathon']);
            },
          ),
        );
      },
    );
  }

  Widget _buildProfessionalTeamMiniCard(TeamPostModel team, Hackathon hackathon) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final bool isLeader = team.createdBy == currentUid;

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
                      Text("Team Name",
                          style: TextStyle(fontWeight: FontWeight.bold, color: _purple.withOpacity(0.8), fontSize: 10)),
                      Text(team.teamName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // ✅ توضيح دور اليوزر في فريقه
                _miniStatusBadge(isLeader ? "Team Leader" : "Team Member", isLeader ? Colors.orange : _purple),
              ],
            ),
            const Divider(height: 20),

            _compactInfoRow(Icons.emoji_events_outlined, hackathon.name),
            const SizedBox(height: 8),
            _compactInfoRow(Icons.group_outlined, "${team.members.length} / ${hackathon.teamSize} Members"),
            const SizedBox(height: 8),
            _compactInfoRow(Icons.event_outlined, "Event: ${hackathon.startDate.day} ${_getMonthName(hackathon.startDate.month)}"),

            const SizedBox(height: 16),

            // ✅ الزر يودي لصفحة إدارة الفريق
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => MyTeamPostView(
                            teamPostId: team.id ?? "",
                            hackathonId: hackathon.id ?? "",
                            hackathonTeamSize: hackathon.teamSize,
                          ),
                        )).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      child: Text(isLeader ? "Manage Team" : "View Team", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHackathonsList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('hackathons').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
        return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator(color: _purple)));
      }

      final now = DateTime.now();
      final all = snapshot.data?.docs.map((doc) => Hackathon.fromFirestore(doc)).toList() ?? [];

      // نحدد "الفرص الأخيرة" (تنتهي خلال 48 ساعة)
      final hotList = all.where((h) {
        final diff = h.applicationDeadline.difference(now).inHours;
        return diff <= 48 && diff >= 0;
      }).toList();

      bool isHot = hotList.isNotEmpty;
      final displayList = isHot ? hotList : all.take(3).toList();

      if (displayList.isEmpty) return _buildEmptyHackathonsState();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHot ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isHot ? Icons.timer : Icons.star, size: 12, color: isHot ? Colors.red : Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    isHot ? "LAST CALL: CLOSING SOON" : "FEATURED HACKATHONS",
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      color: isHot ? Colors.red : Colors.blue
                    ),
                  ),
                ],
              ),
            ),
          ),
          // قائمة الكروت...
          SizedBox(
            height: 350,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: displayList.length,
              itemBuilder: (context, index) => _buildProfessionalMiniCard(displayList[index]),
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildProfessionalMiniCard(Hackathon h) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String hid = h.id ?? ""; 

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
                      Text("Registration Deadline:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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

            // زر التفاصيل الأساسي
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

            // ─── منطق الأزرار الذكي مع ميزة التحديث التلقائي ───
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
                        ))).then((_) {
                           if (mounted) setState(() {}); // تحديث الصفحة عند العودة
                        }); 
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
                            Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTeamPostScreen(
                              hackathonId: hid, 
                              hackathonTeamSize: h.teamSize
                            ))).then((_) {
                               if (mounted) setState(() {}); // تحديث الصفحة فور العودة من الإنشاء
                            });
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
                            Navigator.push(context, MaterialPageRoute(builder: (context) => teams_view.ExploreTeamsView(
                              hackathonId: hid, 
                              hackathonTeamSize: h.teamSize
                            ))).then((_) {
                               if (mounted) setState(() {}); // تحديث الصفحة عند العودة من الانضمام
                            });
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
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off_outlined, color: Colors.grey, size: 40),
          SizedBox(height: 12),
          Text(
            "You haven't registered or created any team yet.",
            style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} // ✅✅✅ هذا هو القوس اللي كان ناقص! (يُغلق كلاس _UserHomePageState) ✅✅✅

class _UserSection extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onExploreTap;
  final Widget child;

  const _UserSection({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onExploreTap,
    required this.child
  });

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
              GestureDetector(
                  onTap: onExploreTap,
                  child: Text(actionLabel, style: const TextStyle(color: Color(0xFFFFA726), fontSize: 12))
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}