import 'package:flutter/material.dart';
import '../../model/hackathon.dart';
import '../view/hackathon_details_view.dart';

class HackathonCard extends StatelessWidget {
  final Hackathon hackathon;
  final bool isPast;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showOrgName; // ✅ تعريف المتغير مرة واحدة فقط هنا

  const HackathonCard({
    super.key,
    required this.hackathon,
    required this.isPast,
    this.onEdit,
    this.onDelete,
    this.showOrgName = false, // ✅ استدعاء المتغير مرة واحدة فقط هنا
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);
  static const Color _orange = Color(0xFFFFA726);

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HackathonDetailsView(hackathon: hackathon),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _lightPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: icon + name + description ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_outlined, color: _purple, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hackathon.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _purple,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // ✅ إظهار اسم المنشأة فقط إذا كان showOrgName = true
                        if (showOrgName)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              hackathon.organizationName ?? "Organization",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                        const SizedBox(height: 4),
                        Text(
                          hackathon.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: _purple.withOpacity(0.15), thickness: 1, indent: 14, endIndent: 14, height: 1),

            // ── Info grid ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoChip(Icons.location_on_outlined, hackathon.city),
                        const SizedBox(height: 6),
                        _infoChip(Icons.calendar_today_outlined, _formatDate(hackathon.startDate)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoChip(Icons.groups_outlined, "Size: ${hackathon.teamSize}"),
                        const SizedBox(height: 6),
                        _infoChip(Icons.public_outlined, hackathon.mode),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Action buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPast)
                    _actionButton("Delete", Icons.delete_outline, Colors.red.shade400, onDelete)
                  else
                    _actionButton("Edit", Icons.edit_outlined, _orange, onEdit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback? action) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: action,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _purple),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}