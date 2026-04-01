import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/org_hackathons_view_model.dart';
import '../../model/hackathon.dart';
import '../widgets/hackathon_mini_card.dart';
import 'org_announced_page.dart';
import 'org_profile_page.dart';
import '../org_home_screen.dart';

class OrgHomePage extends StatelessWidget {
  const OrgHomePage({super.key});

  static const Color _purple = Color(0xFF6D56B3);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrgHackathonsViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "All Hackathons",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _purple,
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          // ✅ قسم الهاكاثونات المعلنة - يعرض كل ما ينتهي اليوم أو غداً
          _HackathonSection(
            title: "Announced Hackathons ✨",
            stream: vm.ongoingStream,
            isPastSection: false,
            onExploreTap: () => institutionHomeState?.changeTab(1)
          ),
          
          const SizedBox(height: 22),
          
          // قسم الهاكاثونات السابقة
          _HackathonSection(
            title: "Past Hackathons 🏅",
            stream: vm.pastStream,
            isPastSection: true,
            onExploreTap: () => institutionHomeState?.changeTab(4)
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _HackathonSection extends StatelessWidget {
  final String title;
  final Stream<List<Hackathon>> stream;
  final VoidCallback onExploreTap;
  final bool isPastSection;

  const _HackathonSection({
    required this.title,
    required this.stream,
    required this.onExploreTap,
    required this.isPastSection,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _orange = Color(0xFFFFA726);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onExploreTap,
                child: const Text(
                  "Explore more",
                  style: TextStyle(fontSize: 12, color: _orange, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        
        StreamBuilder<List<Hackathon>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: _purple, strokeWidth: 2)));
            }

            final list = snapshot.data ?? [];
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = DateTime(now.year, now.month, now.day + 1);

            // 1. فلترة الهاكاثونات التي تنتهي اليوم أو غداً (حتى 11:59 مساءً)
            final hotList = list.where((h) {
              final deadline = h.applicationDeadline;
              final deadlineDateOnly = DateTime(deadline.year, deadline.month, deadline.day);
              final actualExpiry = DateTime(deadline.year, deadline.month, deadline.day, 23, 59, 59);
              
              bool isTargetDay = deadlineDateOnly.isAtSameMomentAs(today) || deadlineDateOnly.isAtSameMomentAs(tomorrow);
              bool isStillOpen = now.isBefore(actualExpiry);
              
              return isTargetDay && isStillOpen;
            }).toList();

            // ✅ تحديد القائمة التي ستعرض (إذا كان فيه Hot نعرضهم كلهم، وإلا نعرض القائمة الأصلية)
            bool isHotMode = hotList.isNotEmpty && !isPastSection;
            final displayList = isHotMode ? hotList : list;

            // ✅ إذا كان المود "Hot" والقائمة فارغة (يعني مافي شي يقفل بكرة أو اليوم)
            if (!isPastSection && list.isNotEmpty && hotList.isEmpty) {
              return _buildEmptyState("No registration finish upcoming 2 days.");
            }

            if (displayList.isEmpty) {
              return _buildEmptyState("No hackathons yet");
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHotMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.red),
                          SizedBox(width: 4),
                          Text("LAST CALL: CLOSING SOON", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // ✅ تم حذف .take(3) ليعرض كل الهاكاثونات اللي تنطبق عليها الشروط
                      children: displayList
                          .map((h) => HackathonMiniCard(hackathon: h, isPast: isPastSection))
                          .toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      height: 100,
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text(msg, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}