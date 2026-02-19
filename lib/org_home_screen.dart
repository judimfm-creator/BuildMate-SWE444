import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/register_view_model.dart';
import 'view/create_hackathon_view.dart';
import 'widgets/org_nav_bar.dart';
import 'widgets/buildmate_app_bar.dart';

class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key});

  @override
  State<InstitutionHomeScreen> createState() => _InstitutionHomeScreenState();
}

class _InstitutionHomeScreenState extends State<InstitutionHomeScreen> {
  // هذا يمثل اختيار الـ NavBar الحقيقي: 0,1,2(+),3,4
  int _navIndex = 0;

  Future<void> logout() async {
    await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
  }

  // صفحات التابات (بدون صفحة Create)
  final List<Widget> _pages = const [
    Center(child: Text("Home")),
    Center(child: Text("Announcements")),
    Center(child: Text("Teams")),
    Center(child: Text("Profile")),
  ];

  // تحويل navIndex إلى index داخل _pages (لأن + مو صفحة)
  int get _pageIndex => (_navIndex > 2) ? _navIndex - 1 : _navIndex;

  void _onItemTapped(int index) {
    // زر + يفتح صفحة جديدة (Route) ولا يغير التاب الحالي
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
      backgroundColor: purple,
      appBar: BuildMateAppBar(
        onLogout: logout,
      ),
      body: _pages[_pageIndex],
      bottomNavigationBar: OrgNavBar(
        selectedIndex: _navIndex, // مهم عشان الهايلايت يضبط
        onTap: _onItemTapped,
      ),
    );
  }
}