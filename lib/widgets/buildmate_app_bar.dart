import 'package:flutter/material.dart';

class BuildMateAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLogout;

  ///  عنوان بدل اللوقو (مثلاً Create Hackathon)
  final String? titleText;

  ///  سهم الرجوع
  final bool showBack;

  /// وش يسوي السهم
  final VoidCallback? onBack;

  const BuildMateAppBar({
    super.key,
    this.onLogout,
    this.titleText,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    const navLight = Colors.white;

    return AppBar(

      backgroundColor: navLight,
      surfaceTintColor: navLight,
      elevation: 0,


      centerTitle: false,

      leading: showBack
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: onBack,
      )
          : null,

      title: titleText != null
          ? Text(
        titleText!,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      )
          : SizedBox(
        height: 90,
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),




      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black87),
          onPressed: onLogout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}