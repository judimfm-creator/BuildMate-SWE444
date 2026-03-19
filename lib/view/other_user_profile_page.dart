import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/user_model.dart';
import '../services/user_service.dart';
import '../widgets/buildmate_app_bar.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  final UserService _userService = UserService();

  final Color primaryPurple = const Color(0xFF7A62B3);
  final Color lightPurpleBG = const Color(0xFFF5F3FF);

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;

    String cleanUrl = urlString.trim();
    if (!cleanUrl.startsWith('http')) {
      cleanUrl = 'https://$cleanUrl';
    }

    final Uri url = Uri.parse(cleanUrl);
    await launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Profile",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userService.streamUserById(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(
              child: Text("User profile not found"),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildProfileHeader(user),
                const SizedBox(height: 24),

                _buildInfoCard(
                  title: "Basic Information",
                  children: [
                    _infoRow("Full Name", user.fullName),
                    _divider(),
                    _infoRow("Username", "@${user.username}"),
                    _divider(),
                    _infoRow("Email", user.email),
                    _divider(),
                    _infoRow("Phone Number", user.phoneNumber),
                    _divider(),
                    _infoRow("City", user.city ?? 'N/A'),
                    _divider(),
                    _infoRow("Gender", user.gender ?? 'N/A'),
                  ],
                ),

                const SizedBox(height: 18),

                _buildInfoCard(
                  title: "Biography",
                  children: [
                    Text(
                      (user.bio != null && user.bio!.trim().isNotEmpty)
                          ? user.bio!
                          : 'No biography added',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _buildInfoCard(
                  title: "Skills",
                  children: [
                    _buildSkillsChips(user.skills),
                  ],
                ),

                const SizedBox(height: 18),

                _buildInfoCard(
                  title: "Portfolio Links",
                  children: [
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
                    if ((user.linkedin == null || user.linkedin!.isEmpty) &&
                        (user.github == null || user.github!.isEmpty))
                      Text(
                        "No portfolio links added",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
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
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightPurpleBG,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryPurple,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: primaryPurple.withOpacity(0.12),
      ),
    );
  }

  Widget _buildSkillsChips(dynamic skillsData) {
    List<String> skills = [];

    if (skillsData is List) {
      skills = skillsData.map((e) => e.toString()).toList();
    } else if (skillsData is String && skillsData.trim().isNotEmpty) {
      skills = skillsData.split(',').map((s) => s.trim()).toList();
    }

    if (skills.isEmpty) {
      return Text(
        "No skills added",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
        ),
      );
    }

    return Wrap(
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
    );
  }
}