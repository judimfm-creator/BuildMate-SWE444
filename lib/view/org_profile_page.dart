import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmate/viewmodel/org_profile_view_model.dart';
import 'package:buildmate/model/org_model.dart';
import 'package:buildmate/view/org_profile_management_page.dart';

class OrgProfilePage extends StatefulWidget {
  const OrgProfilePage({super.key});

  @override
  State<OrgProfilePage> createState() => _OrgProfilePageState();
}

class _OrgProfilePageState extends State<OrgProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color deepMediumPurple = const Color(0xFF7A62B3);
  final Color matteOrange = const Color(0xFFD48C5E);
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
    final viewModel = Provider.of<OrgProfileViewModel>(context);

    return StreamBuilder<OrgModel?>(
      stream: viewModel.orgDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final org = snapshot.data;
        String orgName = org?.orgName ?? "Organization";
        String firstInitial = orgName.isNotEmpty ? orgName.substring(0, 1).toUpperCase() : "O";

        // استخدام Scaffold هنا يحل مشكلة الشاشة الحمراء "No Material widget found" نهائياً
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 25),
                Center(
                  child: Container(
                    width: 105, height: 105,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: tealColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: tealColor,
                      backgroundImage: (org?.profilePhotoPath != null && org!.profilePhotoPath!.isNotEmpty)
                          ? FileImage(File(org.profilePhotoPath!)) : null,
                      child: (org?.profilePhotoPath == null || org!.profilePhotoPath!.isEmpty)
                          ? Text(firstInitial, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(orgName, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: tealColor.withOpacity(0.9))),
                const SizedBox(height: 8),
                _buildManagementButton(context),
                const SizedBox(height: 25),
                _buildSocialRow(),
                const SizedBox(height: 30),
                _buildActionButtons(),
                const SizedBox(height: 40),
                _buildTabBarSection(),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmptyState("No ongoing hackathons", Icons.auto_awesome_mosaic),
                      _buildEmptyState("No previous hackathons", Icons.history_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // الدوال المساعدة (_buildManagementButton, _buildSocialRow, إلخ)
  Widget _buildManagementButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrgProfileManagementPage())),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: deepMediumPurple.withOpacity(0.4))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_center_rounded, size: 18, color: deepMediumPurple),
            const SizedBox(width: 8),
            Text("Organization Info", style: TextStyle(color: deepMediumPurple, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 5),
            Icon(Icons.arrow_forward_ios, size: 10, color: deepMediumPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildIconBox(Icons.location_on_outlined), const SizedBox(width: 20), _buildIconBox(Icons.email_outlined)]);
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: deepMediumPurple.withOpacity(0.3))),
      child: Icon(icon, color: deepMediumPurple, size: 22),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Row(children: [Expanded(child: _buildBtn("My Hackathons", Icons.event_available)), const SizedBox(width: 15), Expanded(child: _buildBtn("Reports", Icons.bar_chart_rounded))]),
    );
  }

  Widget _buildBtn(String label, IconData icon) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: matteOrange, borderRadius: BorderRadius.circular(18)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildTabBarSection() {
    return TabBar(controller: _tabController, labelColor: deepMediumPurple, unselectedLabelColor: Colors.grey.shade400, indicatorColor: deepMediumPurple, tabs: const [Tab(text: "Ongoing"), Tab(text: "Previous")]);
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 45, color: Colors.grey.shade100), const SizedBox(height: 12), Text(text, style: TextStyle(color: Colors.grey.shade300, fontSize: 14))]));
  }
}