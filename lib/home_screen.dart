import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/select_role_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _selectedIndex = 0;

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SelectRoleScreen()),
          (route) => false,
    );
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
    const orange = Color(0xFFFFA726);

    return Scaffold(
      appBar: AppBar(
        title: const Text("BuildMate"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),
      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        height: 75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            _navItem(Icons.home_outlined, 0),
            _navItem(Icons.campaign_outlined, 1),
            _navItem(Icons.groups_outlined, 2),
            _navItem(Icons.person_outline, 3),

          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    const orange = Color(0xFFFFA726);

    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index ? orange : Colors.grey,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }
}