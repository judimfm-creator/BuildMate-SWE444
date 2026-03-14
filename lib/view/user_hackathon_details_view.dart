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
  static const Color lightPurple = Color(0xFFF8F5FF);
  static const Color borderPurple = Color(0xFFE8DFF8);
  static const Color green = Color(0xFF7CB342);
  static const Color lightGreen = Color(0xFFEAF7DF);
  static const Color orange = Color(0xFFF39C12);
  static const Color lightOrange = Color(0xFFFFF3E0);
  static const Color blue = Color(0xFF1E88E5);
  static const Color lightBlue = Color(0xFFEAF4FF);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFF3F3F3);

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Map<String, dynamic> _getHackathonStatus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final registrationOpen = DateTime(
      hackathon.applicationOpenDate.year,
      hackathon.applicationOpenDate.month,
      hackathon.applicationOpenDate.day,
    );

    final registrationDeadline = DateTime(
      hackathon.applicationDeadline.year,
      hackathon.applicationDeadline.month,
      hackathon.applicationDeadline.day,
    );

    final start = DateTime(
      hackathon.startDate.year,
      hackathon.startDate.month,
      hackathon.startDate.day,
    );

    final end = DateTime(
      hackathon.endDate.year,
      hackathon.endDate.month,
      hackathon.endDate.day,
    );

    if (today.isBefore(registrationOpen)) {
      return {
        'label': 'Upcoming Registration',
        'color': orange,
        'bgColor': lightOrange,
      };
    }

    if ((today.isAtSameMomentAs(registrationOpen) ||
        today.isAfter(registrationOpen)) &&
        (today.isAtSameMomentAs(registrationDeadline) ||
            today.isBefore(registrationDeadline))) {
      return {
        'label': 'Registration Open',
        'color': blue,
        'bgColor': lightBlue,
      };
    }

    if ((today.isAtSameMomentAs(start) || today.isAfter(start)) &&
        (today.isAtSameMomentAs(end) || today.isBefore(end))) {
      return {
        'label': 'Ongoing',
        'color': green,
        'bgColor': lightGreen,
      };
    }

    if (today.isAfter(end)) {
      return {
        'label': 'Completed',
        'color': grey,
        'bgColor': lightGrey,
      };
    }

    return {
      'label': 'Upcoming',
      'color': orange,
      'bgColor': lightOrange,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = _getHackathonStatus();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: hackathon.name,
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBanner(status),
            const SizedBox(height: 18),
            _buildTitleBlock(),
            const SizedBox(height: 22),

            _sectionTitle("Event Details"),
            _softCard(
              child: Column(
                children: [
                  _infoRow(Icons.category_outlined, "Domain", hackathon.domain),
                  _divider(),
                  _infoRow(Icons.public_outlined, "Mode", hackathon.mode),
                  _divider(),
                  _infoRow(
                    Icons.groups_2_outlined,
                    "Team Size",
                    "${hackathon.teamSize} members",
                  ),
                  _divider(),
                  _infoRow(
                    Icons.school_outlined,
                    "Education",
                    hackathon.educationCriteria,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _sectionTitle("Location"),
            _softCard(
              child: Column(
                children: [
                  _infoRow(Icons.location_city_outlined, "City", hackathon.city),
                  _divider(),
                  _infoRow(Icons.place_outlined, "Location", hackathon.location),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _sectionTitle("Team Registration"),
            _softCard(
              child: Column(
                children: [
                  _infoRow(
                    Icons.how_to_reg_outlined,
                    "Registration Opens",
                    _formatDate(hackathon.applicationOpenDate),
                  ),
                  _divider(),
                  _infoRow(
                    Icons.event_busy_outlined,
                    "Registration Deadline",
                    _formatDate(hackathon.applicationDeadline),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _sectionTitle("Hackathon Dates"),
            _softCard(
              child: Column(
                children: [
                  _infoRow(
                    Icons.event_outlined,
                    "Start Date",
                    _formatDate(hackathon.startDate),
                  ),
                  _divider(),
                  _infoRow(
                    Icons.event_available_outlined,
                    "End Date",
                    _formatDate(hackathon.endDate),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _sectionTitle("Roles Needed"),
            hackathon.rolesNeeded.isEmpty
                ? const Text(
              "No roles specified",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            )
                : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: hackathon.rolesNeeded.map((role) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: purple.withOpacity(0.18),
                    ),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Color(0xFF5F4AA2),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(Map<String, dynamic> status) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.emoji_events_outlined,
              color: purple,
              size: 54,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: status['bgColor'],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (status['color'] as Color).withOpacity(0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: status['color'],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status['label'],
                    style: TextStyle(
                      color: status['color'],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hackathon.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4F3B8F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hackathon.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _softCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderPurple),
      ),
      child: child,
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: borderPurple,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: purple,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value.isEmpty ? "-" : value,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}