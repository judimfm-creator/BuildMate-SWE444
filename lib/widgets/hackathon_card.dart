import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/hackathon.dart';
import '../services/hackathon_deletion_service.dart';
import '../view/create_hackathon_view.dart';
import '../view/hackathon_details_view.dart';

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

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<void> _deleteHackathon(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Hackathon"),
        content: const Text(
          "Are you sure you want to delete this hackathon?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final deletionService = HackathonDeletionService();
      await deletionService.deleteHackathonCompletely(hackathon.id!);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hackathon deleted successfully"),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting hackathon: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadlineDateTime = DateTime(
      hackathon.applicationDeadline.year,
      hackathon.applicationDeadline.month,
      hackathon.applicationDeadline.day,
      23,
      59,
      59,
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
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hackathon.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(deadlineDateTime),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "${_formatDate(hackathon.startDate)} - ${_formatDate(hackathon.endDate)}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            const Divider(height: 20),

            _buildInfoRow(Icons.category_outlined, hackathon.domain),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on_outlined,
              "${hackathon.city}, ${hackathon.mode}",
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.groups_outlined,
              hackathon.teamSize > 2
                  ? "2 - ${hackathon.teamSize} members"
                  : "2 members",
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HackathonDetailsView(
                        hackathon: hackathon,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "View Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (!isPast) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _purple, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onEdit ??
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateHackathonView(
                                    hackathonToEdit: hackathon,
                                  ),
                                ),
                              );
                            },
                        child: const Text(
                          "Edit",
                          style: TextStyle(
                            color: _purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _deleteHackathon(context),
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DateTime deadlineDateTime) {
    final now = DateTime.now();
    final regClosed = now.isAfter(deadlineDateTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: regClosed
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        regClosed ? "CLOSED" : "OPEN",
        style: TextStyle(
          color: regClosed ? Colors.red : Colors.green,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _purple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}