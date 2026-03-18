import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/register_view_model.dart';
import 'view/create_hackathon_view.dart';
import 'widgets/org_nav_bar.dart';
import 'widgets/buildmate_app_bar.dart';
import 'view/org_profile_page.dart';
import 'view/org_announced_page.dart';
import 'view/org_home_page.dart';

class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key});
  @override
  State<InstitutionHomeScreen> createState() => _InstitutionHomeScreenState();
}

class _InstitutionHomeScreenState extends State<InstitutionHomeScreen> {
  int _navIndex = 0;

  // دالة تسجيل الخروج الموحدة
  Future<void> logout() async {
    await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
  }

  // صفحات التابات (بدون صفحة Create لأنها تفتح كـ Route مستقل)
  final List<Widget> _pages = const [
    OrgHomePage(),           // 0 - Home
    OrgAnnouncedPage(),      // 1 - Announced (Ongoing hackathons)
    Center(child: Text("Teams")),
    OrgProfilePage(), // صفحة بروفايل المنظمة
  ];

  // navIndex 0,1 → pageIndex 0,1 | navIndex 2 → (+) | navIndex 3,4 → pageIndex 2,3
  int get _pageIndex {
    if (_navIndex < 2) return _navIndex;
    if (_navIndex > 2) return _navIndex - 1;
    return 0; // لا يُستخدم (زر + يفتح route)
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateHackathonView()),
      );
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D56B3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        onLogout: logout, // استخدام الدالة الموحدة
      ),
      // استخدام IndexedStack للحفاظ على حالة الصفحات عند التنقل
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