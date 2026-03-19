import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/hackathon.dart';
import '../widgets/buildmate_app_bar.dart';
import 'create_team_post_view.dart';
import 'hackathon_teams_view.dart' as teams_view;
import 'institution_team_posts_view.dart' as institution_posts;
import 'my_team_post_view.dart';

class HackathonDetailsView extends StatelessWidget {
  final Hackathon hackathon;

  const HackathonDetailsView({
    super.key,
    required this.hackathon,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getUserTeamPost({
    required String currentUid,
    required String hackathonId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final leaderResult = await firestore
        .collection('team_posts')
        .where('hackathonId', isEqualTo: hackathonId)
        .where('leaderId', isEqualTo: currentUid)
        .limit(1)
        .get();

    if (leaderResult.docs.isNotEmpty) {
      return leaderResult.docs.first;
    }

    final createdByResult = await firestore
        .collection('team_posts')
        .where('hackathonId', isEqualTo: hackathonId)
        .where('createdBy', isEqualTo: currentUid)
        .limit(1)
        .get();

    if (createdByResult.docs.isNotEmpty) {
      return createdByResult.docs.first;
    }

    final memberResult = await firestore
        .collection('team_posts')
        .where('hackathonId', isEqualTo: hackathonId)
        .where('members', arrayContains: currentUid)
        .limit(1)
        .get();

    if (memberResult.docs.isNotEmpty) {
      return memberResult.docs.first;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool isOngoing = !hackathon.endDate.isBefore(now);
    final bool isRegistrationOpen =
        !hackathon.applicationDeadline.isBefore(now);

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String? hackathonId = hackathon.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Hackathon Details",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: currentUid == null
          ? const Center(
              child: Text("No user is currently signed in."),
            )
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('organizations')
                  .doc(currentUid)
                  .get(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (roleSnapshot.hasError) {
                  return const Center(
                    child: Text("Failed to load user role."),
                  );
                }

                final bool isInstitution = roleSnapshot.data?.exists ?? false;

                if (isInstitution) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(isOngoing),
                        const SizedBox(height: 20),
                        Text(
                          hackathon.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _purple,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hackathon.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _sectionTitle("Event Details"),
                        const SizedBox(height: 10),
                        _infoCard([
                          _row(Icons.category_outlined, "Domain", hackathon.domain),
                          _row(Icons.public_outlined, "Mode", hackathon.mode),
                          _row(
                            Icons.groups_outlined,
                            "Team Size",
                            "${hackathon.teamSize} members",
                          ),
                          _row(
                            Icons.school_outlined,
                            "Education",
                            hackathon.educationCriteria,
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _sectionTitle("Important Dates"),
                        const SizedBox(height: 10),
                        _infoCard([
                          _row(
                            Icons.timer_outlined,
                            "Registration Deadline",
                            _formatDate(hackathon.applicationDeadline),
                          ),
                          _row(
                            Icons.event_outlined,
                            "Start Date",
                            _formatDate(hackathon.startDate),
                          ),
                          _row(
                            Icons.event_available_outlined,
                            "End Date",
                            _formatDate(hackathon.endDate),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _sectionTitle("Location"),
                        const SizedBox(height: 10),
                        _infoCard([
                          _row(Icons.location_city_outlined, "City", hackathon.city),
                          _row(Icons.place_outlined, "Location", hackathon.location),
                        ]),
                        const SizedBox(height: 16),
                        _sectionTitle("Roles Needed"),
                        const SizedBox(height: 10),
                        _buildRolesSection(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: hackathonId == null
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            institution_posts
                                                .InstitutionTeamPostsView(
                                          hackathonId: hackathonId,
                                        ),
                                      ),
                                    );
                                  },
                            child: const Text("View Team Posts"),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                }

                if (hackathonId == null) {
                  return const Center(
                    child: Text("Hackathon ID is missing."),
                  );
                }

                return FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
                  future: _getUserTeamPost(
                    currentUid: currentUid,
                    hackathonId: hackathonId,
                  ),
                  builder: (context, teamPostSnapshot) {
                    if (teamPostSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (teamPostSnapshot.hasError) {
                      return const Center(
                        child: Text("Failed to load team post status."),
                      );
                    }

                    final userTeamPostDoc = teamPostSnapshot.data;
                    final bool hasTeamPost = userTeamPostDoc != null;
                    final String? userTeamPostId = userTeamPostDoc?.id;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(isOngoing),
                          const SizedBox(height: 20),
                          Text(
                            hackathon.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _purple,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hackathon.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle("Event Details"),
                          const SizedBox(height: 10),
                          _infoCard([
                            _row(Icons.category_outlined, "Domain", hackathon.domain),
                            _row(Icons.public_outlined, "Mode", hackathon.mode),
                            _row(
                              Icons.groups_outlined,
                              "Team Size",
                              "${hackathon.teamSize} members",
                            ),
                            _row(
                              Icons.school_outlined,
                              "Education",
                              hackathon.educationCriteria,
                            ),
                          ]),
                          const SizedBox(height: 16),
                          _sectionTitle("Important Dates"),
                          const SizedBox(height: 10),
                          _infoCard([
                            _row(
                              Icons.timer_outlined,
                              "Registration Deadline",
                              _formatDate(hackathon.applicationDeadline),
                            ),
                            _row(
                              Icons.event_outlined,
                              "Start Date",
                              _formatDate(hackathon.startDate),
                            ),
                            _row(
                              Icons.event_available_outlined,
                              "End Date",
                              _formatDate(hackathon.endDate),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          _sectionTitle("Location"),
                          const SizedBox(height: 10),
                          _infoCard([
                            _row(Icons.location_city_outlined, "City", hackathon.city),
                            _row(Icons.place_outlined, "Location", hackathon.location),
                          ]),
                          const SizedBox(height: 16),
                          _sectionTitle("Roles Needed"),
                          const SizedBox(height: 10),
                          _buildRolesSection(),
                          const SizedBox(height: 24),

                          if (hasTeamPost) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: userTeamPostId == null
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MyTeamPostView(
                                              teamPostId: userTeamPostId,
                                              hackathonId: hackathonId,
                                              hackathonTeamSize:
                                                  hackathon.teamSize,
                                            ),
                                          ),
                                        );
                                      },
                                child: const Text("My Team Post"),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isRegistrationOpen ? _purple : Colors.grey,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isRegistrationOpen
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CreateTeamPostScreen(
                                              hackathonId: hackathonId,
                                              hackathonTeamSize:
                                                  hackathon.teamSize,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: const Text("Create My Team Post"),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      isRegistrationOpen ? _purple : Colors.grey,
                                  side: BorderSide(
                                    color: isRegistrationOpen
                                        ? _purple
                                        : Colors.grey,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isRegistrationOpen
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                teams_view.HackathonTeamsView(
                                              hackathonId: hackathonId,
                                              hackathonTeamSize:
                                                  hackathon.teamSize,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: const Text("Join Existing Team"),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          if (!isRegistrationOpen)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                "Registration is closed. Team creation and joining are no longer available after the deadline.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildHeaderCard(bool isOngoing) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 65,
            color: _purple,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isOngoing ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOngoing
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                isOngoing ? "🟢 Ongoing" : "🔴 Ended",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOngoing
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    if (hackathon.rolesNeeded.isEmpty) {
      return Text(
        "No roles specified.",
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hackathon.rolesNeeded.map((role) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _lightPurple,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _purple.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            role,
            style: const TextStyle(
              fontSize: 12,
              color: _purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    final List<Widget> children = [];

    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);

      if (i != rows.length - 1) {
        children.add(
          Divider(
            color: _purple.withValues(alpha: 0.1),
            height: 16,
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _row(IconData icon, String label, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _purple),
        const SizedBox(width: 10),
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value?.toString() ?? "-",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}