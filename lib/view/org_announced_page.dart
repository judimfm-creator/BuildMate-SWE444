import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/org_hackathons_view_model.dart';
import '../../model/hackathon.dart';
import '../widgets/hackathon_card.dart';
import '../widgets/buildmate_app_bar.dart';

class OrgAnnouncedPage extends StatelessWidget {
  const OrgAnnouncedPage({super.key});

  static const Color _purple = Color(0xFF6D56B3);

  @override
  Widget build(BuildContext context) {
    final vm = context.read<OrgHackathonsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Announced Hackathons",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: StreamBuilder<List<Hackathon>>(
        stream: vm.ongoingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _purple));
          }
          if (snapshot.hasError) {
            return _errorState();
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return _emptyState(
              Icons.campaign_outlined,
              "No announced hackathons",
              "Tap + to create your first hackathon",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final h = list[i];
              return HackathonCard(
                hackathon: h,
                isPast: false,
                onEdit: () {
                  // TODO: Navigator.push to EditHackathonView(hackathon: h)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Edit "${h.name}" — coming soon'),
                      backgroundColor: _purple,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 58, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      );

  Widget _errorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 50, color: Colors.red.shade300),
        const SizedBox(height: 12),
        Text("Something went wrong",
            style: TextStyle(color: Colors.grey.shade500)),
      ],
    ),
  );
}