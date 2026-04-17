import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:buildmate/model/org_model.dart';
import '../model/hackathon.dart';

class InstitutionPublicProfilePage extends StatefulWidget {
  final OrgModel org;
  final String orgId;

  const InstitutionPublicProfilePage({
    super.key,
    required this.org,
    required this.orgId,
  });

  @override
  State<InstitutionPublicProfilePage> createState() =>
      _InstitutionPublicProfilePageState();
}

class _InstitutionPublicProfilePageState
    extends State<InstitutionPublicProfilePage>
    with SingleTickerProviderStateMixin {
  static const Color _primaryPurple = Color(0xFF7A62B3);
  static const Color _lightPurpleBG = Color(0xFFF5F3FF);

  late TabController _tabController;

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

  Future<List<Hackathon>> _getOrgHackathons() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('hackathons')
        .where('organizationId', isEqualTo: widget.orgId)
        .get();

    final hackathons = snapshot.docs
        .map((doc) => Hackathon.fromFirestore(doc))
        .toList();

    hackathons.sort((a, b) => b.startDate.compareTo(a.startDate));
    return hackathons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: false,
            backgroundColor: _primaryPurple.withOpacity(0.05),
            surfaceTintColor: _primaryPurple.withOpacity(0.05),
            elevation: 0,
            toolbarHeight: 38,
            expandedHeight: 38,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: _primaryPurple,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            primary: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildOrgHeader(),
                const SizedBox(height: 28),
                _buildContactSection(),
                const SizedBox(height: 32),
                _buildAboutSection(),
                const SizedBox(height: 28),
                _buildHackathonTabs(),
                const SizedBox(height: 18),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                  child: FutureBuilder<List<Hackathon>>(
                    future: _getOrgHackathons(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: _primaryPurple,
                          ),
                        );
                      }

                      final allHackathons = snapshot.data ?? [];
                      final now = DateTime.now();

                      final ongoing = allHackathons.where((hackathon) {
                        return !hackathon.endDate.isBefore(now);
                      }).toList();

                      final previous = allHackathons.where((hackathon) {
                        return hackathon.endDate.isBefore(now);
                      }).toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHackathonList(
                            hackathons: ongoing,
                            emptyText: "No ongoing hackathons",
                            isPrevious: false,
                          ),
                          _buildHackathonList(
                            hackathons: previous,
                            emptyText: "No previous hackathons",
                            isPrevious: true,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgHeader() {
    final bool hasPhoto = (widget.org.profilePhotoPath?.isNotEmpty ?? false);

    ImageProvider? profileImage;
    if (hasPhoto) {
      final path = widget.org.profilePhotoPath!;
      if (path.startsWith('http')) {
        profileImage = NetworkImage(path);
      } else {
        final file = File(path);
        if (file.existsSync()) {
          profileImage = FileImage(file);
        }
      }
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: _lightPurpleBG,
          backgroundImage: profileImage,
          child: profileImage == null
              ? const Icon(Icons.business, size: 55, color: _primaryPurple)
              : null,
        ),
        const SizedBox(height: 15),
        Text(
          widget.org.orgName?.isNotEmpty == true
              ? widget.org.orgName!
              : "Organization",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            color: _primaryPurple,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "@${(widget.org.username?.isNotEmpty == true) ? widget.org.username! : "organization"}",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Text(
            (widget.org.biography?.isNotEmpty == true)
                ? widget.org.biography!
                : "No biography available.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildContactItem(
              Icons.location_on_rounded,
              "Location",
              _safeValue(widget.org.location),
            ),
          ),
          Expanded(
            child: _buildContactItem(
              Icons.email_rounded,
              "Email",
              _safeValue(widget.org.email),
            ),
          ),
          Expanded(
            child: _buildContactItem(
              Icons.phone_iphone_rounded,
              "Contact",
              _safeValue(widget.org.phoneNumber),
            ),
          ),
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
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _primaryPurple, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            value,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _lightPurpleBG,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "About Institution",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryPurple,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              (widget.org.biography?.isNotEmpty == true)
                  ? widget.org.biography!
                  : "No additional information available.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHackathonTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _lightPurpleBG,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: _primaryPurple,
            borderRadius: BorderRadius.circular(30),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: _primaryPurple,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Ongoing"),
            Tab(text: "Previous"),
          ],
        ),
      ),
    );
  }

  Widget _buildHackathonList({
    required List<Hackathon> hackathons,
    required String emptyText,
    required bool isPrevious,
  }) {
    if (hackathons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPrevious ? Icons.history : Icons.rocket_launch_outlined,
              size: 42,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              emptyText,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      itemCount: hackathons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final hackathon = hackathons[index];
        return _buildHackathonCard(hackathon, isPrevious: isPrevious);
      },
    );
  }

  Widget _buildHackathonCard(Hackathon hackathon, {required bool isPrevious}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightPurpleBG,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryPurple.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hackathon.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryPurple,
            ),
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.category_outlined, "Domain", hackathon.domain),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, "Location", hackathon.location),
          const SizedBox(height: 6),
          _infoRow(
            Icons.groups_outlined,
            "Team Size",
            hackathon.teamSize > 2
                ? "2 - ${hackathon.teamSize} members"
                : "2 members",
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.event_outlined,
            isPrevious ? "Ended" : "Ends",
            _formatDate(hackathon.endDate),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPrevious
                  ? Colors.grey.shade200
                  : Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPrevious ? "Previous Hackathon" : "Ongoing Hackathon",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPrevious ? Colors.grey.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _primaryPurple),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return "$day/$month/$year";
  }

  String _safeValue(String? value) {
    if (value == null || value.trim().isEmpty) return "N/A";
    return value.trim();
  }
}
