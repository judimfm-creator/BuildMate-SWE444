import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/org_hackathons_view_model.dart'; 
import '../model/hackathon.dart';
import '../widgets/user_hackathon_card.dart';

class ExploreUserView extends StatefulWidget {
  // أضفنا هذا السطر لاستقبال رقم التبويب
  final int initialTabIndex; 
  const ExploreUserView({super.key, this.initialTabIndex = 0});

  @override
  State<ExploreUserView> createState() => _ExploreUserViewState();
}

class _ExploreUserViewState extends State<ExploreUserView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // جعل التبويب يبدأ من الرقم الممرر (0 للهكاثونات، 1 للفرق)
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: widget.initialTabIndex, // الربط هنا
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Explore", style: TextStyle(color: Color(0xFF7A62B3), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF7A62B3)),
        bottom: TabBar(
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHackathonsSection(),
          _buildEmptyTeamsSection(),
        ],
      ),
    );
  }

  Widget _buildHackathonsSection() {
    final vm = context.watch<OrgHackathonsViewModel>();
    return StreamBuilder<List<Hackathon>>(
      stream: vm.exploreHackathonsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF7A62B3)));
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