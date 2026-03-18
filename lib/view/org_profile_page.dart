import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buildmate/viewmodel/org_profile_view_model.dart';
import 'package:buildmate/model/org_model.dart';
import 'package:buildmate/view/org_profile_management_page.dart';
import '../org_home_screen.dart';
import 'package:buildmate/viewmodel/org_hackathons_view_model.dart';
import 'package:buildmate/model/hackathon.dart';
import '../widgets/hackathon_card.dart';

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
    final String userEmail = FirebaseAuth.instance.currentUser?.email ??
        "Not Available";

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

        return DefaultTabController(
          length: 1,
          child: Scaffold(
            backgroundColor: Colors.white,
            // ✅ تم حذف الـ AppBar بالكامل هنا
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // مساحة تعويضية علوية بعد حذف الـ AppBar
                  _buildOrgHeader(org),
                  const SizedBox(height: 25),
                  _buildManageButton(context),
                  const SizedBox(height: 35),

                  _buildContactSection(org, userEmail),

                  const SizedBox(height: 35),

                  _buildTabBarSection(),

                  const SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _PastHackathonsTab(),
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
        // ✅ تم تغيير اللون للموف ليتطابق مع اليوزر
        Text(
          "@${org?.username ?? "organization"}",
          style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: primaryPurple),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Text(
            org?.biography ?? "Leading organization in software construction.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade700, height: 1.4),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildContactItem(
              Icons.location_on_rounded, "Location", org?.location ?? "N/A")),
          Expanded(
              child: _buildContactItem(Icons.email_rounded, "Email", email)),
          Expanded(child: _buildContactItem(
              Icons.phone_iphone_rounded, "Contact",
              org?.phoneNumber ?? "N/A")),
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
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            value,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
                fontSize: 10, color: Colors.grey.shade600, height: 1.2),
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
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter'),
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
          Text(text, style: TextStyle(color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500)),
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
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const OrgProfileManagementPage())),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2F2F2),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            "Manage Profile",
            style: TextStyle(color: Color(0xFF616161),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
  class _PastHackathonsTab extends StatelessWidget {
  const _PastHackathonsTab();
  static const Color _purple = Color(0xFF6D56B3);

  @override
  Widget build(BuildContext context) {
  final vm = context.read<OrgHackathonsViewModel>();
  return StreamBuilder<List<Hackathon>>(
  stream: vm.pastStream,
  builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator(color: _purple));
  }
  final list = snapshot.data ?? [];
  if (list.isEmpty) {
  return Center(
  child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  Icon(Icons.history_rounded, size: 45, color: Colors.grey.shade300),
  const SizedBox(height: 12),
  Text("No past hackathons yet",
  style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
  ],
  ),
  );
  }
  return ListView.builder(
  padding: const EdgeInsets.only(top: 12, bottom: 24),
  itemCount: list.length,
  itemBuilder: (_, i) {
  final h = list[i];
  return HackathonCard(
  hackathon: h,
  isPast: true,
  onDelete: () => _confirmDelete(context, vm, h),
  );
  },
  );
  },
  );
  }

  void _confirmDelete(BuildContext context, OrgHackathonsViewModel vm, Hackathon h) {
  showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  title: const Text("Delete Hackathon",
  style: TextStyle(fontWeight: FontWeight.bold)),
  content: Text('Delete "${h.name}"?\nThis cannot be undone.',
  style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
  actions: [
  TextButton(
  onPressed: () => Navigator.pop(ctx),
  child: const Text("Cancel", style: TextStyle(color: _purple)),
  ),
  ElevatedButton(
  onPressed: () async {
  Navigator.pop(ctx);
  if (h.id == null) return;
  try {
  await vm.deleteHackathon(h.id!);
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Hackathon deleted"),
  backgroundColor: Colors.red),
  );
  }
  } catch (_) {
  if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Failed to delete. Try again.")),
  );
  }
  }
  },
  style: ElevatedButton.styleFrom(
  backgroundColor: Colors.red.shade400,
  foregroundColor: Colors.white,
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  child: const Text("Delete"),
  ),
  ],
  ),
  );
  }
  }
