import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Screens / Views
import 'package:buildmate/auth/welcome_screen.dart';
import 'package:buildmate/auth/login_screen.dart';
import 'package:buildmate/auth/select_role_screen.dart';
import 'package:buildmate/view/register_org_view.dart';
import 'package:buildmate/view/register_user_view.dart';
import 'package:buildmate/view/complete_profile_view.dart';
import 'package:buildmate/home_screen.dart';
import 'package:buildmate/org_home_screen.dart';

// ViewModels
import 'package:buildmate/viewmodel/register_view_model.dart';
import 'package:buildmate/viewmodel/profile_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6D56B3);

    return MaterialApp(
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

      // (ملاحظتي) نخلي البداية Welcome وبعد 3 ثواني تودّي للّوقن تلقائي
      initialRoute: '/welcome',

      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/loginUser': (context) => const LoginScreen(),

        // (ملاحظتي) هذي كانت لاختيار الدور (لو تبون تلغونها بعدين عادي)
        '/selectRole': (context) => const SelectRoleScreen(),

        // (ملاحظتي) صفحات التسجيل الحالية عندكم
        '/registerUser': (context) => const RegisterUserView(),
        '/registerOrg': (context) => const RegisterOrgView(),

        // (ملاحظتي) صفحات الهوم
        '/home': (context) => const HomeScreen(),
        '/orgHome': (context) => const InstitutionHomeScreen(),

        // (ملاحظتي) إكمال البيانات
        '/completeProfile': (context) => const CompleteProfileView(),
      },
    );
  }
}