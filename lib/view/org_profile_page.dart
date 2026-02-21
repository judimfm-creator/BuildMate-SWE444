import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/viewmodel/org_profile_view_model.dart';
import 'package:buildmate/model/org_model.dart';
import 'package:buildmate/view/org_profile_management_page.dart';
import '../org_home_screen.dart';

class OrgProfilePage extends StatefulWidget {
  const OrgProfilePage({super.key});

  @override
  State<OrgProfilePage> createState() => _OrgProfilePageState();
}

class _OrgProfilePageState extends State<OrgProfilePage> {
  final Color primaryPurple = const Color(0xFF7A62B3);
  final Color lightPurpleBG = const Color(0xFFF5F3FF);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OrgProfileViewModel>(context);
    final String userEmail = FirebaseAuth.instance.currentUser?.email ?? "Not Available";

    return StreamBuilder<OrgModel?>(
      stream: viewModel.orgDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final org = snapshot.data;

        // ✅ DefaultTabController يحل مشكلة الـ Initialization والشاشة الحمراء
        return DefaultTabController(
          length: 1,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                "Profile",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter'
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const InstitutionHomeScreen()),
                        (route) => false,
                  );
                },
              ),
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildOrgHeader(org),
                  const SizedBox(height: 25),
                  _buildManageButton(context),
                  const SizedBox(height: 35),

                  // ✅ قسم التواصل (الموقع، الإيميل، الجوال)
                  _buildContactSection(org, userEmail),

                  const SizedBox(height: 35),

                  // ✅ التاب الوحيد (نفس ستايل اليوزر)
                  _buildTabBarSection(),

                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildEmptyPlaceholder("No previous hackathons yet", Icons.history_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrgHeader(OrgModel? org) {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: lightPurpleBG,
          backgroundImage: (org?.profilePhotoPath?.isNotEmpty ?? false)
              ? FileImage(File(org!.profilePhotoPath!))
              : null,
          child: (org?.profilePhotoPath?.isEmpty ?? true)
              ? Icon(Icons.business, size: 55, color: primaryPurple)
              : null,
        ),
        const SizedBox(height: 15),
        // ✅ الاعتماد على اليوزر نيم فقط
        Text(
          "@${org?.username ?? "organization"}",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Text(
            org?.biography ?? "Leading organization in software construction.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(OrgModel? org, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start, // لضمان توازي الأيقونات لو نزل النص سطرين
        children: [
          Expanded(child: _buildContactItem(Icons.location_on_rounded, "Location", org?.location ?? "N/A")),
          Expanded(child: _buildContactItem(Icons.email_rounded, "Email", email)),
          Expanded(child: _buildContactItem(Icons.phone_iphone_rounded, "Contact", org?.phoneNumber ?? "N/A")),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4)
              )
            ],
          ),
          child: Icon(icon, color: primaryPurple, size: 24),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        // ✅ تم إزالة العرض الثابت واستخدام constraints للسماح بنزول النص لسطر ثانٍ
        Container(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            value,
            textAlign: TextAlign.center,
            softWrap: true, // يسمح بالالتفاف
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarSection() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(height: 1, color: Colors.grey.shade200),
        TabBar(
          indicatorColor: primaryPurple,
          labelColor: primaryPurple,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter'),
          tabs: const [
            Tab(text: "Previous Hackathons"),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 45, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildManageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrgProfileManagementPage())),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2F2F2),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            "Manage Profile",
            style: TextStyle(color: Color(0xFF616161), fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}