import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buildmate/viewmodel/profile_view_model.dart';
import 'package:buildmate/model/user_model.dart';
import 'package:buildmate/view/profile_management_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileViewModel _viewModel = ProfileViewModel();

  // الألوان المستخدمة في مشروعك
  final Color deepMediumPurple = const Color(0xFF7A62B3);
  final Color tealColor = const Color(0xFF63A2A2);

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _viewModel.userDataStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        String userName = user?.fullName ?? "User";
        String firstInitial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : "U";

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              user?.username ?? "username",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // لجعل النصوص تبدأ من اليسار/اليمين حسب اللغة
                    children: [
                      // 1. قسم الصورة (في المنتصف)
                      const SizedBox(height: 20),
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (user?.profilePhotoPath != null && user!.profilePhotoPath!.isNotEmpty)
                              ? (user.profilePhotoPath!.startsWith('http'))
                              ? NetworkImage(user.profilePhotoPath!) as ImageProvider
                              : FileImage(File(user.profilePhotoPath!))
                              : null,
                          child: (user?.profilePhotoPath == null || user!.profilePhotoPath!.isEmpty)
                              ? Text(firstInitial, style: TextStyle(fontSize: 40, color: tealColor))
                              : null,
                        ),
                      ),

<<<<<<< Updated upstream
                      _buildEnhancedInfoButton(context),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        // ✅ تم تغيير linkedinUrl إلى linkedin و githubUrl إلى github
_buildModernSocialCard(FontAwesomeIcons.linkedinIn, user?.linkedin),
const SizedBox(width: 20),
_buildModernSocialCard(FontAwesomeIcons.github, user?.github),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 35),
                        child: Row(
=======
                      // 2. الاسم والبايو (تحت الصورة)
                      const SizedBox(height: 15),
                      Center(
                        child: Column(
>>>>>>> Stashed changes
                          children: [
                            Text(
                              user?.fullName ?? "Full Name",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                user?.bio ?? "No bio yet...", // تأكدي من وجود bio في الـ UserModel
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. زر Manage Profile
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileManagementPage()),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text(
                              "Manage Profile",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),

                      // 4. قسم المهارات (تصميم الهايلايت)
                      const SizedBox(height: 25),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text("Skills", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      const SizedBox(height: 10),
                      _buildSkillsHighlights(user?.skills), // نمرر المهارات هنا

                      const SizedBox(height: 20),

                      // 5. التبويبات (الهاكاثونات)
                      _buildInstagramTabBar(),
                      SizedBox(
                        height: 400, // يمكن تعديله حسب الحاجة
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildEmptyPlaceholder("No ongoing hackathons", Icons.grid_on_rounded),
                            _buildEmptyPlaceholder("History is empty", Icons.assignment_ind_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // مهارات على شكل Highlights
  Widget _buildSkillsHighlights(String? skillsString) {
    List<String> skills = skillsString?.split(',').where((s) => s.trim().isNotEmpty).toList() ?? [];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: skills.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade100,
                    child: Icon(Icons.star_border_rounded, color: deepMediumPurple, size: 25),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  skills[index].trim(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstagramTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.black,
      indicatorWeight: 1,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(icon: Icon(Icons.grid_on_rounded)),
        Tab(icon: Icon(Icons.assignment_ind_outlined)),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}