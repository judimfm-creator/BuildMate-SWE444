import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/org_hackathons_view_model.dart'; 
import '../model/hackathon.dart';
import '../widgets/user_hackathon_card.dart';

class ExploreUserView extends StatefulWidget {
  const ExploreUserView({super.key});

  @override
  State<ExploreUserView> createState() => _ExploreUserViewState();
}

class _ExploreUserViewState extends State<ExploreUserView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 15), 
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF7A62B3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF7A62B3),
              indicatorSize: TabBarIndicatorSize.label, 
              tabs: const [
                Tab(text: "Hackathons"),
                Tab(text: "Teams"),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. جهة الهكاثونات (شغالة 100%)
                _buildHackathonsSection(),
                
                // 2. جهة الفرق (فارغة مؤقتاً لصديقتك)
                _buildEmptyTeamsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHackathonsSection() {
    return StreamBuilder<List<Hackathon>>(
      stream: context.read<OrgHackathonsViewModel>().exploreHackathonsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text("No hackathons open for registration"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) => UserHackathonCard(hackathon: list[index]),
        );
      },
    );
  }

  // ميثود بسيطة عشان الصفحة ما تكون "إيرور" وتنتظر شغل صديقتك
  Widget _buildEmptyTeamsSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Teams feature is coming soon!",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}