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
          return const SizedBox(height: 185, child: Center(child: CircularProgressIndicator(color: _purple)));
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const SizedBox(height: 100, child: Center(child: Text("No open hackathons found")));
        }
        return SizedBox(
          height: 230, // ✅ زدنا الارتفاع من 210 إلى 230 عشان اسم المنشأة ما يسبب Overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final h = list[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HackathonDetailsView(hackathon: h)),
                    );
                  },
                  // ✅ تأكدي أن HackathonMiniCard يستقبل showOrgName: true
                  child: HackathonMiniCard(
                    hackathon: h,
                    showOrgName: true, 
                  ),
                ),
              );
            },
          ),
        );
      },
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