import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/org_hackathons_view_model.dart';
import '../../model/hackathon.dart';
import '../widgets/hackathon_card.dart';
import '../widgets/buildmate_app_bar.dart';

class OrgPastHackathonsPage extends StatelessWidget {
  const OrgPastHackathonsPage({super.key});
  final bool showBack=false;


  static const Color _purple = Color(0xFF6D56B3);

  @override
  Widget build(BuildContext context) {
    final vm = context.read<OrgHackathonsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Past Hackathons",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: StreamBuilder<List<Hackathon>>(
        stream: vm.pastStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _purple));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Something went wrong",
                  style: TextStyle(color: Colors.grey.shade500)),
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 58, color: Colors.grey.shade300),
                  const SizedBox(height: 14),
                  Text("No past hackathons yet",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final h = list[i];
              return HackathonCard(
                hackathon: h,
                isPast: true,
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, OrgHackathonsViewModel vm, Hackathon h) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Hackathon",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete "${h.name}"?\nThis cannot be undone.',
          style:
          TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: _purple)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (h.id == null) return;
              try {
                await vm.deleteHackathon(h.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Hackathon deleted"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Failed to delete. Try again.")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}