import 'package:flutter/material.dart';
import '../model/team_model.dart';
import '../services/team_service.dart';
import '../widgets/buildmate_app_bar.dart';
import 'team_members_view.dart';

class HackathonTeamsView extends StatelessWidget {
  final String hackathonId;
  final int teamSize;

  const HackathonTeamsView({
    super.key,
    required this.hackathonId,
    required this.teamSize,
  });

  @override
  Widget build(BuildContext context) {
    final teamService = TeamService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: BuildMateAppBar(
        titleText: "Teams",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream: teamService.getTeamsByHackathon(hackathonId),
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
              final bool isFull = team.membersCount >= teamSize;
              final int availableSlots =
              (teamSize - team.membersCount).clamp(0, teamSize);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildTeamCard(
                  context,
                  team,
                  isFull,
                  availableSlots,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(
      BuildContext context,
      TeamModel team,
      bool isFull,
      int availableSlots,
      ) {
    const Color purple = Color(0xFF7A62B3);
    const Color lightPurple = Color(0xFFF1ECFB);
    const Color orange = Color(0xFFFFB22C);

    final String genderText =
    (team.genderPreference?.isNotEmpty == true) ? team.genderPreference! : "Any";

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
                  text: "Members: ${team.membersCount} / $teamSize",
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
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
                          isFull
                              ? "This team is full"
                              : "Join request flow will be added later",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFull ? Colors.grey : orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text(
                    "Join",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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