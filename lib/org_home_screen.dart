import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/select_role_screen.dart';
import 'view/create_hackathon_view.dart';

class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key});

  @override
  State<InstitutionHomeScreen> createState() =>
      _InstitutionHomeScreenState();
}

class _InstitutionHomeScreenState
    extends State<InstitutionHomeScreen> {

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

  Widget _navItem(IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index
            ? const Color(0xFFFFA726)
            : Colors.grey,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D56B3);

    return Scaffold(
      backgroundColor: purple,

      appBar: AppBar(
        backgroundColor: purple,
        elevation: 0,
        title: Text(
          _selectedIndex == 2 ? "Create Hackathon" : "BuildMate",
        ),
        leading: _selectedIndex != 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        )
            : null,
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

            GestureDetector(
              onTap: () => _onItemTapped(2),
              child: Container(
                height: 55,
                width: 55,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFA726),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),

            _navItem(Icons.groups_outlined, 3),
            _navItem(Icons.person_outline, 4),
          ],
        ),
      ),
    );
  }
}