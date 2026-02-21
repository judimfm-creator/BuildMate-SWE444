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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isOrg = false;

  @override
  void initState() {
    super.initState();
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

    // هنا السر: ربط الـ Index بالصفحات الحقيقية وليس مجرد Text
    final List<Widget> orgPages = [
      const Center(child: Text("Home")),      // 0
      const Center(child: Text("Campaigns")), // 1
      const Center(child: Text("Add")),       // 2
      const Center(child: Text("Teams")),     // 3
      const OrgProfilePage(),                // 4 - تم التأكد من وضع الصفحة الفعلية هنا
    ];

    final List<Widget> userPages = [
      const Center(child: Text("Home")),      // 0
      const Center(child: Text("Hackathons")),// 1
      const Center(child: Text("Teams")),     // 2
      const ProfilePage(),                   // 3 - صفحة Hailah22
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
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