import 'package:flutter/material.dart';

import '../model/hackathon.dart';
import '../model/team_model.dart';
import '../services/team_service.dart';
import '../widgets/buildmate_app_bar.dart';
import 'team_members_view.dart';

class HackathonTeamsView extends StatelessWidget {
  final Hackathon hackathon;

  const HackathonTeamsView({
    super.key,
    required this.hackathon,
  });

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isRegistrationOpen(Hackathon hackathon) {
    final today = _dateOnly(DateTime.now());
    final open = _dateOnly(hackathon.applicationOpenDate);
    final deadline = _dateOnly(hackathon.applicationDeadline);

    final opened = today.isAtSameMomentAs(open) || today.isAfter(open);
    final notClosed =
        today.isAtSameMomentAs(deadline) || today.isBefore(deadline);

    return opened && notClosed;
  }

  @override
  Widget build(BuildContext context) {
    final teamService = TeamService();
    final bool registrationOpen = _isRegistrationOpen(hackathon);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: BuildMateAppBar(
        titleText: "Teams",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          if (!registrationOpen)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD8A8)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFE67E22)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Registration is closed. You can still view teams, but you cannot join now.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A5A00),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<TeamModel>>(
              stream: teamService.getTeamsByHackathon(hackathon.id ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Something went wrong",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teams = snapshot.data ?? [];

                if (teams.isEmpty) {
                  return const Center(
                    child: Text(
                      "No teams yet",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final bool isFull =
                        team.membersCount >= hackathon.teamSize;
                    final int availableSlots =
                    (hackathon.teamSize - team.membersCount)
                        .clamp(0, hackathon.teamSize);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildTeamCard(
                        context,
                        team,
                        isFull,
                        availableSlots,
                        registrationOpen,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(
      BuildContext context,
      TeamModel team,
      bool isFull,
      int availableSlots,
      bool registrationOpen,
      ) {
    const Color purple = Color(0xFF7A62B3);
    const Color lightPurple = Color(0xFFF1ECFB);
    const Color orange = Color(0xFFFFB22C);

    final String genderText =
    (team.genderPreference?.isNotEmpty == true)
        ? team.genderPreference!
        : "Any";

    String joinButtonText = "Join";
    Color joinButtonColor = orange;

    if (!registrationOpen) {
      joinButtonText = "Closed";
      joinButtonColor = Colors.grey;
    } else if (isFull) {
      joinButtonText = "Full";
      joinButtonColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: purple,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isFull
                          ? "This team is full"
                          : "$availableSlots slot${availableSlots == 1 ? '' : 's'} available",
                      style: TextStyle(
                        color: isFull ? Colors.red.shade400 : Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoColumn(
                  icon: Icons.people_alt_outlined,
                  text: "Members: ${team.membersCount} / ${hackathon.teamSize}",
                ),
              ),
              Expanded(
                child: _buildInfoColumn(
                  icon: Icons.wc_outlined,
                  text: "Gender: $genderText",
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _buildInfoColumn(
            icon: Icons.badge_outlined,
            text: team.rolesNeeded.isNotEmpty
                ? "Roles: ${team.rolesNeeded.join(', ')}"
                : "Roles: Not specified",
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (team.memberIds.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamMembersView(
                          memberIds: team.memberIds,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people_outline_rounded, size: 18),
                  label: const Text(
                    "View Members",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    side: const BorderSide(color: purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                )
              else
                const SizedBox(),

              SizedBox(
                width: 120,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !registrationOpen
                              ? "Registration is currently closed"
                              : isFull
                              ? "This team is full"
                              : "Join request flow will be handled later",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: joinButtonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text(
                    joinButtonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconBox() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E0F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.groups_rounded,
        color: Color(0xFF7A62B3),
        size: 36,
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFF7A62B3),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}