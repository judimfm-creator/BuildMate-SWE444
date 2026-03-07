import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../services/user_service.dart';
import '../widgets/buildmate_app_bar.dart';
import 'other_user_profile_page.dart';

class TeamMembersView extends StatelessWidget {
  final List<String> memberIds;

  const TeamMembersView({
    super.key,
    required this.memberIds,
  });

  @override
  Widget build(BuildContext context) {
    const Color purple = Color(0xFF7A62B3);
    final UserService userService = UserService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BuildMateAppBar(
        titleText: "Team Members",
        showBack: true,
        onBack: () => Navigator.pop(context),
      ),
      body: memberIds.isEmpty
          ? const Center(
        child: Text(
          "No members found",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: memberIds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final userId = memberIds[index];

          return StreamBuilder<UserModel?>(
            stream: userService.streamUserById(userId),
            builder: (context, snapshot) {
              final user = snapshot.data;

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7E2F3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),


                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8E0F8),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  title: Text(
                    user?.username?.isNotEmpty == true
                        ? "@${user!.username}"
                        : "Unknown User",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: purple,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtherUserProfilePage(
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}