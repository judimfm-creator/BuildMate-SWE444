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

class ExploreUserView extends StatefulWidget {
  final int initialTabIndex;
  const ExploreUserView({super.key, this.initialTabIndex = 0});

  @override
  State<ExploreUserView> createState() => _ExploreUserViewState();
}

class _ExploreUserViewState extends State<ExploreUserView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBg = Color(0xFFF0EEFF);
  static const Color _screenBg = Color(0xFFF8F9FD);

  // متغيرات الفلترة
  String? selectedMode;
  String? selectedStatus;
  String? selectedEducation;
  DateTime? selectedEndRegDate;
  DateTime? selectedStartEventDate; 
  DateTime? selectedEndEventDate; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
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

              // ✅ إضافة زر حذف الفلاتر هنا ليظهر فقط عند وجود فلاتر نشطة
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
          _buildTeamsList(), // ✅ تم استبدال النص بهذه الدالة
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
          // ✅ تم حذف الجزء القديم الخاص بـ "Clear All" من هنا لأنه صار فوق ثابت
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

                  bool mEdu = selectedEducation == null ||
                      (h.educationCriteria ?? "Any") == selectedEducation;

                  bool mStatus = true;
                  if (selectedStatus != null) {
                    if (selectedStatus == "Registration Upcoming Soon") {
                      mStatus = now.isBefore(h.applicationOpenDate);
                    } else if (selectedStatus == "Registration Open") {
                      mStatus = now.isAfter(h.applicationOpenDate) && now.isBefore(h.applicationDeadline);
                    } else if (selectedStatus == "Registration Closed") {
                      mStatus = now.isAfter(h.applicationDeadline);
                    }
                  }

                  bool mEvStart = selectedStartEventDate == null || isSameDay(h.startDate, selectedStartEventDate!);
                  bool mEvEnd = selectedEndEventDate == null || isSameDay(h.endDate, selectedEndEventDate!);
                  bool mDeadline = selectedEndRegDate == null || isSameDay(h.applicationDeadline, selectedEndRegDate!);

                  return mCity && mMode && mStatus && mEdu && mEvStart && mEvEnd && mDeadline;
                }).toList();

                if (list.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text("No results found."),
                  ));
                }

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

  Widget _buildTeamsList() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<Map<String, dynamic>>>(
      // 1. نجلب كل بيانات الفرق والهاكاثونات المرتبطة فيها مرة واحدة
      stream: FirebaseFirestore.instance
          .collection('team_posts')
          .orderBy('createdAt', descending: true)
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
          String hackathonName = "Unknown Hackathon";

          if (hackathonDoc.exists) {
            hackathon = Hackathon.fromFirestore(hackathonDoc);
            hackathonName = hackathon.name;
          }

          return {
            'team': team,
            'hackathon': hackathon,
            'hackathonName': hackathonName,
          };
        });

        return await Future.wait(futures);
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text("No teams available right now."),
            ),
          );
        }

        // 2. الفلترة المباشرة بناءً على اختيارات اليوزر في الواجهة
        final now = DateTime.now();
        var list = snapshot.data!.where((item) {
          final team = item['team'] as TeamPostModel;
          final h = item['hackathon'] as Hackathon?;
          final hName = item['hackathonName'] as String;

          // --- القواعد الأساسية ---
          // إخفاء الهاكاثونات المنتهية، وإخفاء الفرق الخاصة بالمستخدم نفسه
          if (h == null || h.applicationDeadline.isBefore(now)) return false;
          if (team.createdBy == currentUid) return false;

          // --- فلاتر البحث والنافذة ---

          // 1. شريط البحث (يبحث في اسم الفريق واسم الهاكاثون)
          bool mSearch = _searchController.text.isEmpty ||
              team.teamName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              hName.toLowerCase().contains(_searchController.text.toLowerCase());

          // 2. فلتر المدينة
          bool mCity = _cityController.text.isEmpty ||
              h.city.toLowerCase().contains(_cityController.text.toLowerCase());

          // 3. فلتر طريقة الحضور
          bool mMode = selectedMode == null || h.mode == selectedMode;

          // 4. فلتر المستوى التعليمي
          bool mEdu = selectedEducation == null || h.educationCriteria == selectedEducation;

          // 5. فلتر حالة التسجيل (ملاحظة: المنتهي استبعدناه مسبقاً، لكن هذا يحترم خيار اليوزر لو فلتر)
          bool mStatus = true;
          if (selectedStatus != null) {
            if (selectedStatus == "Registration Upcoming Soon") {
              mStatus = now.isBefore(h.applicationOpenDate);
            } else if (selectedStatus == "Registration Open") {
              mStatus = now.isAfter(h.applicationOpenDate) && now.isBefore(h.applicationDeadline);
            } else if (selectedStatus == "Registration Closed") {
              mStatus = now.isAfter(h.applicationDeadline);
            }
          }

          // 6. تواريخ الحدث والتسجيل
          bool mEvStart = selectedStartEventDate == null || isSameDay(h.startDate, selectedStartEventDate!);
          bool mEvEnd = selectedEndEventDate == null || isSameDay(h.endDate, selectedEndEventDate!);
          bool mDeadline = selectedEndRegDate == null || isSameDay(h.applicationDeadline, selectedEndRegDate!);

          // لازم الفريق يطابق كل شروط الفلتر عشان ينعرض
          return mSearch && mCity && mMode && mEdu && mStatus && mEvStart && mEvEnd && mDeadline;
        }).toList();

        // في حال كان الفلتر مطبق بس ما فيه ولا فريق يطابق
        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text("No teams match your filters.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        // عرض الفرق المفلترة
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

// ✅ استقبال البيانات كـ Parameters بدل ما نسوي FutureBuilder
  Widget _buildTeamCard(TeamPostModel team, Hackathon? hackathon, String hackathonName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Team Name", style: TextStyle(fontWeight: FontWeight.w600, color: _purple.withOpacity(0.7), fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(team.teamName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("Looking for Members", style: TextStyle(color: _purple, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 25),
            _buildInfoRow(Icons.emoji_events_outlined, "Hackathon", hackathonName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person_outline, "Leader's Role", team.myRole),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.wc_outlined, "Gender Preference", team.genderPreference),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _outlinedBtn("Full Details", _purple, () {
                    if (hackathon != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => TeamPostDetailsView(team: team, hackathon: hackathon),
                      ));
                    }
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _btn("Request to join", _purple, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Coming Soon"),
                        backgroundColor: _purple,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(OrgHackathonsViewModel vm) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search hackathons, orgs, domains...",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: _purple, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey, size: 16),
                onPressed: () {
                  vm.updateSearchQuery("");
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: _purple, width: 1.2)),
      ),
      onChanged: (value) {
        vm.updateSearchQuery(value);
        setState(() {});
      },
    );
  }

  Widget _buildFilterButton() {
    return Container(
      height: 45, width: 45,
      decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: IconButton(
        icon: const Icon(Icons.tune, color: _purple, size: 20),
        onPressed: () => _showFilterDialog(context),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Filters", style: TextStyle(fontWeight: FontWeight.bold, color: _purple, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filterSectionTitle("Location"),
                TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(hintText: "City Name", prefixIcon: Icon(Icons.location_city, size: 18))),

                const SizedBox(height: 15),
                _filterSectionTitle("Attendance Mode"),
                DropdownButtonFormField<String>(
                  value: selectedMode,
                  hint: const Text("Select Mode"),
                  items: ["Onsite", "Online", "Hybrid"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setDialogState(() => selectedMode = val),
                ),

                const Divider(height: 30),
                // ✅ تواريخ الحدث (شغالة الآن)
                _filterSectionTitle("Event Dates"),
                _dateTile(context, "Event Start Date", selectedStartEventDate, (d) => setDialogState(() => selectedStartEventDate = d)),
                _dateTile(context, "Event End Date", selectedEndEventDate, (d) => setDialogState(() => selectedEndEventDate = d)),

                const Divider(height: 30),
                _filterSectionTitle("Education Criteria"),
                DropdownButtonFormField<String>(
                  value: selectedEducation,
                  hint: const Text("Select Level"),
                  items: ["Any", "University Students", "High School", "Professionals"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => selectedEducation = val),
                ),

                const Divider(height: 30),
                _filterSectionTitle("Status"),
                Wrap(
                  spacing: 5,
                  children: ["Registration Upcoming Soon", "Registration Open", "Registration Closed"].map((s) => ChoiceChip(
                    label: Text(s, style: const TextStyle(fontSize: 9)),
                    selected: selectedStatus == s,
                    selectedColor: _purple.withOpacity(0.2),
                    onSelected: (v) => setDialogState(() => selectedStatus = v ? s : null),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () { setState(() {}); Navigator.pop(context); },
              child: const Text("Apply", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 5, top: 10),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
      );

  Widget _dateTile(BuildContext context, String label, DateTime? date, Function(DateTime) onPicked) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(date == null ? label : DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.calendar_month, color: _purple, size: 18),
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
        if (d != null) onPicked(d);
      },
    );
  }

  // --- Premium Card (بدون تغيير في المحتوى) ---
  Widget _buildPremiumHackathonCard(Hackathon h) {
    final DateTime now = DateTime.now();
    final bool regNotStarted = now.isBefore(h.applicationOpenDate);
    final bool regClosed = now.isAfter(h.applicationDeadline);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _purple.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("By ${h.organizationName ?? "Organizer"}", style: TextStyle(fontWeight: FontWeight.w600, color: _purple.withOpacity(0.7), fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(h.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _statusBadge(regNotStarted, regClosed),
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
              child: Column(
                children: [
                  _dateRow("Reg. Starts", _format(h.applicationOpenDate), "Reg. Deadline", _format(h.applicationDeadline), isDeadline: true),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(color: Colors.white)),
                  _dateRow("Event Starts", _format(h.startDate), "Event Ends", _format(h.endDate)),
                ],
              ),
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
                        hackathonTeamSize: h.teamSize))).then((_) => setState(() {}));
                    });
                  }
                  return Row(
                    children: [
                      if (regClosed)
                        Expanded(child: _outlinedBtn("Registration Closed", Colors.grey, null))
                      else if (regNotStarted)
                        Expanded(child: _outlinedBtn("Upcoming", Colors.grey, null))
                      else ...[
                        Expanded(child: _outlinedBtn("Create Team", _purple, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateTeamPostScreen(hackathonId: h.id ?? "", hackathonTeamSize: h.teamSize))).then((_) { if (mounted) setState(() {}); });
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _outlinedBtn("Join Team", _purple, () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => teams_view.ExploreTeamsView(hackathonId: h.id ?? "", hackathonTeamSize: h.teamSize))).then((_) { if (mounted) setState(() {}); });
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
        style: ElevatedButton.styleFrom(backgroundColor: color, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
      ),
    );
  }

  Widget _outlinedBtn(String label, Color color, VoidCallback? onTap) {
    return SizedBox(width: double.infinity, height: 42,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: onTap == null ? Colors.grey.shade300 : color, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _statusBadge(bool ns, bool cl) {
    String label = "Registration Open"; Color color = Colors.green;
    if (ns) { label = "Upcoming"; color = Colors.orange; }
    else if (cl) { label = "Closed"; color = Colors.red; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [
        Icon(icon, size: 16, color: _purple),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87))),
      ],
    );
  }

  Widget _dateRow(String l1, String d1, String l2, String d2, {bool isDeadline = false}) {
    return Row(children: [
        Expanded(child: _dateItem(l1, d1)),
        Container(width: 1, height: 18, color: _purple.withOpacity(0.2)),
        const SizedBox(width: 12),
        Expanded(child: _dateItem(l2, d2, isCritical: isDeadline)),
      ],
    );
  }

  Widget _dateItem(String label, String date, {bool isCritical = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCritical ? Colors.redAccent : Colors.black)),
      ],
    );
  }
}