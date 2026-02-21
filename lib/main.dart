import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:buildmate/view/complete_profile_view.dart';
import 'package:buildmate/auth/welcome_screen.dart';

import 'package:buildmate/viewmodel/register_view_model.dart';
import 'package:buildmate/auth/login_screen.dart';
import 'package:buildmate/home_screen.dart';
import 'package:buildmate/org_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
      ],
      child: MaterialApp(
        title: 'BuildMate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
        ),

        // ✅ NEW: خلي البداية من شاشة الترحيب
        initialRoute: '/welcome',

        routes: {
          // ✅ NEW
          '/welcome': (context) => const WelcomeScreen(),
          '/loginUser': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/orgHome': (context) => const InstitutionHomeScreen(),
          '/completeProfile': (context) => const CompleteProfileView(),
        },
      ),
    );
  }
}