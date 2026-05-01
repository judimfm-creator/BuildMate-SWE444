import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/hackathon.dart';
import '../model/org_model.dart';
import '../widgets/buildmate_app_bar.dart';
import 'create_team_post_view.dart';
import 'hackathon_teams_view.dart' as teams_view;
import 'institution_team_posts_view.dart' as institution_posts;
import 'institution_public_profile_page.dart';
import 'my_team_post_view.dart';

class HackathonDetailsView extends StatefulWidget {
  final Hackathon hackathon;

  const HackathonDetailsView({
    super.key,
    required this.hackathon,
  });

  @override
  State<HackathonDetailsView> createState() => _HackathonDetailsViewState();
}

class _HackathonDetailsViewState extends State<HackathonDetailsView> {
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getUserTeamPost(
    String uid,
    String hid,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final leader = await firestore
        .collection('team_posts')
        .where('hackathonId', isEqualTo: hid)
        .where('createdBy', isEqualTo: uid)
        .limit(1)
        .get();

    if (leader.docs.isNotEmpty) return leader.docs.first;

    final member = await firestore
        .collection('team_posts')
        .where('hackathonId', isEqualTo: hid)
        .where('members', arrayContains: uid)
        .limit(1)
        .get();

    if (member.docs.isNotEmpty) return member.docs.first;

    return null;
  }

