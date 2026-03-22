import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/org_hackathons_view_model.dart';
import '../../model/hackathon.dart';
import '../widgets/hackathon_mini_card.dart';
import 'hackathon_details_view.dart';
import 'explore_user_view.dart';

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
           

            // ── الهكاثونات ──
            _UserSection(
              title: "Open Hackathons 🚀",
              onExploreTap: () => _navigateToExplore(0),
              child: _buildHackathonsList(),
            ),
            
            const SizedBox(height: 30),

            // ── الفرق ──
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            SizedBox(width: 14),
            Expanded(child: Text("Search for hackathons...", style: TextStyle(color: Colors.grey, fontSize: 14))),
            Icon(Icons.search, color: _purple),
            SizedBox(width: 12),
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
        
        // 1. FILTER: Only show currently open registrations for the Home Page
        final openList = (snapshot.data ?? []).where((h) {
          return now.isAfter(h.applicationOpenDate) && now.isBefore(h.applicationDeadline);
        }).toList();

        if (openList.isEmpty) {
          return _buildEmptyHackathonsState();
        }

        return SizedBox(
          height: 310, // Increased height to fit all the professional info + button
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: openList.length,
            itemBuilder: (context, index) {
              final h = openList[index];
              return _buildProfessionalMiniCard(h);
            },
          ),
        );
      },
    );
  }

Widget _buildProfessionalMiniCard(Hackathon h) {
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
        mainAxisSize: MainAxisSize.min, // ✅ Makes the card wrap its content tightly
        children: [
          // --- Header ---
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
              _miniStatusBadge("Open", Colors.green),
            ],
          ),
          const Divider(height: 20),

          // --- Info Rows (No gaps) ---
          _compactInfoRow(Icons.category_outlined, h.domain),
          const SizedBox(height: 8),
          _compactInfoRow(Icons.location_on_outlined, "${h.city}, ${h.mode}"),
          const SizedBox(height: 8),
          _compactInfoRow(Icons.groups_outlined, h.teamSize > 2 ? "2 - ${h.teamSize} members" : "2 members"),
          
          const SizedBox(height: 16), // ✅ Fixed space instead of Spacer()

          // --- Registration Deadline Box ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5), // Light red tint for urgency
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

          // --- View Details Button ---
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
        ],
      ),
    ),
  );
}

  // --- Helper Widgets for the Professional Look ---

  Widget _compactInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _purple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, 
            style: const TextStyle(fontSize: 12, color: Colors.black87), 
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
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
        children: [
          Icon(Icons.group_off_outlined, color: Colors.grey, size: 40),
          SizedBox(height: 10),
          Text("No teams yet", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  final String title;
  final VoidCallback onExploreTap;
  final Widget child;

  const _UserSection({
    super.key,
    required this.title,
    required this.onExploreTap,
    required this.child,
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
                child: const Text(
                  "Explore more",
                  style: TextStyle(color: Color(0xFFFFA726), fontSize: 12),
                ),
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