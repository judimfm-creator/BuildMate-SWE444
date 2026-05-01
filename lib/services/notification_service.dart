import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _joinRequestsSub;
  final Set<String> _shownNotificationIds = {};

  GlobalKey<NavigatorState>? navigatorKey;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _saveTokenToFirestore();
    _listenToTokenRefresh();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  Future<void> _saveTokenToFirestore() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final String? token = await _messaging.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'lastTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenToTokenRefresh() {
    _messaging.onTokenRefresh.listen((String newToken) async {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': newToken,
        'lastTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  // Called from main.dart foreground FCM listener
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    showInAppBanner(title: title, body: body);
  }

  // Snapchat/Instagram-style in-app banner overlay
  void showInAppBanner({required String title, required String body}) {
    final overlay = navigatorKey?.currentState?.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _InAppBannerWidget(
        title: title,
        body: body,
        onDismiss: () {
          try {
            entry.remove();
          } catch (_) {}
        },
      ),
    );

    overlay.insert(entry);
  }

  bool _initialLoadDone = false;

  // Listens to the notifications collection for real-time in-app banners.
  // First snapshot silently seeds seen IDs — only additions AFTER login show a banner.
  void startJoinRequestListener() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _joinRequestsSub?.cancel();
    _initialLoadDone = false;
    _shownNotificationIds.clear();

    _joinRequestsSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (!_initialLoadDone) {
        // Seed all existing IDs silently — these are old, don't banner them
        for (final doc in snapshot.docs) {
          _shownNotificationIds.add(doc.id);
        }
        _initialLoadDone = true;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final doc = change.doc;
        final data = doc.data();
        if (data == null) continue;

        if (_shownNotificationIds.contains(doc.id)) continue;
        _shownNotificationIds.add(doc.id);

        final String title = (data['title'] ?? 'New Notification').toString();
        final String body = (data['message'] ?? '').toString();

        showInAppBanner(title: title, body: body);
      }
    });
  }

  Future<void> stopJoinRequestListener() async {
    await _joinRequestsSub?.cancel();
    _joinRequestsSub = null;
  }
}

// ─── In-App Banner Widget ────────────────────────────────────────────────────

class _InAppBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const _InAppBannerWidget({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  @override
  State<_InAppBannerWidget> createState() => _InAppBannerWidgetState();
}

class _InAppBannerWidgetState extends State<_InAppBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    Future.delayed(const Duration(seconds: 15), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SlideTransition(
            position: _slideAnim,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null &&
                    details.primaryDelta! < -5) {
                  _dismiss();
                }
              },
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF1C1B1F),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6D56B3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group_add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.body,
                              style: const TextStyle(
                                color: Color(0xFFB0AEC8),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
