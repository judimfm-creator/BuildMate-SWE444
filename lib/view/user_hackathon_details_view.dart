import 'package:flutter/material.dart';
import '../model/hackathon.dart';
import '../widgets/buildmate_app_bar.dart';

class UserHackathonDetailsView extends StatelessWidget {
  final Hackathon hackathon;

  const UserHackathonDetailsView({
    super.key,
    required this.hackathon,
  });

  static const Color purple = Color(0xFF6D56B3);
  static const Color lightPurple = Color(0xFFF0EEFF);

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool regNotStarted = now.isBefore(hackathon.applicationOpenDate);
    final bool regClosed = now.isAfter(hackathon.applicationDeadline);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Hackathon Details",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSimpleStatusBadge(regNotStarted, regClosed),
            const SizedBox(height: 12),

            Text(
              "By ${hackathon.organizationName ?? 'Organizer'}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: purple.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              hackathon.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            _sectionTitle("Description"),
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
            _infoCard([
              _row(Icons.category_outlined, "Domain", hackathon.domain),
              _row(Icons.public_outlined, "Mode", hackathon.mode),
              _row(Icons.location_city_outlined, "City", hackathon.city),
              _row(Icons.place_outlined, "Location", hackathon.location),
              _row(
                Icons.groups_outlined,
                "Team Size",
                hackathon.teamSize > 2
                    ? "2 - ${hackathon.teamSize} members"
                    : "2 members",
              ),
              _row(
                Icons.school_outlined,
                "Education",
                hackathon.educationCriteria,
              ),
            ]),

            const SizedBox(height: 16),

            _sectionTitle("Important Dates"),
            _infoCard([
              _row(
                Icons.calendar_month_outlined,
                "Registration Starts",
                _formatDate(hackathon.applicationOpenDate),
              ),
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

            if (hackathon.rolesNeeded.isNotEmpty) ...[
              _sectionTitle("Roles Needed"),
              _buildRolesSection(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStatusBadge(bool regNotStarted, bool regClosed) {
    String label = "Registration Open";
    Color color = Colors.green;

    if (regNotStarted) {
      label = "Upcoming";
      color = Colors.orange;
    } else if (regClosed) {
      label = "Registration Closed";
      color = Colors.red;
    }

    return Row(
      children: [
        Icon(
          regClosed ? Icons.lock_outline : Icons.check_circle_outline,
          color: color,
          size: 16,
        ),
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
        color: lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: rows
            .expand(
              (w) => [
            w,
            if (w != rows.last)
              Divider(
                color: purple.withOpacity(0.1),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: purple),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRolesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hackathon.rolesNeeded
          .map(
            (role) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: purple.withOpacity(0.3),
            ),
          ),
          child: Text(
            role,
            style: const TextStyle(
              fontSize: 12,
              color: purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}