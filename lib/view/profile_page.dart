import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buildmate/viewmodel/profile_view_model.dart';
import 'package:buildmate/model/user_model.dart';
import 'package:buildmate/view/profile_management_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileViewModel _viewModel = ProfileViewModel();

  final Color primaryPurple = const Color(0xFF7A62B3);
  final Color lightPurpleBG = const Color(0xFFF5F3FF);
  final Color manageButtonGrey = const Color(0xFFF2F2F2);
  final Color manageButtonText = const Color(0xFF616161);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;
    String cleanUrl = urlString.trim();
    if (!cleanUrl.startsWith('http')) cleanUrl = 'https://$cleanUrl';
    final Uri url = Uri.parse(cleanUrl);
    await launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ✅ تم حذف الـ AppBar بالكامل هنا
      body: StreamBuilder<UserModel?>(
        stream: _viewModel.userDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final user = snapshot.data;
          if (user == null) return const Center(child: Text("No user data found"));

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60), // مساحة تعويضية علوية بعد حذف الـ AppBar
                _buildProfileHeader(user),
                const SizedBox(height: 20),
                _buildManageButton(),
                const SizedBox(height: 35),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, color: primaryPurple, size: 24),
                    const SizedBox(width: 8),
                    const Text("Skills", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 15),

                _buildSkillsChips(user.skills),

                const SizedBox(height: 30),
                _buildTabBarSection(),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmptyPlaceholder("No ongoing projects", Icons.rocket_launch_outlined),
                      _buildEmptyPlaceholder("No previous projects", Icons.history),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: lightPurpleBG,
          backgroundImage: (user.profilePhotoPath?.isNotEmpty ?? false)
              ? (user.profilePhotoPath!.startsWith('http') ? NetworkImage(user.profilePhotoPath!) : FileImage(File(user.profilePhotoPath!))) as ImageProvider
              : null,
          child: (user.profilePhotoPath?.isEmpty ?? true) ? Icon(Icons.person, size: 50, color: primaryPurple) : null,
        ),
        const SizedBox(height: 12),
        Text("@${user.username}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryPurple)),
        if (user.bio != null && user.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text(user.bio!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.linkedin != null) IconButton(icon: Icon(FontAwesomeIcons.linkedin, color: primaryPurple), onPressed: () => _launchURL(user.linkedin)),
            if (user.github != null) IconButton(icon: Icon(FontAwesomeIcons.github, color: primaryPurple), onPressed: () => _launchURL(user.github)),
          ],
        ),
      ],
    );
  }

  Widget _buildManageButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileManagementPage())),
          style: ElevatedButton.styleFrom(
            backgroundColor: manageButtonGrey,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("Manage Profile", style: TextStyle(color: manageButtonText, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildSkillsChips(String? skillsString) {
    List<String> skills = skillsString?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];
    if (skills.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: skills.map((skill) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryPurple.withOpacity(0.4)),
          ),
          child: Text(skill, style: TextStyle(color: primaryPurple, fontSize: 13, fontWeight: FontWeight.bold)),
        )).toList(),
      ),
    );
  }

  Widget _buildTabBarSection() {
    return TabBar(
      controller: _tabController,
      indicatorColor: primaryPurple,
      labelColor: primaryPurple,
      unselectedLabelColor: Colors.grey,
      indicatorWeight: 3,
      tabs: const [Tab(text: "Ongoing"), Tab(text: "Previous")],
    );
  }

  Widget _buildEmptyPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ],
      ),
    );
  }
}