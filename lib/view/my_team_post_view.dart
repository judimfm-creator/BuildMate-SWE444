import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'leader_join_requests_view.dart';
import 'team_registration_form_view.dart';

class MyTeamPostView extends StatelessWidget {
  final String teamPostId;
  final String hackathonId;
  final int hackathonTeamSize;

  const MyTeamPostView({
    super.key,
    required this.teamPostId,
    required this.hackathonId,
    required this.hackathonTeamSize,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user is currently signed in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team Post'),
        centerTitle: true,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong while loading your team post.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Team post not found.'),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final String teamName =
              (data['teamName'] ?? 'Unnamed Team').toString();
          final String genderPreference =
              (data['genderPreference'] ?? 'Not specified').toString();
          final String myRole = (data['myRole'] ?? '').toString();
          final String description =
              (data['description'] ?? 'No description added.').toString();
          final String leaderName =
              (data['leaderName'] ?? 'Unknown Leader').toString();
          final String leaderId = (data['leaderId'] ?? '').toString();
          final String status = (data['status'] ?? 'open').toString();

          final List<String> members = _parseStringList(data['members']);
          final List<String> neededRoles = _parseStringList(data['neededRoles']);

          final int currentMembers = _parseInt(data['currentMembers']);
          final int storedMaxMembers = _parseInt(data['maxMembers']);
          final int maxMembers =
              storedMaxMembers > 0 ? storedMaxMembers : hackathonTeamSize;

          final bool isLeader = currentUserId == leaderId;
          final bool isComplete = currentMembers >= maxMembers;
          final bool submittedToInstitution =
              data['submittedToInstitution'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  'Team Information',
                  'This is your current team for this hackathon.',
                ),
                const SizedBox(height: 10),
                _infoCard([
                  _row('Team Name', teamName),
                  _row('Leader', leaderName),
                  _row(
                    'My Role',
                    myRole.isEmpty ? 'Not specified' : myRole,
                  ),
                  _row('Gender Preference', genderPreference),
                  _row('Members', '$currentMembers / $maxMembers'),
                  _row('Status', status),
                ]),
                const SizedBox(height: 20),
                _sectionTitle(
                  'Team Description',
                  'This text is visible to users who want to join your team.',
                ),
                const SizedBox(height: 10),
                _textCard(description),
                const SizedBox(height: 20),
                _sectionTitle(
                  'Needed Roles',
                  'These are the roles your team is currently looking for.',
                ),
                const SizedBox(height: 10),
                _rolesCard(neededRoles),
                const SizedBox(height: 20),
                _sectionTitle(
                  'Team Progress',
                  'Your team is complete only when it reaches the required hackathon team size.',
                ),
                const SizedBox(height: 10),
                _infoCard([
                  _row('Current Members', currentMembers.toString()),
                  _row('Required Team Size', maxMembers.toString()),
                  _row('Is Team Complete', isComplete ? 'Yes' : 'No'),
                  _row(
                    'Submitted to Institution',
                    submittedToInstitution ? 'Yes' : 'No',
                  ),
                ]),
                const SizedBox(height: 24),

                if (isLeader) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            submittedToInstitution ? Colors.grey : _purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: submittedToInstitution
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LeaderJoinRequestsView(
                                    teamPostId: teamPostId,
                                    hackathonTeamSize: maxMembers,
                                  ),
                                ),
                              );
                            },
                      child: Text(
                        submittedToInstitution
                            ? 'Join Requests Closed'
                            : 'View Join Requests',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: submittedToInstitution
                            ? Colors.black54
                            : isComplete
                                ? Colors.green
                                : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (!submittedToInstitution && isComplete)
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamRegistrationFormView(
                                    hackathonId: hackathonId,
                                    teamPostId: teamPostId,
                                    teamName: teamName,
                                    members: members,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        submittedToInstitution
                            ? 'Already Registered for Hackathon'
                            : 'Register Team for Hackathon',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isComplete && !submittedToInstitution)
                    Text(
                      'The team leader can register the team only after the team becomes complete.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'You are a team member. Only the team leader can manage requests and register the team.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _sectionTitle(
                  'Current Members',
                  'These are the members currently in your team.',
                ),
                const SizedBox(height: 10),
                _membersCard(members),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(List<Widget> rows) {
    final children = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(
          Divider(
            color: _purple.withValues(alpha: 0.1),
            height: 16,
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _textCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _rolesCard(List<String> roles) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: roles.isEmpty
          ? Text(
              'No specific roles listed.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles.map((role) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _purple.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _membersCard(List<String> members) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: members.isEmpty
          ? Text(
              'No members yet.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            )
          : Column(
              children: members.map((memberId) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline, color: _purple),
                  title: Text(memberId),
                );
              }).toList(),
            ),
    );
  }
}