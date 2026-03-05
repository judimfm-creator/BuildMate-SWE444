import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';


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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // اللون البنفسجي المعتمد في المشروع
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // نقطة البداية المعتمدة هي صفحة الترحيب (Welcome Screen)
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
}