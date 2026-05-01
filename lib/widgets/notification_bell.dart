import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../view/notifications_view.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('receiverId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final int unread = snapshot.data?.docs.length ?? 0;

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.black87),
              if (unread > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6D56B3),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unread > 99 ? '99+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsView()),
          ),
        );
      },
    );
  }
}
