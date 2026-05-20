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
import 'package:onesignal_flutter/onesignal_flutter.dart';

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
  static const Color _screenBg = Colors.white;

  String? selectedMode;
  List<String> selectedStatuses = [];
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
  bool isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  void _clearAllFilters() {
    setState(() {
      _cityController.clear();
      _searchController.clear();
      selectedMode = null;
      selectedStatuses = [];
      selectedEducation = null;
      selectedEndRegDate = null;
      selectedStartEventDate = null;
      selectedEndEventDate = null;
      context.read<OrgHackathonsViewModel>().updateSearchQuery("");
    });
  }

  bool _hasActiveFilters() =>
      _cityController.text.isNotEmpty ||
          selectedMode != null ||
          selectedStatuses.isNotEmpty ||
          selectedEndRegDate != null ||
          selectedStartEventDate != null ||
          selectedEndEventDate != null;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrgHackathonsViewModel>();
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: _purple),
        titleSpacing: 0,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
          child: Row(children: [
            Expanded(child: _buildSearchBar(vm)),
            if (_hasActiveFilters()) ...[
              const SizedBox(width: 8), 
              _buildClearFilterButton()
            ],
            const SizedBox(width: 8),
            _buildFilterButton(), 
          ]),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: _purple,
                  indicatorWeight: 3,
                  labelColor: _purple,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: "Hackathons"),
                    Tab(text: "Teams"),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHackathonList(), _buildTeamsList()],
      ),
    );
  }


  Future<void> _confirmWithdraw(String requestId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Withdraw Request", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to withdraw your join request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Withdraw", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('join_requests').doc(requestId).delete();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Join request withdrawn successfully"), backgroundColor: Colors.green),
        );
      }
    }
  }

  Widget _buildHackathonList() {
    final vm = context.watch<OrgHackathonsViewModel>();
    return RefreshIndicator(
      color: _purple,
      onRefresh: () async { setState(() {}); await Future.delayed(const Duration(seconds: 1)); },
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Hackathon>>(
              stream: vm.filteredHackathonsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _purple));
                var list = snapshot.data ?? [];
                final now = DateTime.now();

                list = list.where((h) {
                  bool mCity = _cityController.text.isEmpty || h.city.toLowerCase().contains(_cityController.text.toLowerCase());
                  bool mMode = selectedMode == null || h.mode == selectedMode;
                  bool mEdu = selectedEducation == null || (h.educationCriteria ?? "Any") == selectedEducation;
                  final hEndOfDeadline = DateTime(h.applicationDeadline.year, h.applicationDeadline.month, h.applicationDeadline.day, 23, 59, 59);
                  String currentHStatus = "";
                  if (now.isBefore(h.applicationOpenDate)) {
                    currentHStatus = "Registration Upcoming Soon";
                  } else if (now.isAfter(h.applicationOpenDate) && now.isBefore(hEndOfDeadline)) {
                    currentHStatus = "Registration Open";
                  } else {
                    currentHStatus = "Registration Closed";
                  }
                  bool mStatus = selectedStatuses.isEmpty || selectedStatuses.contains(currentHStatus);

                  bool mEvStart = selectedStartEventDate == null || isSameDay(h.startDate, selectedStartEventDate!);
                  bool mEvEnd = selectedEndEventDate == null || isSameDay(h.endDate, selectedEndEventDate!);
                  bool mDeadline = selectedEndRegDate == null || isSameDay(h.applicationDeadline, selectedEndRegDate!);

                  return mCity && mMode && mStatus && mEdu && mEvStart && mEvEnd && mDeadline;
                }).toList();

                if (list.isEmpty) return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("No results found.")));
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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

  Widget _buildPremiumHackathonCard(Hackathon h) {
    final DateTime now = DateTime.now();
    final bool regNotStarted = now.isBefore(h.applicationOpenDate);
    final endOfDeadline = DateTime(h.applicationDeadline.year, h.applicationDeadline.month, h.applicationDeadline.day, 23, 59, 59);
    final bool regClosed = now.isAfter(endOfDeadline);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purple.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "By ${h.organizationName ?? "Organizer"}",
                style: TextStyle(fontWeight: FontWeight.bold, color: _purple.withOpacity(0.8), fontSize: 10, letterSpacing: 0.5),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(h.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ])),
            _statusBadge(regNotStarted, h.applicationDeadline),
          ]),
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
          
          _btn("View Full Details", _purple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => HackathonDetailsView(hackathon: h)))),
          const SizedBox(height: 10),

          if (currentUid != null)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('team_posts')
                  .where('hackathonId', isEqualTo: h.id)
                  .where('members', arrayContains: currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 42);

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final teamDoc = snapshot.data!.docs.first;
                  final bool isOwner = teamDoc.data()['createdBy'] == currentUid;

                  return _outlinedBtn(
                    isOwner ? "Manage My Team" : "View My Team",
                    _purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyTeamPostView(
                            teamPostId: teamDoc.id,
                            hackathonId: h.id ?? "",
                            hackathonTeamSize: h.teamSize,
                          ),
                        ),
                      ).then((_) { if (mounted) setState(() {}); });
                    },
                  );
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('join_requests')
                      .where('hackathonId', isEqualTo: h.id)
                      .where('requesterId', isEqualTo: currentUid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, requestSnapshot) {
                    final bool hasPendingRequest = requestSnapshot.hasData && requestSnapshot.data!.docs.isNotEmpty;

                    if (regClosed) return _outlinedBtn("Registration Closed", Colors.grey, null);
                    if (regNotStarted) return _outlinedBtn("Registration Upcoming Soon", Colors.grey, null);

                    if (hasPendingRequest) {
                      final requestId = requestSnapshot.data!.docs.first.id;
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Text(
                              "You have a pending join request for this hackathon.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _outlinedBtn(
                            "Withdraw Join Request",
                            Colors.deepOrange.shade400,
                            () => _confirmWithdraw(requestId),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _outlinedBtn(
                            "Create Team",
                            _purple,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateTeamPostScreen(
                                    hackathonId: h.id ?? "",
                                    hackathonTeamSize: h.teamSize,
                                  ),
                                ),
                              ).then((dynamic res) async {
                                if (res == true && mounted) {
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  homeScreenState?.changeTab(0);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _outlinedBtn(
                            "Join Team",
                            _purple,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => teams_view.ExploreTeamsView(
                                    hackathonId: h.id ?? "",
                                    hackathonTeamSize: h.teamSize,
                                  ),
                                ),
                              ).then((dynamic res) async {
                                if (res == true && mounted) {
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  homeScreenState?.changeTab(0);
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ]),
      ),
    );
  }

Future<List<Map<String, dynamic>>> _buildFilteredTeams(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      String currentUid,
      Set<String> pendingHackathonIds,
      ) async {
    
    final userTeamsSnapshot = await FirebaseFirestore.instance
        .collection('team_posts')
        .where('members', arrayContains: currentUid)
        .get();

    final joinedIds = userTeamsSnapshot.docs
        .map((doc) => doc.data()['hackathonId'] as String?)
        .whereType<String>()
        .toSet();

    final pendingRequestsQuery = await FirebaseFirestore.instance
        .collection('join_requests')
        .where('requesterId', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .get();
    
    Map<String, String> pendingHackathonToTeam = {};
    for (var doc in pendingRequestsQuery.docs) {
      pendingHackathonToTeam[doc['hackathonId']] = doc['teamPostId'];
    }

    final futures = docs.map((doc) async {
      final data = doc.data();
      final team = TeamPostModel.fromMap(doc.id, data);


      if (joinedIds.contains(team.hackathonId)) return null;
      if (team.createdBy == currentUid) return null;


      if (pendingHackathonToTeam.containsKey(team.hackathonId)) {
        if (team.id != pendingHackathonToTeam[team.hackathonId]) {
          return null;
        }
      }

      final hDoc = await FirebaseFirestore.instance.collection('hackathons').doc(team.hackathonId).get();
      if (!hDoc.exists) return null;

      final h = Hackathon.fromFirestore(hDoc);


      if (team.members.length >= h.teamSize || data['status'] == 'registered') {
        return null;
      }

      final teamDeadline = DateTime(h.applicationDeadline.year, h.applicationDeadline.month, h.applicationDeadline.day, 23, 59, 59);
      if (DateTime.now().isAfter(teamDeadline)) return null;

      return {
        'team': team,
        'hackathon': h,
        'hackathonName': h.name,
        'isPending': pendingHackathonToTeam.containsKey(team.hackathonId),
      };
    });

    final results = await Future.wait(futures);
    return results.where((item) => item != null).cast<Map<String, dynamic>>().toList();
  }

  Widget _buildTeamsList() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('join_requests')
          .where('requesterId', isEqualTo: currentUid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, requestSnapshot) {
        if (requestSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _purple));

        final pendingHackathonIds = requestSnapshot.data?.docs
            .map((doc) => doc.data()['hackathonId'] as String?)
            .whereType<String>()
            .toSet() ?? <String>{};

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('team_posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, teamSnapshot) {
            if (teamSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _purple));

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _buildFilteredTeams(teamSnapshot.data!.docs, currentUid, pendingHackathonIds),
              builder: (context, filteredSnapshot) {
                if (filteredSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _purple));

                final now = DateTime.now();
                var list = filteredSnapshot.data ?? [];

                list = list.where((item) {
                  final team = item['team'] as TeamPostModel;
                  final h = item['hackathon'] as Hackathon?;
                  final hName = item['hackathonName'] as String;
                  if (h == null) return false;

                  bool mSearch = _searchController.text.isEmpty || team.teamName.toLowerCase().contains(_searchController.text.toLowerCase()) || hName.toLowerCase().contains(_searchController.text.toLowerCase());
                  bool mCity = _cityController.text.isEmpty || h.city.toLowerCase().contains(_cityController.text.toLowerCase());
                  bool mMode = selectedMode == null || h.mode == selectedMode;
                  bool mEdu = selectedEducation == null || h.educationCriteria == selectedEducation;
                  
                  final hEndOfDeadline = DateTime(h.applicationDeadline.year, h.applicationDeadline.month, h.applicationDeadline.day, 23, 59, 59);
                  String currentHStatus = "";
                  if (now.isBefore(h.applicationOpenDate)) currentHStatus = "Registration Upcoming Soon";
                  else if (now.isAfter(h.applicationOpenDate) && now.isBefore(hEndOfDeadline)) currentHStatus = "Registration Open";
                  else currentHStatus = "Registration Closed";

                  bool mStatus = selectedStatuses.isEmpty || selectedStatuses.contains(currentHStatus);
                  bool mEvStart = selectedStartEventDate == null || isSameDay(h.startDate, selectedStartEventDate!);
                  bool mEvEnd = selectedEndEventDate == null || isSameDay(h.endDate, selectedEndEventDate!);
                  bool mDeadline = selectedEndRegDate == null || isSameDay(h.applicationDeadline, selectedEndRegDate!);

                  return mSearch && mCity && mMode && mEdu && mStatus && mEvStart && mEvEnd && mDeadline;
                }).toList();

                if (list.isEmpty) return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("No teams available right now.")));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildTeamCard(
                      item['team'], 
                      item['hackathon'], 
                      item['hackathonName'], 
                      isPending: item['isPending'] ?? false
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTeamCard(TeamPostModel team, Hackathon? hackathon, String hackathonName, {bool isPending = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purple.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
        ],
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
              decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), 
              child: const Text("Looking for Members", style: TextStyle(color: _purple, fontSize: 8, fontWeight: FontWeight.bold))
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
            Expanded(child: _outlinedBtn("Full Details", _purple, () { if (hackathon != null) Navigator.push(context, MaterialPageRoute(builder: (c) => TeamPostDetailsView(team: team, hackathon: hackathon))); })),
            const SizedBox(width: 12),
            Expanded(child: isPending 
              ? _outlinedBtn("Withdraw Request", Colors.deepOrange.shade400, () async {
                  final q = await FirebaseFirestore.instance.collection('join_requests')
                      .where('requesterId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .where('teamPostId', isEqualTo: team.id)
                      .get();
                  if (q.docs.isNotEmpty) {
                    _confirmWithdraw(q.docs.first.id);
                  }
                })
              : _btn("Join Team", _purple, () {
                  if (hackathon != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => teams_view.ExploreTeamsView(
                          hackathonId: hackathon.id ?? "",
                          hackathonTeamSize: hackathon.teamSize,
                          teamId: team.id,
                        )
                      )
                    ).then((dynamic res) async {
                      if (res == true && mounted) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        setState(() {});
                        homeScreenState?.changeTab(0);
                      }
                    });
                  }
                })
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildSearchBar(OrgHackathonsViewModel vm) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search hackathons,orgs,domain,team", hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        prefixIcon: const Icon(Icons.search, color: _purple, size: 20),
        suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.cancel, color: Colors.grey, size: 16), onPressed: () { vm.updateSearchQuery(""); _searchController.clear(); setState(() {}); }) : null,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: _purple, width: 1.2)),
      ),
      onChanged: (value) { vm.updateSearchQuery(value); setState(() {}); },
    );
  }

  Widget _buildFilterButton() {
    return Container(height: 45, width: 45, decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: const Icon(Icons.tune, color: _purple, size: 20), onPressed: () => _showFilterDialog(context)),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Filters", style: TextStyle(fontWeight: FontWeight.bold, color: _purple, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _filterSectionTitle("Location"),
        TextField(controller: _cityController, decoration: const InputDecoration(hintText: "City Name", prefixIcon: Icon(Icons.location_city, size: 18))),
        const SizedBox(height: 15),
        _filterSectionTitle("Attendance Mode"),
        DropdownButtonFormField<String>(
          value: selectedMode, hint: const Text("Select Mode"),
          items: ["Onsite", "Online", "Hybrid"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) => setDialogState(() => selectedMode = val),
        ),
        const SizedBox(height: 15),
        _filterSectionTitle("Event Dates"),
        _dateTile(context, "Event Start Date", selectedStartEventDate, (d) => setDialogState(() => selectedStartEventDate = d)),
        _dateTile(context, "Event End Date", selectedEndEventDate, (d) => setDialogState(() => selectedEndEventDate = d)),
        const SizedBox(height: 15),
        _filterSectionTitle("Education Criteria"),
        DropdownButtonFormField<String>(
          value: selectedEducation, hint: const Text("Select Level"),
          items: ["Any", "University Students", "High School", "Professionals"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setDialogState(() => selectedEducation = val),
        ),
        const SizedBox(height: 15),
        _filterSectionTitle("Status"),
        Wrap(
          spacing: 5,
          children: ["Registration Upcoming Soon", "Registration Open", "Registration Closed"].map((s) {
            final isSelected = selectedStatuses.contains(s);
            return ChoiceChip(
              label: Text(s, style: const TextStyle(fontSize: 9)),
              selected: isSelected,
              onSelected: (v) {
                setDialogState(() {
                  if (v) {
                    if (selectedStatuses.length < 2) selectedStatuses.add(s);
                  } else {
                    selectedStatuses.remove(s);
                  }
                });
              },
            );
          }).toList(),
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), 
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _purple), onPressed: () { setState(() {}); Navigator.pop(context); }, child: const Text("Apply", style: TextStyle(color: Colors.white)))
      ],
    )));
  }

  Widget _filterSectionTitle(String title) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 5), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)));
  Widget _buildClearFilterButton() => Container(height: 45, width: 45, decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: IconButton(icon: Icon(Icons.filter_alt_off, color: Colors.orange.shade700, size: 20), onPressed: _clearAllFilters));

  Widget _btn(String label, Color color, VoidCallback? onTap) => SizedBox(width: double.infinity, height: 42, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: onTap, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))));
  Widget _outlinedBtn(String label, Color color, VoidCallback? onTap) => SizedBox(width: double.infinity, height: 42, child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: onTap == null ? Colors.grey.shade300 : color, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: onTap, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
  
  Widget _statusBadge(bool ns, DateTime deadline) {
    final now = DateTime.now();
    final endOfDeadline = DateTime(deadline.year, deadline.month, deadline.day, 23, 59, 59);
    final bool cl = now.isAfter(endOfDeadline);
    String label = "Registration Open"; Color color = const Color(0xFF6D56B3);
    if (ns) { label = "Registration Upcoming Soon"; color = Colors.orange; }
    else if (cl) { label = "Registration Closed"; color = Colors.grey.shade500; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) => Row(children: [Icon(icon, size: 16, color: _purple), const SizedBox(width: 8), Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87)))]);
  Widget _dateRow(String l1, String d1, String l2, String d2, {bool isDeadline = false}) => Row(children: [Expanded(child: _dateItem(l1, d1)), Container(width: 1, height: 18, color: _purple.withOpacity(0.2)), const SizedBox(width: 12), Expanded(child: _dateItem(l2, d2, isCritical: isDeadline))]);
  Widget _dateTile(BuildContext context, String label, DateTime? date, Function(DateTime) onPicked) {
    return ListTile(
      contentPadding: EdgeInsets.zero, dense: true,
      title: Text(date == null ? label : DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.calendar_month, color: _purple, size: 18),
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
        if (d != null) onPicked(d);
      },
    );
  }
  Widget _dateItem(String label, String date, {bool isCritical = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)), Text(date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCritical ? Colors.deepOrange.shade400 : Colors.black))]);
}