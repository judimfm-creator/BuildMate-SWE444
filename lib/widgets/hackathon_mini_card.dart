import 'package:flutter/material.dart';
import '../../model/hackathon.dart';
import '../view/hackathon_details_view.dart';
import 'package:intl/intl.dart';
import '../view/create_hackathon_view.dart';

class HackathonMiniCard extends StatelessWidget {
  final Hackathon hackathon;
  final bool isPast;

  const HackathonMiniCard({
    super.key,
    required this.hackathon,
    this.isPast = false,
  });

  static const Color _purple = Color(0xFF6D56B3);

  String _format(DateTime d) => DateFormat('MMM dd').format(d);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool regNotStarted = now.isBefore(hackathon.applicationOpenDate);
    final bool regClosed = now.isAfter(hackathon.applicationDeadline);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    hackathon.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: _statusBadge(regNotStarted, regClosed)),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),

            _infoRow(Icons.category_outlined, hackathon.domain),
            const SizedBox(height: 10),
            _infoRow(
              Icons.location_on_outlined,
              "${hackathon.city}, ${hackathon.mode}",
            ),
            const SizedBox(height: 10),
            _infoRow(
              Icons.groups_outlined,
              hackathon.teamSize > 2
                  ? "2 - ${hackathon.teamSize} members"
                  : "2 members",
            ),

            const SizedBox(height: 16),

            // Deadline box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: Colors.red),
                      SizedBox(width: 6),
                      Text("Deadline:", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text(
                    _format(hackathon.applicationDeadline),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // View Full Details Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HackathonDetailsView(hackathon: hackathon),
                    ),
                  );
                },
                child: const Text(
                  "View Full Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Edit Button (Only shows if not past)
            if (!isPast) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: const BorderSide(color: _purple, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateHackathonView(hackathonToEdit: hackathon),
                      ),
                    );
                  },
                  child: const Text(
                    "Edit",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool ns, bool cl) {
    String label = "Open";
    Color color = Colors.green;
    if (ns) {
      label = "Opening Soon";
      color = Colors.orange;
    } else if (cl) {
      label = "Closed";
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _purple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}