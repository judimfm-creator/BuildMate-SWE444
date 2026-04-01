import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/hackathon.dart';
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
    // ✅ تحديد الموعد النهائي الدقيق (نهاية اليوم 23:59:59)
    final deadlineDateTime = DateTime(
      hackathon.applicationDeadline.year,
      hackathon.applicationDeadline.month,
      hackathon.applicationDeadline.day,
      23, 59, 59,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // ✅ لضمان محاذاة البادج مع أول سطر
              children: [
                Expanded(
                  child: Text(
                    hackathon.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    // ✅ حل مشكلة الـ Wrap لاسم الهاكاثون
                    softWrap: true,
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(deadlineDateTime), // نمرر التوقيت الدقيق هنا
              ],
            ),
            const Divider(height: 20),
            _infoRow(Icons.category_outlined, hackathon.domain),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on_outlined, "${hackathon.city}, ${hackathon.mode}"),
            const SizedBox(height: 8),
            _infoRow(Icons.groups_outlined, hackathon.teamSize > 2 ? "2 - ${hackathon.teamSize} members" : "2 members"),
            
            const SizedBox(height: 15),
            
            // قسم التواريخ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lightBg.withOpacity(0.5), 
                borderRadius: BorderRadius.circular(16)
              ),
              child: Column(
                children: [
                  _dateRow("Reg. Starts", _format(hackathon.applicationOpenDate), "Reg. Deadline", _format(hackathon.applicationDeadline), isDeadline: true),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(color: Colors.white)),
                  _dateRow("Event Starts", _format(hackathon.startDate), "Event Ends", _format(hackathon.endDate)),
                ],
              ),
            ),

            const SizedBox(height: 15),
            
            // زر التفاصيل
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HackathonDetailsView(hackathon: hackathon),
                    ),
                  );
                },
                child: Text(
                  isPast ? "View Details" : "View Details & Teams",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (!isPast) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _purple, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateHackathonView(hackathonToEdit: hackathon),
                    ),
                  ),
                  child: const Text(
                    "Edit",
                    style: TextStyle(
                      color: _purple,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

 Widget _statusBadge(DateTime deadlineDateTime) {
  final DateTime now = DateTime.now();
  
  // ✅ فحص دقيق للحالات بناءً على الوقت الحالي
  final bool regNotStarted = now.isBefore(hackathon.applicationOpenDate);
  final bool regClosed = now.isAfter(deadlineDateTime); // يستخدم 23:59:59
  final bool isEventEnded = now.isAfter(hackathon.endDate);

  String text = "Registration Open";
  Color color = Colors.green;

  if (isEventEnded) {
    text = "Hackathon Ended";
    color = Colors.blueGrey; // لون هادئ للانتهاء
  } else if (regClosed) {
    text = "Registration Closed";
    color = Colors.red;
  } else if (regNotStarted) {
    text = "Registration Upcoming Soon";
    color = Colors.orange;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color, 
        fontSize: 8, 
        fontWeight: FontWeight.bold
      ),
    ),
  );
}

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _purple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _dateRow(String l1, String d1, String l2, String d2, {bool isDeadline = false}) {
    return Row(
      children: [
        Expanded(child: _dateItem(l1, d1)),
        Container(width: 1, height: 18, color: _purple.withOpacity(0.2)),
        const SizedBox(width: 12),
        Expanded(child: _dateItem(l2, d2, isCritical: isDeadline)),
      ],
    );
  }

  Widget _dateItem(String label, String date, {bool isCritical = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCritical ? Colors.redAccent : Colors.black)),
      ],
    );
  }
}