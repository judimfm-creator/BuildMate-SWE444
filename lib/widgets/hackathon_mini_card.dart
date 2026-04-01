import 'package:flutter/material.dart';
import '../model/hackathon.dart';
import '../view/hackathon_details_view.dart';
import '../view/create_hackathon_view.dart';

class HackathonMiniCard extends StatelessWidget {
  final Hackathon hackathon;
  final bool isPast;

  const HackathonMiniCard({
    super.key,
    required this.hackathon,
    required this.isPast,
  });

  static const Color _purple = Color(0xFF6D56B3);

  @override
  Widget build(BuildContext context) {
    // ✅ حساب الموعد النهائي بدقة (حتى 11:59 مساءً)
    final endOfDeadline = DateTime(
      hackathon.applicationDeadline.year,
      hackathon.applicationDeadline.month,
      hackathon.applicationDeadline.day,
      23, 59, 59,
    );

    return Container(
      width: 300, 
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // ✅ لضمان محاذاة النص والبادج
              children: [
                Expanded(
                  child: Text(
                    hackathon.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2, // مسافة بين الأسطر
                    ),
                    // ✅ حل مشكلة الـ Wrap:
                    softWrap: true,
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(endOfDeadline), // مررنا الوقت الدقيق هنا
              ],
            ),
            const Divider(height: 20),
            _infoRow(Icons.category_outlined, hackathon.domain),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on_outlined, "${hackathon.city}, ${hackathon.mode}"),
            const SizedBox(height: 8),
            _infoRow(Icons.groups_outlined, hackathon.teamSize > 2 ? "2 - ${hackathon.teamSize} members" : "2 members"),
            const SizedBox(height: 16),
            
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HackathonDetailsView(hackathon: hackathon)));
                },
                child: const Text("View Details", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateHackathonView(hackathonToEdit: hackathon))),
                  child: const Text("Edit", style: TextStyle(color: _purple, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ ميثود البادج المعدلة لحل مشكلة Closed
  Widget _statusBadge(DateTime endOfDeadline) {
    final DateTime now = DateTime.now();
    
    final bool regNotStarted = now.isBefore(hackathon.applicationOpenDate);
    // ✅ نستخدم الموعد النهائي الدقيق بالثواني لضمان بقائه Open
    final bool regClosed = now.isAfter(endOfDeadline); 
    final bool isEventEnded = now.isAfter(hackathon.endDate);

    String text = "Registration Open";
    Color color = Colors.green;

    if (isEventEnded) {
      text = "Hackathon Ended";
      color = Colors.blueGrey;
    } else if (regClosed) {
      text = "Registration Closed";
      color = Colors.red;
    } else if (regNotStarted) {
      text = "Registration Upcoming Soon";
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _purple),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}