  Future<void> _openInstitutionProfile(BuildContext context) async {
    try {
      final orgId = widget.hackathon.organizationId;

      final doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .get();

      if (!doc.exists || doc.data() == null) return;

      final org = OrgModel.fromMap(doc.data()!);

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InstitutionPublicProfilePage(
            org: org,
            orgId: orgId,
          ),
        ),
      );
    } catch (e) {
      // keep silent to avoid breaking UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime deadlineDateTime = DateTime(
      widget.hackathon.applicationDeadline.year,
      widget.hackathon.applicationDeadline.month,
      widget.hackathon.applicationDeadline.day,
      23,
      59,
      59,
    );

    final bool isEventEnded = widget.hackathon.endDate.isBefore(now);
    final bool regNotStarted =
        now.isBefore(widget.hackathon.applicationOpenDate);
    final bool regClosed = now.isAfter(deadlineDateTime);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Hackathon Details",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: currentUid == null
          ? const Center(child: Text("Please sign in."))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('organizations')
                  .doc(currentUid)
                  .get(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _purple),
                  );
                }

                final bool isInstitution = roleSnapshot.data?.exists ?? false;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSimpleStatusBadge(
                        regNotStarted,
                        regClosed,
                        isEventEnded,
                      ),
                      const SizedBox(height: 12),

                      if (!isInstitution) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _lightPurple,
                              side: BorderSide(
                                color: _purple.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                            onPressed: () => _openInstitutionProfile(context),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  color: _purple,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "View Organizer Profile",
                                    style: TextStyle(
                                      color: _purple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: _purple,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Text(
                        widget.hackathon.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),
                      _sectionTitle("Description"),
                      Text(
                        widget.hackathon.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 22),
                      _sectionTitle("Event Details"),
                      _infoCard([
                        _row(
                          Icons.category_outlined,
                          "Domain",
                          widget.hackathon.domain,
                        ),
                        _row(
                          Icons.public_outlined,
                          "Mode",
                          widget.hackathon.mode,
                        ),
                        _row(
                          Icons.location_city_outlined,
                          "City",
                          widget.hackathon.city,
                        ),
                        _row(
                          Icons.place_outlined,
                          "Location",
                          widget.hackathon.location,
                        ),
                        _row(
                          Icons.groups_outlined,
                          "Team Size",
                          widget.hackathon.teamSize > 2
                              ? "2 - ${widget.hackathon.teamSize} members"
                              : "2 members",
                        ),
                        _row(
                          Icons.school_outlined,
                          "Education",
                          widget.hackathon.educationCriteria,
                        ),
                      ]),

                      const SizedBox(height: 16),
                      if (!isInstitution) _buildRequirementNote(),

                      const SizedBox(height: 16),
                      _sectionTitle("Important Dates"),
                      _infoCard([
                        _row(
                          Icons.calendar_month_outlined,
                          "Registration Starts",
                          _formatDate(widget.hackathon.applicationOpenDate),
                        ),
                        _row(
                          Icons.timer_outlined,
                          "Registration Deadline",
                          _formatDate(widget.hackathon.applicationDeadline),
                        ),
                        _row(
                          Icons.event_outlined,
                          "Start Date",
                          _formatDate(widget.hackathon.startDate),
                        ),
                        _row(
                          Icons.event_available_outlined,
                          "End Date",
                          _formatDate(widget.hackathon.endDate),
                        ),
                      ]),

                      const SizedBox(height: 16),
                      if (widget.hackathon.rolesNeeded.isNotEmpty) ...[
                        _sectionTitle("Roles Needed"),
                        _buildRolesSection(),
                      ],

                      const SizedBox(height: 30),
                      _buildActionButtons(
                        context,
                        isInstitution,
                        currentUid,
                        regNotStarted,
                        regClosed,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSimpleStatusBadge(bool ns, bool cl, bool ended) {
    String label = "Registration Open";
    Color color = const Color(0xFF6D56B3);
    IconData icon = Icons.check_circle_outline;

    if (ended) {
      label = "Hackathon Ended";
      color = Colors.blueGrey;
      icon = Icons.event_available;
    } else if (cl) {
      label = "Registration Closed";
      color = Colors.grey.shade500;
      icon = Icons.lock_outline;
    } else if (ns) {
      label = "Registration Upcoming Soon";
      color = Colors.orange;
      icon = Icons.timer_outlined;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: rows
            .expand(
              (w) => [
                w,
                if (w != rows.last)
                  Divider(
                    color: _purple.withOpacity(0.1),
                    height: 16,
                  ),
              ],
            )
            .toList(),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _purple),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isInst,
    String uid,
    bool notStarted,
    bool closed,
  ) {
    final String hid = widget.hackathon.id ?? "";

    if (isInst) {
      return _btn(
        "View Teams Submission",
        _purple,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                institution_posts.InstitutionTeamPostsView(hackathonId: hid),
          ),
        ),
      );
    }

    return FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
      future: _getUserTeamPost(uid, hid),
      builder: (context, teamSnap) {
        if (teamSnap.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        if (teamSnap.hasData && teamSnap.data != null) {
          final teamData = teamSnap.data!.data();
          final String teamPostId = teamSnap.data!.id;
          final bool isOwner = teamData['createdBy'] == uid;

          if (isOwner) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('join_requests')
                  .where('teamPostId', isEqualTo: teamPostId)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, requestSnapshot) {
                final int pendingCount = requestSnapshot.data?.docs.length ?? 0;

                return _btn(
                  "Manage My Team",
                  _purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyTeamPostView(
                          teamPostId: teamPostId,
                          hackathonId: hid,
                          hackathonTeamSize: widget.hackathon.teamSize,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  badgeCount: pendingCount,
                );
              },
            );
          }

          return _btn(
            "View My Team",
            _purple,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyTeamPostView(
                    teamPostId: teamPostId,
                    hackathonId: hid,
                    hackathonTeamSize: widget.hackathon.teamSize,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('join_requests')
              .where('hackathonId', isEqualTo: hid)
              .where('requesterId', isEqualTo: uid)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, requestSnapshot) {
            final bool hasPendingRequest =
                requestSnapshot.hasData &&
                    requestSnapshot.data!.docs.isNotEmpty;

            if (closed) {
              return _btn("Registration Closed", Colors.grey, null);
            }

            if (notStarted) {
              return Column(
                children: [
                  _btn("Create Team Post (Opening Soon)", Colors.grey, null),
                  const SizedBox(height: 12),
                  _outlinedBtn(
                    "Join Existing Team (Opening Soon)",
                    Colors.grey,
                    null,
                  ),
                ],
              );
            }

            if (hasPendingRequest) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      "You already sent a join request for a team in this hackathon. Please wait for the team leader's response.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  _btn("Create Team Post", Colors.grey, null),
                  const SizedBox(height: 12),
                  _outlinedBtn("Request Pending", Colors.orange, null),
                ],
              );
            }

            return Column(
              children: [
                _btn(
                  "Create Team Post",
                  _purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTeamPostScreen(
                        hackathonId: hid,
                        hackathonTeamSize: widget.hackathon.teamSize,
                      ),
                    ),
                  ).then((_) => setState(() {})),
                ),
                const SizedBox(height: 12),
                _outlinedBtn(
                  "Join Existing Team",
                  _purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => teams_view.ExploreTeamsView(
                        hackathonId: hid,
                        hackathonTeamSize: widget.hackathon.teamSize,
                      ),
                    ),
                  ).then((_) => setState(() {})),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _btn(
    String l,
    Color c,
    VoidCallback? a, {
    int badgeCount = 0,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: a,
                child: Text(
                  l,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -4,
                top: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _outlinedBtn(String l, Color c, VoidCallback? a) => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: c,
            side: BorderSide(color: c),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: a,
          child: Text(
            l,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildRolesSection() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.hackathon.rolesNeeded
            .map(
              (r) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _purple.withOpacity(0.3)),
                ),
                child: Text(
                  r,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _purple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      );

  Widget _buildRequirementNote() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Note: You must have at least 2 members to register",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}