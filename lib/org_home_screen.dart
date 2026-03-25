import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/register_view_model.dart';
import 'view/create_hackathon_view.dart';
import 'widgets/org_nav_bar.dart';
import 'widgets/buildmate_app_bar.dart';
import 'view/org_profile_page.dart';
import 'view/org_announced_page.dart';
import 'view/org_home_page.dart';
import 'view/org_my_hackathons_page.dart'; // ⭐ أضفناه

class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key});

  @override
  State<InstitutionHomeScreen> createState() =>
      _InstitutionHomeScreenState();
}

class _InstitutionHomeScreenState
    extends State<InstitutionHomeScreen> {
  int _navIndex = 0;

  // تسجيل خروج
  Future<void> logout() async {
    await Provider.of<RegisterViewModel>(
      context,
      listen: false,
    ).logout(context);
  }

  // ⭐ صفحات التابات
  final List<Widget> _pages = const [
    OrgHomePage(),              // 0 - Home
    OrgAnnouncedPage(),         // 1 - Announced
    OrgMyHackathonsPage(),      // 2 - Requests (بدل Teams)
    OrgProfilePage(),           // 3 - Profile
  ];

  // ⭐ تحويل navIndex إلى pageIndex
  int get _pageIndex {
    if (_navIndex < 2) return _navIndex;
    if (_navIndex > 2) return _navIndex - 1;
    return 0; // زر +
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CreateHackathonView(),
        ),
      );
      return;
    }

    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        onLogout: logout,
      ),
      body: IndexedStack(
        index: _pageIndex,
        children: _pages,
      ),
      bottomNavigationBar: OrgNavBar(
        selectedIndex: _navIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}