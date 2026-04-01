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
import '../model/team_post_model.dart';
import 'team_post_details_view.dart';
import 'dart:async'; 
import '../../home_screen.dart'; 

// 1. المتغيرات العامة
int targetExploreTab = 0;
final StreamController<int> exploreTabStream = StreamController<int>.broadcast();

class ExploreUserView extends StatefulWidget {
  final int initialTabIndex;
  const ExploreUserView({super.key, this.initialTabIndex = 0});

  @override
  State<ExploreUserView> createState() => _ExploreUserViewState();
}

class _ExploreUserViewState extends State<ExploreUserView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription<int> _tabSubscription;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBg = Color(0xFFF0EEFF);
  static const Color _screenBg = Color(0xFFF8F9FD);

  String? selectedMode;
  String? selectedStatus;
  String? selectedEducation;
  DateTime? selectedEndRegDate;
  DateTime? selectedStartEventDate;
  DateTime? selectedEndEventDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: targetExploreTab);

    _tabSubscription = exploreTabStream.stream.listen((index) {
      if (mounted && _tabController.index != index) {
        _tabController.animateTo(index);
      }
    });
  }

  @override
  void dispose() {
    _tabSubscription.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String _format(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

  bool isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  void _clearAllFilters() {
    setState(() {
      _cityController.clear();
      selectedMode = null;
      selectedStatus = null;
      selectedEducation = null;
      selectedEndRegDate = null;
      selectedStartEventDate = null;
      selectedEndEventDate = null;
    });
  }

  bool _hasActiveFilters() =>
      _cityController.text.isNotEmpty ||
      selectedMode != null ||
      selectedStatus != null ||
      selectedEndRegDate != null ||
      selectedStartEventDate != null ||
      selectedEndEventDate != null;

  Widget _buildClearFilterButton() {
    return Container(
      height: 45, width: 45,
      decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)
      ),
      child: IconButton(
        icon: const Icon(Icons.filter_alt_off, color: Colors.red, size: 20),
        onPressed: _clearAllFilters,
        tooltip: "Clear Filters",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrgHackathonsViewModel>();

    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(child: _buildSearchBar(vm)),
              if (_hasActiveFilters()) ...[
                const SizedBox(width: 8),
                _buildClearFilterButton(),
              ],
              const SizedBox(width: 8),
              _buildFilterButton(),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            child: TabBar(
              controller: _tabController,
              indicatorColor: _purple,
              indicatorWeight: 3,
              labelColor: _purple,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [Tab(text: "Hackathons"), Tab(text: "Teams")],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHackathonList(),
          _buildTeamsList(),
        ],
      ),
    );
  }

  Widget _buildHackathonList() {
    final vm = context.watch<OrgHackathonsViewModel>();
    return RefreshIndicator(
      color: _purple,
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(seconds: 1));
      },
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Hackathon>>(
              stream: vm.filteredHackathonsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _purple));
                }
                var list = snapshot.data ?? [];
                final now = DateTime.now();

                list = list.where((h) {
                  bool mCity = _cityController.text.isEmpty ||
                      h.city.toLowerCase().contains(_cityController.text.toLowerCase());
                  bool mMode = selectedMode == null || h.mode == selectedMode;
                  bool mEdu = selectedEducation == null || (h.educationCriteria ?? "Any") == selectedEducation;

                  bool mStatus = true;
                  if (selectedStatus != null) {
                    final hEndOfDeadline = DateTime(h.applicationDeadline.year, h.applicationDeadline.month, h.applicationDeadline.day, 23, 59, 59);
                    if (selectedStatus == "Registration Upcoming Soon") {
                      mStatus = now.isBefore(h.applicationOpenDate);
                    } else if (selectedStatus == "Registration Open") {
                      mStatus = now.isAfter(h.applicationOpenDate) && now.isBefore(hEndOfDeadline);
                    } else if (selectedStatus == "Registration Closed") {
                      mStatus = now.isAfter(hEndOfDeadline);
                    }
                  }

                  bool mEvStart = selectedStartEventDate == null || isSameDay(h.startDate, selectedStartEventDate!);
                  bool mEvEnd = selectedEndEventDate == null || isSameDay(h.endDate, selectedEndEventDate!);
                  bool mDeadline = selectedEndRegDate == null || isSameDay(h.applicationDeadline, selectedEndRegDate!);

                  return mCity && mMode && mStatus && mEdu && mEvStart && mEvEnd && mDeadline;
                }).toList();

                if (list.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("No results found.")));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _buildPremiumHackathonCard(list[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsList() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('team_posts')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final userTeamsSnapshot = await FirebaseFirestore.instance
            .collection('team_posts')
            .where('members', arrayContains: currentUid)
            .get();

        final joinedHackathonIds = userTeamsSnapshot.docs
            .map((doc) => doc.data()['hackathonId'] as String?)
            .where((id) => id != null)
            .toSet();

        final futures = snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          final team = TeamPostModel.fromMap(doc.id, data);
          if (joinedHackathonIds.contains(team.hackathonId)) return null;

          final hackathonDoc = await FirebaseFirestore.instance.collection('hackathons').doc(team.hackathonId).get();
          if (!hackathonDoc.exists) return null;
          final hackathon = Hackathon.fromFirestore(hackathonDoc);
          if (team.members.length >= hackathon.teamSize) return null;

          final teamEndOfDeadline = DateTime(hackathon.applicationDeadline.year, hackathon.applicationDeadline.month, hackathon.applicationDeadline.day, 23, 59, 59);
          if (DateTime.now().isAfter(teamEndOfDeadline)) return null;

          return {'team': team, 'hackathon': hackathon, 'hackathonName': hackathon.name};
        });

        final results = await Future.wait(futures);
        return results.where((item) => item != null).cast<Map<String, dynamic>>().toList();
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("No teams available right now.")));
        }

        final now = DateTime.now();
        var list = snapshot.data!.where((item) {
          final team = item['team'] as TeamPostModel;
          final h = item['hackathon'] as Hackathon?;
          final hName = item['hackathonName'] as String;
          if (h == null) return false;

          bool mSearch = _searchController.text.isEmpty ||
              team.teamName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              hName.toLowerCase().contains(_searchController.text.toLowerCase());
          bool mCity = _cityController.text.isEmpty || h.city.toLowerCase().contains(_cityController.text.toLowerCase());
          bool mMode = selectedMode == null || h.mode == selectedMode;
          bool mEdu = selectedEducation == null || h.educationCriteria == selectedEducation;
          
          bool mStatus = true;
          if (selectedStatus != null) {
            if (selectedStatus == "Registration Upcoming Soon") mStatus = now.isBefore(h.applicationOpenDate);
            else if (selectedStatus == "Registration Open") mStatus = now.isAfter(h.applicationOpenDate) && now.isBefore(h.applicationDeadline);
            else if (selectedStatus == "Registration Closed") mStatus = now.isAfter(h.applicationDeadline);
          }

          return mSearch && mCity && mMode && mEdu && mStatus;
        }).toList();

        if (list.isEmpty) return const Center(child: Text("No teams match your filters."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return _buildTeamCard(item['team'], item['hackathon'], item['hackathonName']);
          },
        );
      },
    );
  }

  Widget _buildPremiumHackathonCard(Hackathon h) {
    final DateTime now = DateTime.now();
    final bool regNotStarted = now.isBefore(h.applicationOpenDate);
    final endOfDeadline = DateTime(h.applicationDeadline.year, h.applicationDeadline.month, h.applicationDeadline.day, 23, 59, 59);
    final bool regClosed = now.isAfter(endOfDeadline);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("By ${h.organizationName ?? "Organizer"}", style: TextStyle(fontWeight: FontWeight.w600, color: _purple.withOpacity(0.7), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(h.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ])),
                _statusBadge(regNotStarted, h.applicationDeadline),
              ],
            ),
            const Divider(height: 25),
            _buildInfoRow(Icons.category_outlined, "Domain", h.domain),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, "Location", "${h.city}, ${h.mode}"),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.groups_outlined, "Team Size", h.teamSize > 2 ? "2 - ${h.teamSize} members" : "2 members"),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _lightBg.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _dateRow("Registration Starts", _format(h.applicationOpenDate), "Registration Deadline", _format(h.applicationDeadline), isDeadline: true),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(color: Colors.white)),
                _dateRow("Event Starts", _format(h.startDate), "Event Ends", _format(h.endDate)),
              ]),
            ),
            const SizedBox(height: 15),
            _btn("View Full Details", _purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => HackathonDetailsView(hackathon: h)));
            }),
            const SizedBox(height: 10),
            if (currentUid != null)
              FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
                future: _getUserTeamPost(currentUid, h.id ?? ""),
                builder: (context, teamSnap) {
                  if (teamSnap.connectionState == ConnectionState.waiting) return const SizedBox();
                  if (teamSnap.hasData && teamSnap.data != null) {
                    final bool isOwner = teamSnap.data!.data()['createdBy'] == currentUid;
                    return _outlinedBtn(isOwner ? "Manage My Team" : "View My Team", _purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MyTeamPostView(
                        teamPostId: teamSnap.data!.id,
                        hackathonId: h.id ?? "",
                        hackathonTeamSize: h.teamSize))).then((_) { if (mounted) setState(() {}); });
                    });
                  }
                  return Row(
                    children: [
                      if (regClosed) Expanded(child: _outlinedBtn("Registration Closed", Colors.grey, null))
                      else if (regNotStarted) Expanded(child: _outlinedBtn("Registration Upcoming Soon", Colors.grey, null))
                      else ...[
                        Expanded(child: _outlinedBtn("Create Team", _purple, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTeamPostScreen(hackathonId: h.id ?? "", hackathonTeamSize: h.teamSize)))
                          .then((dynamic result) async {
                            if (result == true && mounted) {
                              await Future.delayed(const Duration(milliseconds: 500));
                              if (mounted) {
                                setState(() {});
                                homeScreenState?.changeTab(0);
                              }
                            }
                          });
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _outlinedBtn("Join Team", _purple, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => teams_view.ExploreTeamsView(hackathonId: h.id ?? "", hackathonTeamSize: h.teamSize)))
                          .then((dynamic result) async {
                            if (result == true && mounted) {
                              await Future.delayed(const Duration(milliseconds: 500));
                              if (mounted) {
                                setState(() {});
                                homeScreenState?.changeTab(0);
                              }
                            }
                          });
                        })),
                      ]
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(TeamPostModel team, Hackathon? hackathon, String hackathonName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Team Name", style: TextStyle(fontWeight: FontWeight.w600, color: _purple.withOpacity(0.7), fontSize: 11)),
              const SizedBox(height: 4),
              Text(team.teamName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text("Looking for Members", style: TextStyle(color: _purple, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ]),
          const Divider(height: 25),
          _buildInfoRow(Icons.emoji_events_outlined, "Hackathon", hackathonName),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person_outline, "Leader's Role", team.myRole),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.wc_outlined, "Gender Preference", team.genderPreference),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _outlinedBtn("Full Details", _purple, () {
              if (hackathon != null) Navigator.push(context, MaterialPageRoute(builder: (context) => TeamPostDetailsView(team: team, hackathon: hackathon)));
            })),
            const SizedBox(width: 12),
            Expanded(child: _btn("Join Team", _purple, () {
              if (hackathon != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => teams_view.ExploreTeamsView(hackathonId: hackathon.id ?? "", hackathonTeamSize: hackathon.teamSize)))
                .then((dynamic result) async {
                  if (result == true && mounted) {
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) {
                      setState(() {});
                      homeScreenState?.changeTab(0);
                    }
                  }
                });
              }
            })),
          ]),
        ]),
      ),
    );
  }

  // الدوال المساعدة (Helper Methods) بقيت كما هي لضمان عدم حذف أي عمل
  Widget _buildSearchBar(OrgHackathonsViewModel vm) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search hackathons,orgs,teams...",
        prefixIcon: const Icon(Icons.search, color: _purple),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      onChanged: (value) => setState(() => vm.updateSearchQuery(value)),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      height: 45, width: 45,
      decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: const Icon(Icons.tune, color: _purple), onPressed: () => _showFilterDialog(context)),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Filters"),
      content: const Text("Filter options here..."),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
    ));
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getUserTeamPost(String uid, String hid) async {
    final firestore = FirebaseFirestore.instance;
    final leader = await firestore.collection('team_posts').where('hackathonId', isEqualTo: hid).where('createdBy', isEqualTo: uid).limit(1).get();
    if (leader.docs.isNotEmpty) return leader.docs.first;
    final member = await firestore.collection('team_posts').where('hackathonId', isEqualTo: hid).where('members', arrayContains: uid).limit(1).get();
    if (member.docs.isNotEmpty) return member.docs.first;
    return null;
  }

  Widget _btn(String label, Color color, VoidCallback? onTap) {
    return SizedBox(width: double.infinity, height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap, child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _outlinedBtn(String label, Color color, VoidCallback? onTap) {
    return SizedBox(width: double.infinity, height: 42,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap, child: Text(label),
      ),
    );
  }

  Widget _statusBadge(bool ns, DateTime deadline) {
    final now = DateTime.now();
    final endOfDeadline = DateTime(deadline.year, deadline.month, deadline.day, 23, 59, 59);
    final bool cl = now.isAfter(endOfDeadline);
    Color c = cl ? Colors.red : (ns ? Colors.orange : Colors.green);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(cl ? "CLOSED" : (ns ? "UPCOMING" : "OPEN"), style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, size: 16, color: _purple), const SizedBox(width: 8), Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Expanded(child: Text(value, style: const TextStyle(fontSize: 12)))]);
  }

  Widget _dateRow(String l1, String d1, String l2, String d2, {bool isDeadline = false}) {
    return Row(children: [Expanded(child: _dateItem(l1, d1)), Container(width: 1, height: 18, color: _purple.withOpacity(0.2)), const SizedBox(width: 12), Expanded(child: _dateItem(l2, d2, isCritical: isDeadline))]);
  }

  Widget _dateItem(String label, String date, {bool isCritical = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)), Text(date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCritical ? Colors.redAccent : Colors.black))]);
  }
}