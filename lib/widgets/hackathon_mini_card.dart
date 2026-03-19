import 'package:flutter/material.dart';
import '../../model/hackathon.dart';
import '../view/hackathon_details_view.dart';

/// كارد صغير يُستخدم في الهوم بيج (horizontal scroll)
class HackathonMiniCard extends StatelessWidget {
  final Hackathon hackathon;
  final bool showOrgName; // ✅ أضفنا تعريف المتغير هنا

  const HackathonMiniCard({
    super.key, 
    required this.hackathon, 
    this.showOrgName = false, // ✅ أضفناه هنا في الكونستركتور
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HackathonDetailsView(hackathon: hackathon)),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _lightPurple,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.13),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Center(
                child: Icon(Icons.emoji_events_outlined,
                    color: _purple, size: 36),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hackathon.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _purple,
                    ),
                    maxLines: 1, // قللت الأسطر هنا عشان نترك مساحة لاسم المنظمة
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // ✅ عرض اسم المنظمة إذا كان showOrgName = true
                  if (showOrgName)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        hackathon.organizationName ?? "Organization",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 5),
                  _miniRow(Icons.calendar_today_outlined,
                      _formatDate(hackathon.startDate)),
                  const SizedBox(height: 3),
                  _miniRow(Icons.location_on_outlined,
                      "${hackathon.city}"), // اختصرتها للمدينة بس عشان المساحة
                  const SizedBox(height: 3),
                  _miniRow(Icons.groups_outlined,
                      "Team: ${hackathon.teamSize}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 11, color: _purple),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}