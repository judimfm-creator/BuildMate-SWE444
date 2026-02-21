import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // دالة تسجيل الخروج الموحدة
  Future<void> logout() async {
    await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
  }

  // صفحات التابات (بدون صفحة Create لأنها تفتح كـ Route مستقل)
  final List<Widget> _pages = const [
    Center(child: Text("Home")),
    Center(child: Text("Announcements")),
    Center(child: Text("Teams")),
    OrgProfilePage(), // صفحة بروفايل المنظمة
  ];

  // تحويل navIndex إلى index داخل _pages (لأن زر + في المنتصف ليس صفحة تابعة للـ Index المباشر)
  int get _pageIndex => (_navIndex > 2) ? _navIndex - 1 : _navIndex;

  void _onItemTapped(int index) {
    // زر + (Index 2) يفتح صفحة إنشاء الهاكاثون كشاشة جديدة
    if (index == 2) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => const CreateHackathonView())
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