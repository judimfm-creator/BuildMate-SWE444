import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buildmate/model/org_model.dart';

class InstitutionPublicProfilePage extends StatelessWidget {
  final OrgModel org;

  const InstitutionPublicProfilePage({
    super.key,
    required this.org,
  });

  static const Color _primaryPurple = Color(0xFF7A62B3);
  static const Color _lightPurpleBG = Color(0xFFF5F3FF);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
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
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: EdgeInsets.zero,
                title: Container(
                  alignment: Alignment.center,
                  child: Text(
                    org.orgName?.isNotEmpty == true
                        ? org.orgName!
                        : "Organization Profile",
                    style: const TextStyle(
                      color: _primaryPurple,
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
                  _buildOrgHeader(),
                  const SizedBox(height: 28),
                  _buildContactSection(),
                  const SizedBox(height: 32),
                  _buildAboutSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgHeader() {
    final bool hasPhoto = (org.profilePhotoPath?.isNotEmpty ?? false);

    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: _lightPurpleBG,
          backgroundImage: hasPhoto
              ? FileImage(File(org.profilePhotoPath!))
              : null,
          child: !hasPhoto
              ? const Icon(Icons.business, size: 55, color: _primaryPurple)
              : null,
        ),
        const SizedBox(height: 15),
        Text(
          org.orgName?.isNotEmpty == true ? org.orgName! : "Organization",
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
          "@${(org.username?.isNotEmpty == true) ? org.username! : "organization"}",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Text(
            (org.biography?.isNotEmpty == true)
                ? org.biography!
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
              _safeValue(org.location),
            ),
          ),
          Expanded(
            child: _buildContactItem(
              Icons.email_rounded,
              "Email",
              _safeValue(org.email),
            ),
          ),
          Expanded(
            child: _buildContactItem(
              Icons.phone_iphone_rounded,
              "Contact",
              _safeValue(org.phoneNumber),
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
              (org.biography?.isNotEmpty == true)
                  ? org.biography!
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

  String _safeValue(String? value) {
    if (value == null || value.trim().isEmpty) return "N/A";
    return value.trim();
  }
}