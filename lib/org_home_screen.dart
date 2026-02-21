import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/register_view_model.dart';
import 'view/create_hackathon_view.dart';
import 'widgets/org_nav_bar.dart';
import 'widgets/buildmate_app_bar.dart';
import 'view/org_profile_page.dart';

class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key});
  @override
  State<InstitutionHomeScreen> createState() => _InstitutionHomeScreenState();
}

class _InstitutionHomeScreenState extends State<InstitutionHomeScreen> {
  int _navIndex = 0;
  final List<Widget> _pages = const [
    Center(child: Text("Home")),
    Center(child: Text("Announcements")),
    Center(child: Text("Teams")),
    OrgProfilePage(),
  ];

  int get _pageIndex => (_navIndex > 2) ? _navIndex - 1 : _navIndex;

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateHackathonView()));
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(onLogout: () => Provider.of<RegisterViewModel>(context, listen: false).logout(context)),
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: OrgNavBar(selectedIndex: _navIndex, onTap: _onItemTapped),
    );
  }
}