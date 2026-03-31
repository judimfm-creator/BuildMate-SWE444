import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/register_view_model.dart';
import 'view/create_hackathon_view.dart';
import 'widgets/org_nav_bar.dart';
import 'widgets/buildmate_app_bar.dart';
import 'view/org_profile_page.dart';
import 'view/org_announced_page.dart';
import 'view/org_home_page.dart';
import 'view/org_my_hackathons_page.dart'; // الصفحة المضافة

class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key});

  @override
  State<InstitutionHomeScreen> createState() => InstitutionHomeScreenState();
}

InstitutionHomeScreenState? institutionHomeState;

class InstitutionHomeScreenState extends State<InstitutionHomeScreen> {
  int _navIndex = 0; // هذا يتبع أزرار الـ NavBar (0, 1, 2, 3, 4)

  // تسجيل خروج
  Future<void> logout() async {
    await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
  }

  // الصفحات الفعلية المعروضة (4 صفحات لأن صفحة "الزائد" تفتح كـ Route مستقل)
  final List<Widget> _pages = const [
    OrgHomePage(),           // 0 - الرئيسية
    OrgAnnouncedPage(),      // 1 - الهاكاثونات المعلنة
    OrgMyHackathonsPage(),   // 2 - هاكاثوناتي (بدل Teams)
    OrgProfilePage(),        // 3 - الملف الشخصي
  ];

  // تحويل Index الـ NavBar إلى Index القائمة اللي فوق
  // إذا ضغطنا 0 أو 1 -> تفتح 0 أو 1
  // إذا ضغطنا 3 أو 4 -> تفتح 2 أو 3 (لأننا تجاوزنا زر الزائد)
  int get _pageIndex {
    if (_navIndex < 2) return _navIndex;
    if (_navIndex > 2) return _navIndex - 1;
    return 0; // حالة مؤقتة لزر الزائد
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // زر الزائد يفتح صفحة "إنشاء" بشكل مستقل
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateHackathonView()),
      );
      return; 
    }
    // بقية الأزرار تغير الصفحة تحت الـ AppBar
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        onLogout: logout,
      ),
      // الـ body الحين مرتب وبحجم طبيعي 100%
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
  @override
  void initState() {
    super.initState();
    institutionHomeState = this; // ✅ نسجل الـ state عشان نوصله من أي مكان
  }

// أضف دالة تغيير التاب
  void changeTab(int index) {
    setState(() => _navIndex = index);
  }
}