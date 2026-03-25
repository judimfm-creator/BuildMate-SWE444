import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/hackathon.dart';
import '../view/hackathon_details_view.dart';
import '../view/create_hackathon_view.dart';

class HackathonCard extends StatelessWidget {
  final Hackathon hackathon;
  final bool isPast;
  final VoidCallback? onEdit;

  const HackathonCard({
    super.key,
    required this.hackathon,
    required this.isPast,
    this.onEdit,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightBg = Color(0xFFF0EEFF);

  String _format(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool regNotStarted = now.isBefore(hackathon.applicationOpenDate);
    final bool regClosed = now.isAfter(hackathon.applicationDeadline);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hackathon.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _statusBadge(regNotStarted, regClosed),
              ],
            ),

            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1)),

            _infoRow(Icons.category_outlined, "Domain", hackathon.domain),
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, "Location",
                "${hackathon.city}, ${hackathon.mode}"),
            const SizedBox(height: 10),
            _infoRow(
                Icons.groups_outlined,
                "Team Size",
                hackathon.teamSize > 2
                    ? "2 - ${hackathon.teamSize} members"
                    : "2 members"),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _lightBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _dateRow(
                      "Registration Starts",
                      _format(hackathon.applicationOpenDate),
                      "Registration Deadline",
                      _format(hackathon.applicationDeadline),
                      isDeadline: true),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white)),
                  _dateRow("Event Starts", _format(hackathon.startDate),
                      "Event Ends", _format(hackathon.endDate)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Column(
              children: [
                // ✅ زر View Full Details — يظهر دائماً
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: _btn("View Full Details", _purple, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HackathonDetailsView(hackathon: hackathon),
                      ),
                    );
                  }),
                ),

                // ✅ زر Edit — يظهر فقط إذا مو Past
                if (!isPast) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: _btn("Edit", Colors.orange, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateHackathonView(hackathonToEdit: hackathon),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _purple),
        const SizedBox(width: 8),
        Text("$label: ",
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(
            child: Text(value,
                style:
                const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }

  Widget _dateRow(String l1, String d1, String l2, String d2,
      {bool isDeadline = false}) {
    return Row(
      children: [
        Expanded(child: _dateItem(l1, d1)),
        Container(width: 1, height: 20, color: _purple.withOpacity(0.2)),
        const SizedBox(width: 16),
        Expanded(child: _dateItem(l2, d2, isCritical: isDeadline)),
      ],
    );
  }

  Widget _dateItem(String label, String date, {bool isCritical = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold)),
        Text(date,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCritical ? Colors.redAccent : Colors.black)),
      ],
    );
  }

  Widget _statusBadge(bool ns, bool cl) {
    String label = "Registration Open";
    Color color = Colors.green;
    if (ns) {
      label = "Registration Opening Soon";
      color = Colors.orange;
    } else if (cl) {
      label = "Registration Closed";
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _btn(String label, Color color, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}
