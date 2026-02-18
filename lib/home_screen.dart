import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // أضفنا البروفايدر
import 'viewmodel/register_view_model.dart'; // استدعاء الـ ViewModel
import 'widgets/user_nav_bar.dart';
import 'widgets/buildmate_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // التعديل هنا: استدعاء دالة الخروج من الـ ViewModel لضمان المسارات الصحيحة
  Future<void> _handleLogout() async {
    // نستخدم الـ ViewModel اللي برمجنا فيه العودة لـ /loginUser
    await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
  }

  final List<Widget> _pages = [
    const Center(child: Text("Home")),
    const Center(child: Text("Hackathons")),
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
      backgroundColor: Colors.white, // يفضل خلفية بيضاء للمحتوى داخل الـ Scaffold
      appBar: BuildMateAppBar(
        onLogout: _handleLogout, // نمرر الدالة الجديدة
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: UserNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}