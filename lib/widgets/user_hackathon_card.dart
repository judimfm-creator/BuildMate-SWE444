import 'package:flutter/material.dart';
import '../model/hackathon.dart';
import '../view/user_hackathon_details_view.dart';

class UserHackathonCard extends StatelessWidget {
  final Hackathon hackathon;
  final int currentMembers;
  final bool isPrevious;

  const UserHackathonCard({
    super.key,
    required this.hackathon,
    required this.currentMembers,
    this.isPrevious = false,
  });

  static const Color _purple = Color(0xFF6D56B3);

  String _formatDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Widget _infoRow(IconData icon, String text, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _purple),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? Colors.grey.shade700,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusText = isPrevious ? "COMPLETED" : "ONGOING";
    final statusColor = isPrevious ? Colors.grey : Colors.green;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    hackathon.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusBadge(statusText, statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 14, color: _purple),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    hackathon.organizationName ?? "Organizer",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _purple.withOpacity(0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text(
              "Description",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                hackathon.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 14),
            _infoRow(
              Icons.location_on_outlined,
              "${hackathon.city}, ${hackathon.location}",
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.calendar_today_outlined,
              "${_formatDate(hackathon.startDate)} → ${_formatDate(hackathon.endDate)}",
            ),
            const SizedBox(height: 8),
            _infoRow(
              isPrevious
                  ? Icons.event_available_outlined
                  : Icons.groups_outlined,
              isPrevious
                  ? "Ended on: ${_formatDate(hackathon.endDate)}"
                  : "Current Team: $currentMembers/${hackathon.teamSize} members",
              textColor: isPrevious ? Colors.grey.shade700 : null,
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.public_outlined,
              hackathon.mode,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserHackathonDetailsView(
                        hackathon: hackathon,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text("View Details"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}