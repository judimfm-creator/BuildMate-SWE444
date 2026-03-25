import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';
import 'package:buildmate/viewmodel/register_view_model.dart';

import 'package:buildmate/viewmodel/profile_view_model.dart';
import 'package:buildmate/model/user_model.dart';
import 'package:buildmate/model/hackathon.dart';
import 'package:buildmate/view/profile_management_page.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';
import 'package:buildmate/widgets/user_hackathon_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;
    String cleanUrl = urlString.trim();
    if (!cleanUrl.startsWith('http')) cleanUrl = 'https://$cleanUrl';
    final Uri url = Uri.parse(cleanUrl);
    await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  }

  Future<List<Map<String, dynamic>>> _getUserHackathons(String userId) async {
    final teamPostsSnapshot = await FirebaseFirestore.instance
        .collection('team_posts')
        .where('members', arrayContains: userId)
        .get();

    List<Map<String, dynamic>> result = [];

    for (var doc in teamPostsSnapshot.docs) {
      final data = doc.data();

      final String hackathonId = (data['hackathonId'] ?? '').toString();
      final List members = data['members'] ?? [];
      final String status = (data['status'] ?? 'pending_approval').toString();

      if (hackathonId.isEmpty) continue;

      final hackathonDoc = await FirebaseFirestore.instance
          .collection('hackathons')
          .doc(hackathonId)
          .get();

      if (hackathonDoc.exists) {
        final hackathon = Hackathon.fromFirestore(hackathonDoc);

        result.add({
          'hackathon': hackathon,
          'membersCount': members.length,
          'status': status,
        });
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,


      appBar: BuildMateAppBar(
        titleText: null,
        showBack: false,
        onLogout: () async => await Provider.of<RegisterViewModel>(
          context,
          listen: false,
        ).logout(context),
      ),

      body: StreamBuilder<UserModel?>(
        stream: _viewModel.userDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text("No user profile found"));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: false,
                backgroundColor: primaryPurple.withOpacity(0.05),
                surfaceTintColor: primaryPurple.withOpacity(0.05),
                elevation: 0,
                toolbarHeight: 38,
                expandedHeight: 38,
                automaticallyImplyLeading: false,
                primary: false,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: EdgeInsets.zero,
                  title: Container(
                    alignment: Alignment.center,
                    child: Text(
                      user.fullName,
                      style: TextStyle(
                        color: primaryPurple,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(user),
                    const SizedBox(height: 25),
                    _buildManageButton(),
                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: primaryPurple, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          "Skills",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildSkillsChips(user.skills),
                    const SizedBox(height: 35),

                    _buildTabBarSection(),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOngoingHackathonsTab(user.uid),
                      _buildPreviousHackathonsTab(user.uid),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildProfileHeader(UserModel user) {
    ImageProvider? profileImage;

    if (user.profilePhotoPath != null && user.profilePhotoPath!.isNotEmpty) {
      if (user.profilePhotoPath!.startsWith('http')) {
        profileImage = NetworkImage(user.profilePhotoPath!);
      } else {
        final file = File(user.profilePhotoPath!);
        if (file.existsSync()) {
          profileImage = FileImage(file);
        }
      }
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: lightPurpleBG,
          backgroundImage: profileImage,
          child: profileImage == null
              ? Icon(Icons.person, size: 50, color: primaryPurple)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          "@${user.username}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryPurple,
          ),
        ),
        if (user.bio != null && user.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.linkedin != null && user.linkedin!.isNotEmpty)
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.linkedin,
                  color: Color(0xFF7A62B3),
                ),
                onPressed: () => _launchURL(user.linkedin),
              ),
            if (user.github != null && user.github!.isNotEmpty)
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.github,
                  color: Color(0xFF7A62B3),
                ),
                onPressed: () => _launchURL(user.github),
              ),
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfileManagementPage(),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: manageButtonGrey,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Manage Profile",
            style: TextStyle(
              color: manageButtonText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsChips(dynamic skillsData) {
    List<String> skills = [];

    if (skillsData is List) {
      skills = skillsData.map((e) => e.toString()).toList();
    } else if (skillsData is String && skillsData.isNotEmpty) {
      skills = skillsData.split(',').map((s) => s.trim()).toList();
    }

    if (skills.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: skills.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryPurple.withOpacity(0.4),
              ),
            ),
            child: Text(
              skill,
              style: TextStyle(
                color: primaryPurple,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
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
      tabs: const [
        Tab(text: "Ongoing"),
        Tab(text: "Previous"),
      ],
    );
  }

  Widget _buildOngoingHackathonsTab(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getUserHackathons(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final data = snapshot.data!;

        final ongoing = data.where((item) {
          final h = item['hackathon'] as Hackathon;
          final status = (item['status'] ?? 'pending_approval').toString();

          final started = !h.startDate.isAfter(now);
          final notEnded = !h.endDate.isBefore(now);

          return started && notEnded && (status == 'approved'|| status=='accepted');
        }).toList();

        if (ongoing.isEmpty) {
          return _empty("No ongoing hackathons");
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: ongoing.length,
          itemBuilder: (_, i) {
            final item = ongoing[i];
            return UserHackathonCard(
              hackathon: item['hackathon'] as Hackathon,
              currentMembers: item['membersCount'] as int,
              isPrevious: false,
            );
          },
        );
      },
    );
  }

  Widget _buildPreviousHackathonsTab(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getUserHackathons(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final data = snapshot.data!;

        final previous = data.where((item) {
          final h = item['hackathon'] as Hackathon;
          final status = (item['status'] ?? 'pending_approval').toString();

          return h.endDate.isBefore(now) && (status == 'approved' || status=='accepted');
        }).toList();

        if (previous.isEmpty) {
          return _empty("No previous hackathons");
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: previous.length,
          itemBuilder: (_, i) {
            final item = previous[i];
            return UserHackathonCard(
              hackathon: item['hackathon'] as Hackathon,
              currentMembers: item['membersCount'] as int,
              isPrevious: true,
            );
          },
        );
      },
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }
}