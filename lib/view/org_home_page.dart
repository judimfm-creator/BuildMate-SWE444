import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/org_hackathons_view_model.dart';
import '../../model/hackathon.dart';
import '../widgets/hackathon_mini_card.dart';
import 'org_announced_page.dart';
import 'org_past_hackathons_page.dart';

class OrgHomePage extends StatelessWidget {
  const OrgHomePage({super.key});

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _orange = Color(0xFFFFA726);

  @override
  Widget build(BuildContext context) {
    final vm = context.read<OrgHackathonsViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "Hackathons",
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ),
                  const Icon(Icons.search, color: _purple),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ── All Hackathons title ──
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

          // ── Announced Section ──
          _HackathonSection(
            title: "Announced Hackathons ✨",
            stream: vm.ongoingStream,
            onExploreTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrgAnnouncedPage()),
            ),
          ),
          const SizedBox(height: 22),

          // ── Past Section ──
          _HackathonSection(
            title: "Past Hackathons 🏅",
            stream: vm.pastStream,
            onExploreTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrgPastHackathonsPage()),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable section widget
// ─────────────────────────────────────────────
class _HackathonSection extends StatelessWidget {
  final String title;
  final Stream<List<Hackathon>> stream;
  final VoidCallback onExploreTap;

  const _HackathonSection({
    required this.title,
    required this.stream,
    required this.onExploreTap,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _orange = Color(0xFFFFA726);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row + Explore more
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: onExploreTap,
                child: const Row(
                  children: [
                    Text(
                      "Explore more",
                      style: TextStyle(
                        fontSize: 12,
                        color: _orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward, size: 14, color: _orange),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal list
        StreamBuilder<List<Hackathon>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 170,
                child: Center(
                    child: CircularProgressIndicator(
                        color: _purple, strokeWidth: 2)),
              );
            }

            final list = snapshot.data ?? [];

            if (list.isEmpty) {
              return SizedBox(
                height: 110,
                child: Center(
                  child: Text(
                    "No hackathons yet",
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 185,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    HackathonMiniCard(hackathon: list[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}