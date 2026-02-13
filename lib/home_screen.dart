import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth/select_role_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D56B3);
    const lightPurple = Color(0xFFB8A8E6);
    const orange = Color(0xFFFF9F2E);

    Future<void> logout() async {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SelectRoleScreen()),
        (route) => false,
      );
    }

    return Scaffold(
      backgroundColor: purple,
      appBar: AppBar(
        backgroundColor: purple,
        elevation: 0,
        title: const Text(
          "BuildMate",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: lightPurple.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome 👋",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("Logout"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
