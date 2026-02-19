import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmate/viewmodel/register_view_model.dart';
import 'package:buildmate/widgets/user_nav_bar.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';
import 'package:buildmate/view/profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _handleLogout() async {
    await Provider.of<RegisterViewModel>(context, listen: false).logout(context);
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const Center(child: Text("Home")),
      const Center(child: Text("Hackathons")),
      const Center(child: Text("Teams")),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        onLogout: _handleLogout,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: UserNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}