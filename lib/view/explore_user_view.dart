import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodel/org_hackathons_view_model.dart';
import '../model/hackathon.dart';
import 'hackathon_details_view.dart';

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
      actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: _purple)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded, color: _purple)),
          const SizedBox(width: 8),
        ],
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

    return StreamBuilder<List<Hackathon>>(
      stream: vm.exploreHackathonsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }

        final now = DateTime.now();
        var list = (snapshot.data ?? []).where((h) => !h.endDate.isBefore(now)).toList();

        if (list.isEmpty) return const Center(child: Text("No active hackathons found."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) => _buildPremiumHackathonCard(list[index]),
        );
      },
    );
  }

  Widget _buildPremiumHackathonCard(Hackathon h) {
    final now = DateTime.now();
    
    // Updated Status Logic
    String status = "Registration Opening Soon";
    Color sColor = Colors.orange;

    if (now.isAfter(h.applicationOpenDate) && now.isBefore(h.applicationDeadline)) {
      status = "Registration Open"; 
      sColor = Colors.green;
    } else if (now.isAfter(h.applicationDeadline)) {
      status = "Registration Closed"; 
      sColor = Colors.redAccent;
    }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clear Organizer Name Label
                      Text("By ${h.organizationName ?? "Organizer"}", 
                          style: TextStyle(fontWeight: FontWeight.w600, color: _purple.withOpacity(0.7), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                ),
                _statusBadge(status, sColor),
              ],
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),

            _buildInfoRow(Icons.category_outlined, "Domain", h.domain),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.location_on_outlined, "Location", "${h.city}, ${h.mode}"),
            const SizedBox(height: 10),
            // NEW: Team Size added under Location
_buildInfoRow(
  Icons.groups_outlined, 
  "Team Size", 
  h.teamSize > 2 ? "2 - ${h.teamSize} members" : "2 members"
),            
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
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, // Fixed to Purple
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HackathonDetailsView(hackathon: h),
                    ),
                  );
                },
                child: const Text("View Full Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
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