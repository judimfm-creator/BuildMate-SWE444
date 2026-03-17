import 'package:flutter/material.dart';
import '../../model/hackathon.dart';
import '../widgets/buildmate_app_bar.dart';

class HackathonDetailsView extends StatelessWidget {
  final Hackathon hackathon;
  const HackathonDetailsView({super.key, required this.hackathon});

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  @override
  Widget build(BuildContext context) {
    final bool isOngoing = hackathon.endDate.isAfter(DateTime.now());

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
            // ── Banner ──
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 65, color: _purple),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOngoing
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
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
            ),
            const SizedBox(height: 20),

            // ── العنوان واسم المنشأة (التعديل هنا) ──
            Text(hackathon.name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _purple)),
            
            const SizedBox(height: 8),

            // ✅ اسم المنشأة تحت العنوان مباشرة
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 18, color: _purple),
                const SizedBox(width: 8),
                Text(
                  "Organized by: ${hackathon.organizationName ?? "ksu"}",
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _purple),
                ),
              ],
            ),

            const SizedBox(height: 15),
            Text(hackathon.description,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.6)),
            const SizedBox(height: 22),

            _sectionTitle("Event Details"),
            const SizedBox(height: 10),
            _infoCard([
              _row(Icons.category_outlined, "Domain", hackathon.domain),
              _row(Icons.public_outlined, "Mode", hackathon.mode),
              _row(Icons.groups_outlined, "Team Size",
                  "${hackathon.teamSize} members"),
              _row(Icons.school_outlined, "Education",
                  hackathon.educationCriteria),
            ]),
            const SizedBox(height: 16),

            // ── المواعيد المهمة (التعديل هنا) ──
            _sectionTitle("Important Dates"),
            const SizedBox(height: 10),
            _infoCard([
              // ✅ تاريخ انتهاء التسجيل أضفته هنا
              _row(Icons.timer_outlined, "Registration Deadline",
                  _formatDate(hackathon.applicationDeadline)),
              _row(Icons.event_outlined, "Start Date",
                  _formatDate(hackathon.startDate)),
              _row(Icons.event_available_outlined, "End Date",
                  _formatDate(hackathon.endDate)),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hackathon.rolesNeeded
                  .map((r) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _lightPurple,
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: _purple.withOpacity(0.3)),
                ),
                child: Text(r,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _purple,
                        fontWeight: FontWeight.w500)),
              ))
                  .toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87));

  Widget _infoCard(List<Widget> rows) => Container(
    width: double.infinity,
    padding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _lightPurple,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: rows
          .expand((w) => [
        w,
        Divider(
            color: _purple.withOpacity(0.1), height: 16)
      ])
          .toList()
        ..removeLast(),
    ),
  );

  Widget _row(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: _purple),
      const SizedBox(width: 10),
      Text("$label: ",
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87)),
      Expanded(
        child: Text(value,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade700)),
      ),
    ],
  );
}