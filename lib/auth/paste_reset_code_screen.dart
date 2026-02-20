import 'package:flutter/material.dart';
import 'set_new_password_screen.dart';

class PasteResetCodeScreen extends StatefulWidget {
  const PasteResetCodeScreen({super.key});

  @override
  State<PasteResetCodeScreen> createState() => _PasteResetCodeScreenState();
}

class _PasteResetCodeScreenState extends State<PasteResetCodeScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _goToSetPassword() {
    final code = _codeController.text.trim();

    if (code.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetNewPasswordScreen(oobCode: code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color purple = const Color(0xFF6D56B3);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: const Text("Enter Reset Code"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Paste the oobCode from the reset link.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Reset Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _goToSetPassword,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}