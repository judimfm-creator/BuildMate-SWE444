import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/hackathon.dart';
import '../services/hackathon_deletion_service.dart';
import '../widgets/buildmate_app_bar.dart';
import 'institution_team_post_details_view.dart';

class OrgHackathonDetailsView extends StatefulWidget {
  final Hackathon hackathon;

  const OrgHackathonDetailsView({
    super.key,
    required this.hackathon,
  });

  @override
  State<OrgHackathonDetailsView> createState() =>
      _OrgHackathonDetailsViewState();
}

class _OrgHackathonDetailsViewState extends State<OrgHackathonDetailsView> {
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  bool _isDeleting = false;

  String _formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  Future<void> _deleteHackathon(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Delete Hackathon"),
        content: const Text(
          "Are you sure you want to delete this hackathon?\n\n"
          "This will permanently delete the hackathon and all related team posts, join requests, and registrations.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Yes, Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final deletionService = HackathonDeletionService();

      await deletionService.deleteHackathonCompletely(
        widget.hackathon.id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hackathon deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete hackathon: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hackathon = widget.hackathon;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Hackathon Details",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hackathon.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${_formatDate(hackathon.startDate)} - ${_formatDate(hackathon.endDate)}",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Description",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  hackathon.description,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isDeleting ? null : () => _deleteHackathon(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      _isDeleting ? "Deleting..." : "Delete Hackathon",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Registered Teams",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('team_posts')
                      .where('hackathonId', isEqualTo: hackathon.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final teams = snapshot.data!.docs;

                    if (teams.isEmpty) {
                      return const Text("No teams yet");
                    }

                    return Column(
                      children: teams.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final teamName = data['teamName'] ?? 'Team';
                        final members = (data['members'] as List?)?.length ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _lightPurple,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.group, color: _purple),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "$teamName - $members Members",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          InstitutionTeamPostDetailsView(
                                        teamPostId: doc.id,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("View Team"),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: CircularProgressIndicator(color: _purple),
              ),
            ),
        ],
      ),
    );
  }
}