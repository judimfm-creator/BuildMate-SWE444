import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/team_post_model.dart';
import '../../model/hackathon.dart';
import 'my_team_post_view.dart';

class MyTeamsView extends StatelessWidget {
  const MyTeamsView({super.key});

  static const Color _purple = Color(0xFF6D56B3);

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // foregroundColor يغير لون السهم والنص معاً للموف
        foregroundColor: const Color(0xFF6D56B3),
        title: const Text(
          "My Teams",
          style: TextStyle(
            fontSize: 20, // حجم الخط الموحد للعناوين
            fontWeight: FontWeight.bold, // نفس ثقل خط الوورك سبيس
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: currentUid == null
          ? const Center(child: Text("Please login first."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('team_posts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _purple));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // فلترة الفرق الخاصة بالمستخدم
          final myTeams = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final members = List<String>.from(data['members'] ?? []);
            final createdBy = data['createdBy'] ?? '';
            return members.contains(currentUid) || createdBy == currentUid;
          }).toList();

          if (myTeams.isEmpty) return _buildEmptyState();

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(
              myTeams.map((doc) async {
                final data = doc.data() as Map<String, dynamic>;
                final team = TeamPostModel.fromMap(doc.id, data);
                final hackathonDoc = await FirebaseFirestore.instance
                    .collection('hackathons')
                    .doc(team.hackathonId)
                    .get();

                Hackathon? hackathon;
                if (hackathonDoc.exists) {
                  hackathon = Hackathon.fromFirestore(hackathonDoc);
                }
                return {'team': team, 'hackathon': hackathon};
              }),
            ),
            builder: (context, futureSnapshot) {
              if (!futureSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: _purple));
              }

              var list = futureSnapshot.data!
                  .where((item) => item['hackathon'] != null)
                  .toList();

              if (list.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final team = list[index]['team'] as TeamPostModel;
                  final hackathon = list[index]['hackathon'] as Hackathon;
                  return _buildSimplifiedTeamCard(context, team, hackathon, currentUid);
                },
              );
            },
          );
        },
      ),
    );
  }

  // الكارد المبسطة بناءً على طلبك
  Widget _buildSimplifiedTeamCard(
      BuildContext context, TeamPostModel team, Hackathon hackathon, String currentUid) {

    // التحقق من حالة المستخدم
    final bool isLeader = team.createdBy == currentUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // خلفية بيضاء صافية
        borderRadius: BorderRadius.circular(20),
        // 👈 اللمعة الحين صارت "أنحف" وأفتح عشان ما تعطي إحساس بالغمق
        border: Border.all(
          color: _purple.withOpacity(0.25), // 👈 درجة هادئة جداً من الموف
          width: 1.0, // 👈 خط نحيف جداً (يعطي شكل ملمع وراقي)
        ),
        boxShadow: [
          BoxShadow(
            // 👈 الهالة (Glow) اللي تخلي البوكس يبدو مضيء
            color: _purple.withOpacity(0.08),
            blurRadius: 25,
            spreadRadius: 2, // 👈 انتشار خفيف جداً يوزع اللون حول الحواف
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم التيم مع Wrapping
              Expanded(
                child: Text(
                  team.teamName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true, // يضمن نزول النص لسطر جديد إذا كان طويلاً
                ),
              ),
              const SizedBox(width: 12),
              // الـ Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLeader ? Colors.orange.withOpacity(0.1) : _purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLeader ? "Leader" : "Member",
                  style: TextStyle(
                    color: isLeader ? Colors.orange : _purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // الزر يتغير نصه بناءً على الـ Status
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyTeamPostView(
                      teamPostId: team.id ?? "",
                      hackathonId: hackathon.id ?? "",
                      hackathonTeamSize: hackathon.teamSize,
                    ),
                  ),
                );
              },
              child: Text(
                isLeader ? "Manage Team" : "View Details",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, color: Colors.grey.shade400, size: 80),
          const SizedBox(height: 16),
          Text(
            "You haven't joined any team yet.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}