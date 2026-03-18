import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:buildmate/viewmodel/profile_view_model.dart';
import 'package:buildmate/model/user_model.dart';
import 'package:buildmate/model/team_model.dart';
import 'package:buildmate/model/hackathon.dart';
import 'package:buildmate/view/profile_management_page.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';

import '../services/team_service.dart';
import '../services/hackathon_service.dart';
import '../widgets/user_hackathon_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileViewModel _viewModel = ProfileViewModel();
  final TeamService _teamService = TeamService();
  final HackathonService _hackathonService = HackathonService();

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
    await launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const BuildMateAppBar(
        titleText: '',
        showBack: false,
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
            // لضمان عدم وجود مسافات تلقائية في الأعلى
            slivers: [
              // 1. البار الثابت (الاسم) ملاصق للـ AppBar العلوي
              SliverAppBar(
                pinned: false,
                floating: false,
                backgroundColor: primaryPurple.withOpacity(0.05),
                surfaceTintColor: primaryPurple.withOpacity(0.05),
                elevation: 0,
                // تقليل الارتفاع ليصبح شريطاً نحيفاً وملاصقاً
                toolbarHeight: 38,
                expandedHeight: 38,
                automaticallyImplyLeading: false,
                // إزالة أي مسافات إضافية
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

              // 2. محتوى الصفحة
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // تم تقليل المسافة هنا لتبدأ الصورة مباشرة تحت الاسم الثابت بشكل أنيق
                    const SizedBox(height: 20),

                    _buildProfileHeader(user),
                    const SizedBox(height: 25),
                    _buildManageButton(),
                    const SizedBox(height: 40),

                    // عنوان المهارات
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
                  // نعطي ارتفاعاً كافياً للتابات لكي تظهر كاملة
                  height: 500, // يمكنكِ تعديل هذا الرقم حسب طول المحتوى المتوقع
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOngoingHackathonsTab(),
                      _buildEmptyPlaceholder("No previous projects", Icons.history),
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
                onPressed: () async {
                  final Uri uri = Uri.parse(user.linkedin!);
                  await launchUrl(
                    uri,
                    mode: LaunchMode.inAppBrowserView,
                  );
                },
              ),
            if (user.github != null && user.github!.isNotEmpty)
              IconButton(
                icon: const Icon(
                  FontAwesomeIcons.github,
                  color: Color(0xFF7A62B3),
                ),
                onPressed: () async {
                  final Uri uri = Uri.parse(user.github!);
                  await launchUrl(
                    uri,
                    mode: LaunchMode.inAppBrowserView,
                  );
                },
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
              builder: (context) => const ProfileManagementPage(),
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
        children: skills
            .map(
              (skill) => Container(
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
          ),
        )
            .toList(),
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

  Widget _buildOngoingHackathonsTab() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _buildEmptyPlaceholder(
        "No ongoing hackathons",
        Icons.rocket_launch_outlined,
      );
    }

    return StreamBuilder<List<TeamModel>>(
      stream: _teamService.getTeamsByMember(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Something went wrong",
              style: TextStyle(fontSize: 14),
            ),
          );
        }

        final teams = snapshot.data ?? [];
        final hackathonIds = teams
            .map((team) => team.hackathonId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        if (hackathonIds.isEmpty) {
          return _buildEmptyPlaceholder(
            "No ongoing hackathons",
            Icons.rocket_launch_outlined,
          );
        }

        return FutureBuilder<List<Hackathon>>(
          future: _hackathonService.getHackathonsByIds(hackathonIds),
          builder: (context, hackathonSnapshot) {
            if (hackathonSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (hackathonSnapshot.hasError) {
              return const Center(
                child: Text(
                  "Failed to load hackathons",
                  style: TextStyle(fontSize: 14),
                ),
              );
            }

            final hackathons = hackathonSnapshot.data ?? [];
            final now = DateTime.now();

            final ongoingHackathons = hackathons.where((hackathon) {
              final startsBeforeOrNow =
                  hackathon.startDate.isBefore(now) ||
                      hackathon.startDate.isAtSameMomentAs(now);

              final endsAfterOrNow =
                  hackathon.endDate.isAfter(now) ||
                      hackathon.endDate.isAtSameMomentAs(now);

              return startsBeforeOrNow && endsAfterOrNow;
            }).toList();

            if (ongoingHackathons.isEmpty) {
              return _buildEmptyPlaceholder(
                "No ongoing hackathons",
                Icons.rocket_launch_outlined,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: ongoingHackathons.length,
              itemBuilder: (context, index) {
                final hackathon = ongoingHackathons[index];
                return UserHackathonCard(hackathon: hackathon);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}