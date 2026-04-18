import 'package:flutter/material.dart';
import '../home_screen.dart';
import 'explore_user_view.dart' as explore_view;
import 'my_teams_view.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  // الألوان الأساسية بناءً على الهوية والتوزيع الجديد
  static const Color _mainPurple = Color(0xFF6D56B3);
  static const Color _mainOrange = Color(0xFFFFA726);
  static const Color _turquoise = Color(0xFF00ACC1); // درجة التركواز/السيان المأخوذة من اللوقو

  void _navigateToExplore(int tabIndex) {
    explore_view.targetExploreTab = tabIndex;
    homeScreenState?.changeTab(1);
    Future.delayed(const Duration(milliseconds: 100), () {
      explore_view.exploreTabStream.add(tabIndex);
    });
  }

  void _navigateToWorkspace() {
    homeScreenState?.changeTab(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),

            // القسم العلوي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _mainPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: _mainPurple,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Welcome to BuildMate!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "What would you like to explore today?",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // الأزرار موزعة بالشكل القطري الجديد
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الصف الأول: تركوازي | موف
                        Row(
                          children: [
                            Expanded(
                              child: _buildDashboardButton(
                                context,
                                title: "All Hackathons",
                                icon: Icons.campaign_outlined,
                                color: _turquoise, // 👈 تركوازي
                                onTap: () => _navigateToExplore(0),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDashboardButton(
                                context,
                                title: "Teams to Join",
                                icon: Icons.person_add_alt_1_rounded,
                                color: _mainPurple, // 👈 موف
                                onTap: () => _navigateToExplore(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // الصف الثاني: موف | برتقالي
                        Row(
                          children: [
                            Expanded(
                              child: _buildDashboardButton(
                                context,
                                title: "My Teams",
                                icon: Icons.diversity_3_rounded,
                                color: _mainPurple, // 👈 موف
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyTeamsView(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDashboardButton(
                                context,
                                title: "My Groups\nWorkspace",
                                icon: Icons.groups_outlined,
                                color: _mainOrange, // 👈 برتقالي
                                onTap: _navigateToWorkspace,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 170,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}