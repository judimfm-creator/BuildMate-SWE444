import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // ضروري لاستدعاء الـ ViewModel
import '../viewmodel/register_view_model.dart'; // تأكدي من المسار الصحيح
import 'auth/select_role_screen.dart';
import 'view/create_hackathon_view.dart';
import 'widgets/org_nav_bar.dart';
import 'widgets/buildmate_app_bar.dart';

class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key});

  @override
  State<InstitutionHomeScreen> createState() =>
      _InstitutionHomeScreenState();
}

class _InstitutionHomeScreenState
    extends State<InstitutionHomeScreen> {

  int _selectedIndex = 0;

  // --- التعديل الجوهري هنا ---
  Future<void> logout() async {
    // بدلاً من التوجيه اليدوي للدوائر، نستدعي دالة الـ ViewModel الموحدة
    await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
  }

  final List<Widget> _pages = [
    const Center(child: Text("Home")),
    const Center(child: Text("Announcements")),
    const CreateHackathonView(),
    const Center(child: Text("Teams")),
    const Center(child: Text("Profile")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D56B3);

    return Scaffold(
      backgroundColor: purple,
      appBar: BuildMateAppBar(
        onLogout: logout, // ستعمل الدالة المعدلة الآن وتوجهك للوجن
        titleText: _selectedIndex == 2 ? "Create Hackathon" : null,
        showBack: _selectedIndex == 2,
        onBack: () {
          setState(() => _selectedIndex = 0);
        },
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: OrgNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}