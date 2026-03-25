import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/org_hackathons_view_model.dart';
import '../../model/hackathon.dart';
import '../widgets/hackathon_mini_card.dart';
import 'org_announced_page.dart';
import 'org_profile_page.dart';

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

          _HackathonSection(
            title: "Announced Hackathons ✨",
            stream: vm.ongoingStream,
            isPastSection: false,
            onExploreTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrgAnnouncedPage(showBack: true),
              ),
            ),
          ),

          const SizedBox(height: 22),

          _HackathonSection(
            title: "Past Hackathons 🏅",
            stream: vm.pastStream,
            isPastSection: true,
            onExploreTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrgProfilePage(showBack: true),
              ),
            ),
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
    final double sectionHeight = isPastSection ? 310 : 370;

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
              InkWell(
                onTap: onExploreTap,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
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

        StreamBuilder<List<Hackathon>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: sectionHeight,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _purple,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: sectionHeight,
                child: Center(
                  child: Text(
                    "Something went wrong",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              );
            }

            final list = snapshot.data ?? [];

            if (list.isEmpty) {
              return SizedBox(
                height: sectionHeight,
                child: Center(
                  child: Text(
                    "No hackathons yet",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 355,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (_, i) => HackathonMiniCard(
                  hackathon: list[i],
                  isPast: isPastSection,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}