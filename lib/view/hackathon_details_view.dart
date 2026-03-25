import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/hackathon.dart';
import '../widgets/buildmate_app_bar.dart';
import 'create_team_post_view.dart';
import 'hackathon_teams_view.dart' as teams_view;
import 'institution_team_posts_view.dart' as institution_posts;
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
  static const Color _bgColor = Color(0xFFF8F5FF);
  static const Color _cardBorder = Color(0xFFD8CCF3);
  static const Color _softText = Color(0xFF6E6785);
  static const Color _titleColor = Color(0xFF4B3F72);
  static const Color _orange = Color(0xFFFF9F2E);
  static const Color _red = Color(0xFFE57373);
  static const Color _green = Color(0xFF6D56B3);

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

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool isEventEnded = widget.hackathon.endDate.isBefore(now);
    final bool regNotStarted =
        now.isBefore(widget.hackathon.applicationOpenDate);
    final bool regClosed = now.isAfter(widget.hackathon.applicationDeadline);
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: BuildMateAppBar(
        titleText: "Hackathon Details",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: currentUid == null
          ? const Center(
              child: Text(
                "Please sign in.",
                style: TextStyle(
                  color: _titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
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
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _lightPurple,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSimpleStatusBadge(regNotStarted, regClosed),
                        const SizedBox(height: 12),

                        if (!isInstitution) ...[
                          Text(
                            "By ${widget.hackathon.organizationName ?? 'Organizer'}",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _purple.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        Text(
                          widget.hackathon.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _titleColor,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (widget.hackathon.startDate != null &&
                            widget.hackathon.endDate != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              "${_formatDate(widget.hackathon.startDate)} - ${_formatDate(widget.hackathon.endDate)}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: _softText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),
                        _sectionTitle("Description"),
                        _infoCard([
                          Text(
                            widget.hackathon.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.7,
                            ),
                          ),
                        ]),

                        const SizedBox(height: 20),
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

                        const SizedBox(height: 20),
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

                        const SizedBox(height: 20),
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
                          isEventEnded,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSimpleStatusBadge(bool notStarted, bool closed) {
    String label = "Registration Open";
    Color color = _green;
    IconData icon = Icons.check_circle_outline;

    if (notStarted) {
      label = "Upcoming";
      color = _orange;
      icon = Icons.schedule_outlined;
    } else if (closed) {
      label = "Registration Closed";
      color = _red;
      icon = Icons.lock_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .expand(
              (w) => [
                w,
                if (w != rows.last)
                  Divider(
                    color: _purple.withOpacity(0.10),
                    height: 18,
                  ),
              ],
            )
            .toList(),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _purple),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _titleColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: _softText,
              height: 1.5,
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
    bool isEventEnded,
  ) {
    final String hid = widget.hackathon.id ?? "";

    if (isInst) {
      return _btn(
        "View Hackathons",
        _purple,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => institution_posts.InstitutionTeamPostsView(
              hackathonId: hid,
            ),
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
          final bool isOwner = teamSnap.data!.data()['createdBy'] == uid;

          return _btn(
            isOwner ? "Manage My Team" : "View My Team",
            _purple,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyTeamPostView(
                    teamPostId: teamSnap.data!.id,
                    hackathonId: hid,
                    hackathonTeamSize: widget.hackathon.teamSize,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          );
        }

        return Column(
          children: [
            if (closed || isEventEnded)
              _btn(
                "Registration Closed",
                Colors.grey,
                null,
              )
            else if (notStarted) ...[
              _btn(
                "Create Team Post (Opening Soon)",
                Colors.grey,
                null,
              ),
              const SizedBox(height: 12),
              _outlinedBtn(
                "Join Existing Team (Opening Soon)",
                Colors.grey,
                null,
              ),
            ] else ...[
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
          ],
        );
      },
    );
  }

  Widget _btn(String label, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _outlinedBtn(String label, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: _titleColor,
        ),
      ),
    );
  }

  Widget _buildRolesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.hackathon.rolesNeeded
          .map(
            (r) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _purple.withOpacity(0.25),
                ),
              ),
              child: Text(
                r,
                style: const TextStyle(
                  fontSize: 12,
                  color: _purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRequirementNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withOpacity(0.18)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: _purple, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Note: You must have at least 2 members to register",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}