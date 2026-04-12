import 'package:buildmate/view/teams_groups_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buildmate/viewmodel/register_view_model.dart';
import 'package:buildmate/widgets/user_nav_bar.dart';
import 'package:buildmate/widgets/org_nav_bar.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';
import 'package:buildmate/view/profile_page.dart';
import 'package:buildmate/view/org_profile_page.dart';
import 'package:buildmate/view/explore_user_view.dart';
import 'package:buildmate/view/user_home_page.dart';
import 'package:buildmate/view/teams_groups_view.dart';
// ✅ إضافة هذا السطر لتمكين الصفحات الأخرى من تغيير التبويب
_HomeScreenState? homeScreenState;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isOrg = false;

  // ✅ إضافة هذه الدالة لتغيير الصفحة برمجياً
  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    homeScreenState = this; // ✅ ربط الحالة الحالية بالمتغير العالمي
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    try {
      final doc = await FirebaseFirestore.instance.collection('organizations').doc(uid).get();
      if (mounted) {
        setState(() {
          _isOrg = doc.exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> orgPages = [
      const Center(child: Text("Home")),      // 0
      const Center(child: Text("Campaigns")), // 1
      const Center(child: Text("Add")),       // 2
      const Center(child: Text("Teams")),     // 3
      const OrgProfilePage(),                // 4
    ];

    final List<Widget> userPages = [
      const UserHomePage(),     // 0
      const ExploreUserView(),  // 1
      const TeamsGroupsView(),     // 2
      const ProfilePage(),                   // 3
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: (!_isOrg && _selectedIndex == 3) 
          ? null 
          : BuildMateAppBar(
              onLogout: () => Provider.of<RegisterViewModel>(context, listen: false).logout(context),
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _isOrg ? orgPages : userPages,
      ),
      bottomNavigationBar: _isOrg
          ? OrgNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      )
          : UserNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}