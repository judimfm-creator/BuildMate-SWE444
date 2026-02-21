import 'dart:io'; // إضافة مكتبة الملفات لدعم عرض الصورة المحدثة
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buildmate/viewmodel/profile_view_model.dart';
import 'package:buildmate/model/user_model.dart';
import 'package:buildmate/view/profile_management_page.dart';
import 'package:buildmate/widgets/buildmate_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileViewModel _viewModel = ProfileViewModel();

  final Color deepMediumPurple = const Color(0xFF7A62B3);
  final Color matteOrange = const Color(0xFFD48C5E);
  final Color tealColor = const Color(0xFF63A2A2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
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
          appBar: BuildMateAppBar(
            titleText: '',
            showBack: false,
          ),
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 105,
                          height: 105,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: tealColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: tealColor,
                            // التعديل: دعم عرض الصورة المختارة محلياً أو المحملة من الإنترنت
                            backgroundImage: (user?.profilePhotoPath != null && user!.profilePhotoPath!.isNotEmpty)
                                ? (user.profilePhotoPath!.startsWith('http'))
                                ? NetworkImage(user.profilePhotoPath!) as ImageProvider
                                : FileImage(File(user.profilePhotoPath!))
                                : null,
                            child: (user?.profilePhotoPath == null || user!.profilePhotoPath!.isEmpty)
                                ? Text(
                              firstInitial,
                              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                          "@${user?.username ?? 'username'}",
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: tealColor.withOpacity(0.9))
                      ),
                      const SizedBox(height: 8),

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
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                "Skills",
                                matteOrange,
                                Icons.bolt_rounded,
                                    () {},
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildActionButton(
                                "Requests",
                                matteOrange,
                                Icons.near_me_rounded,
                                    () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildMinimalTabBar(),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildEmptyPlaceholder("No ongoing hackathons", Icons.auto_awesome_mosaic),
                            _buildEmptyPlaceholder("History is empty", Icons.history_rounded),
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

  Widget _buildEnhancedInfoButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileManagementPage())),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: deepMediumPurple.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_pin_rounded, size: 18, color: deepMediumPurple),
            const SizedBox(width: 8),
            Text("Profile Information", style: TextStyle(color: deepMediumPurple, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 5),
            Icon(Icons.arrow_forward_ios, size: 10, color: deepMediumPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSocialCard(IconData icon, String? url) {
    bool hasUrl = url != null && url.isNotEmpty;
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: deepMediumPurple.withOpacity(hasUrl ? 0.3 : 0.1)),
        ),
        child: FaIcon(icon, color: deepMediumPurple, size: 22),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))
                  ]
              )
          )
      ),
    );
  }

  Widget _buildMinimalTabBar() {
    return TabBar(
        controller: _tabController,
        labelColor: deepMediumPurple,
        unselectedLabelColor: Colors.grey.shade400,
        indicatorColor: deepMediumPurple,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [Tab(text: "Ongoing"), Tab(text: "Previous")]
    );
  }

  Widget _buildEmptyPlaceholder(String text, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 45, color: Colors.grey.shade100), const SizedBox(height: 12), Text(text, style: TextStyle(color: Colors.grey.shade300, fontSize: 14))]));
  }
}