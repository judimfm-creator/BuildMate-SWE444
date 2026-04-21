import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// ViewModels
import 'package:buildmate/viewmodel/register_view_model.dart';
import 'package:buildmate/viewmodel/profile_view_model.dart';
import 'package:buildmate/viewmodel/org_profile_view_model.dart';
import 'package:buildmate/viewmodel/org_hackathons_view_model.dart';

// Screens & Views
import 'package:buildmate/auth/welcome_screen.dart';
import 'package:buildmate/auth/login_screen.dart';
import 'package:buildmate/auth/select_role_screen.dart';
import 'package:buildmate/view/register_org_view.dart';
import 'package:buildmate/view/register_user_view.dart';
import 'package:buildmate/view/complete_profile_view.dart';
import 'package:buildmate/home_screen.dart';
import 'package:buildmate/org_home_screen.dart';

// Notification Service
import 'package:buildmate/services/notification_service.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//video call
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await initializeDateFormatting();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.init();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  /// 🔥 GET TOKEN
  final String? fcmToken = await messaging.getToken();
  debugPrint('FCM Token: $fcmToken');

  /// 🔥 SAVE TOKEN
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && fcmToken != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': fcmToken,
    }, SetOptions(merge: true));
  }

  /// 🔥 UPDATE TOKEN
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint('FCM Token refreshed: $newToken');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': newToken,
      }, SetOptions(merge: true));
    }
  });

  /// OneSignal (نخليه زي ما هو عشان ما نخرب شغلك)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('c398e7ba-119f-4de3-ab62-ff64b114dfce');
  await OneSignal.Notifications.requestPermission(true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => OrgProfileViewModel()),
        ChangeNotifierProvider(create: (_) => OrgHackathonsViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    NotificationService.instance.navigatorKey = _navigatorKey;

    // 👇 1. إعطاء Zego صلاحية التنقل لفتح الشاشة
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(_navigatorKey);

    // 👇 2. تشغيل خدمة الرنين تلقائياً بمجرد دخول المستخدم
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        // نحاول جلب اسم المستخدم من قاعدة البيانات
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userName = doc.data()?['fullName'] ?? 'BuildMate User';

        // استدعاء الدالة لتشغيل الخدمة (هنا كان النقص!)
        onUserLogin(user.uid, userName);
      } else {
        // إغلاق الخدمة عند تسجيل الخروج
        ZegoUIKitPrebuiltCallInvitationService().uninit();
      }
    });

    /// Foreground FCM → show in-app banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationService.instance.showNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked: ${message.messageId}');
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6D56B3);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'BuildMate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/loginUser': (context) => const LoginScreen(),
        '/selectRole': (context) => const SelectRoleScreen(),
        '/registerUser': (context) => const RegisterUserView(),
        '/registerOrg': (context) => const RegisterOrgView(),
        '/home': (context) => const HomeScreen(),
        '/orgHome': (context) => const InstitutionHomeScreen(),
        '/completeProfile': (context) => const CompleteProfileView(),
      },
    );
  }

  void onUserLogin(String userID, String userName) {
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 1561145060,
      appSign: "2d4b9e89e5e3d2dc4625071e52091562ae81fe354f86a6073c9e9c1afcecda3b",
      userID: userID,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
      requireConfig: (ZegoCallInvitationData data) {
        return ZegoUIKitPrebuiltCallConfig.groupVideoCall()
          ..bottomMenuBar.buttons = [
            ZegoCallMenuBarButtonName.toggleCameraButton,
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.switchAudioOutputButton,
            ZegoCallMenuBarButtonName.toggleScreenSharingButton,
            ZegoCallMenuBarButtonName.hangUpButton,
          ];
      },
    );
  }
}