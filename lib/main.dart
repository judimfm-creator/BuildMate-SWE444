import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'viewmodel/register_view_model.dart';
import 'auth/login_screen.dart';       
import 'auth/select_role_screen.dart'; 
import 'view/register_org_view.dart';  
import 'view/register_user_view.dart'; 
import 'home_screen.dart';   
// إذا كان الملف موجوداً في نفس مجلد main
import 'org_home_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // نبدأ بصفحة اللوجن مباشرة
      initialRoute: '/loginUser', 

      routes: {
  '/loginUser': (context) => const LoginScreen(),
  '/home': (context) => const HomeScreen(),        // شاشة المتسابق
  '/orgHome': (context) => const InstitutionHomeScreen(),   // شاشة المنظمة (الملف الجديد في الصورة)
  '/selectRole': (context) => const SelectRoleScreen(),
},
    );
  }
}