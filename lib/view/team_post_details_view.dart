import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/team_post_model.dart';
import '../model/hackathon.dart';
import '../widgets/buildmate_app_bar.dart';
import 'request_to_join_view.dart';

class TeamPostDetailsView extends StatefulWidget {
  final TeamPostModel team;
  final Hackathon hackathon;

  const TeamPostDetailsView({
    super.key,
    required this.team,
    required this.hackathon
  });

  @override
  State<TeamPostDetailsView> createState() => _TeamPostDetailsViewState();
}

class _TeamPostDetailsViewState extends State<TeamPostDetailsView> {
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Team Details",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1️⃣ حالة الفريق واسمه (نفس ترتيب الهاكاثون)
            _buildSimpleStatusBadge(),
            const SizedBox(height: 12),

            Text(
              "Hackathon Team",
              style: TextStyle(fontWeight: FontWeight.bold, color: _purple.withOpacity(0.7), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              widget.team.teamName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),

            const SizedBox(height: 22),

            // 2️⃣ تفاصيل بوست الفريق في كرت بنفسجي
            _sectionTitle("Team Post Details"),
            _infoCard([
              _row(Icons.person_outline, "Leader's Role", widget.team.myRole),
              _row(Icons.wc_outlined, "Gender Preference", widget.team.genderPreference),
              _row(Icons.calendar_today_outlined, "Posted On", _formatDate(widget.team.createdAt)),
            ]),

            const SizedBox(height: 32),
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 24),

            // 3️⃣ سياق الهاكاثون
            Text(
              "By ${widget.hackathon.organizationName ?? 'Organizer'}",
              style: TextStyle(fontWeight: FontWeight.bold, color: _purple.withOpacity(0.7), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              widget.hackathon.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),

            const SizedBox(height: 16),
            _sectionTitle("Description"),
            Text(widget.hackathon.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),

            const SizedBox(height: 22),

            // 4️⃣ تفاصيل الهاكاثون في كرت بنفسجي
            _sectionTitle("Event Details"),
            _infoCard([
              _row(Icons.category_outlined, "Domain", widget.hackathon.domain),
              _row(Icons.public_outlined, "Mode", widget.hackathon.mode),
              _row(Icons.location_city_outlined, "City", widget.hackathon.city),
              if (widget.hackathon.location.isNotEmpty)
                _row(Icons.place_outlined, "Location", widget.hackathon.location),
              _row(Icons.groups_outlined, "Team Size",
                  widget.hackathon.teamSize > 2 ? "2 - ${widget.hackathon.teamSize} members" : "2 members"),
              _row(Icons.school_outlined, "Education", widget.hackathon.educationCriteria),
            ]),

            const SizedBox(height: 22),

            // 5️⃣ التواريخ المهمة في كرت بنفسجي
            _sectionTitle("Important Dates"),
            _infoCard([
              _row(Icons.calendar_month_outlined, "Registration Starts", _formatDate(widget.hackathon.applicationOpenDate)),
              _row(Icons.timer_outlined, "Registration Deadline", _formatDate(widget.hackathon.applicationDeadline)),
              _row(Icons.event_outlined, "Start Date", _formatDate(widget.hackathon.startDate)),
              _row(Icons.event_available_outlined, "End Date", _formatDate(widget.hackathon.endDate)),
            ]),

            const SizedBox(height: 16),

            // 6️⃣ الأدوار المطلوبة
            if (widget.hackathon.rolesNeeded.isNotEmpty) ...[
              _sectionTitle("Roles Needed"),
              _buildRolesSection(),
            ],

            const SizedBox(height: 40),

            // 7️⃣ زر طلب الانضمام
            _btn("Request to join team", _purple, () {
              // ✅ تعديل عشان ينقلك لصفحة الطلب بدل الـ Snackbar
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => RequestToJoinView(
                    team: widget.team,
                    hackathon: widget.hackathon
                ),
              ));
            }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers المطابقة لشاشة الهاكاثون ---

  Widget _buildSimpleStatusBadge() {
    return Row(
      children: [
        const Icon(Icons.person_search, color: _purple, size: 16),
        const SizedBox(width: 6),
        const Text("Looking for Members", style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _lightPurple, borderRadius: BorderRadius.circular(14)),
      child: Column(
          children: rows.expand((w) => [w, if (w != rows.last) Divider(color: _purple.withOpacity(0.1), height: 16)]).toList()
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: _purple),
      const SizedBox(width: 12),
      Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
    ]);
  }

  Widget _btn(String l, Color c, VoidCallback? a) {
    return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: c,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: a,
            child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold))
        )
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 12),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
    );
  }

  Widget _buildRolesSection() {
    return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.hackathon.rolesNeeded.map((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _purple.withOpacity(0.3))
            ),
            child: Text(r, style: const TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.w500))
        )).toList()
    );
  }
}