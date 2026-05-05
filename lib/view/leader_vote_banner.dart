import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';

/// بانر التصويت على القائد الجديد.
/// - بدون عداد ظاهر (timeout خفي فقط كـ safety net)
/// - يتحسم فوراً لما الجميع يصوّت
/// - يقدر العضو يغيّر صوته في أي وقت
class LeaderVoteBanner extends StatefulWidget {
  final String teamPostId;
  final Map<String, dynamic> leaderVoteData;
  final List<String> currentMembers;

  const LeaderVoteBanner({
    super.key,
    required this.teamPostId,
    required this.leaderVoteData,
    required this.currentMembers,
  });

  @override
  State<LeaderVoteBanner> createState() => _LeaderVoteBannerState();
}

class _LeaderVoteBannerState extends State<LeaderVoteBanner> {
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);

  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final ChatService _chatService = ChatService();

  final Map<String, String> _nameCache = {};
  bool _loadingNames = true;

  // background timer — safety net فقط، ما يظهر للمستخدم
  Timer? _expiryTimer;

  bool _voting = false;

  // لما يكون صوّت — نعرضله خيار التغيير
  bool _changingVote = false;

  @override
  void initState() {
    super.initState();
    _loadNames();
    _startExpiryCheck();
  }

  @override
  void didUpdateWidget(LeaderVoteBanner old) {
    super.didUpdateWidget(old);
    _startExpiryCheck();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  // ── Background expiry check (مخفي) ──────────────────────────

  void _startExpiryCheck() {
    _expiryTimer?.cancel();
    final expiresAt =
        (widget.leaderVoteData['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt == null) return;

    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      _tryResolve();
      return;
    }

    // Timer يشتغل لما ينتهي الـ timeout الخفي
    _expiryTimer = Timer(remaining, _tryResolve);
  }

  Future<void> _tryResolve() async {
    try {
      await _chatService.resolveLeaderVote(teamPostId: widget.teamPostId);
    } catch (_) {}
  }

  // ── Load member names ────────────────────────────────────────

  Future<void> _loadNames() async {
    final futures = widget.currentMembers.map((uid) async {
      if (_nameCache.containsKey(uid)) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      _nameCache[uid] = doc.data()?['fullName'] ?? 'Unknown';
    });
    await Future.wait(futures);
    if (mounted) setState(() => _loadingNames = false);
  }

  // ── Cast / Change vote ───────────────────────────────────────

  Future<void> _castVote(String votedForId) async {
    if (_voting) return;
    setState(() => _voting = true);
    try {
      await _chatService.castLeaderVote(
        teamPostId: widget.teamPostId,
        voterId: _currentUserId!,
        votedForId: votedForId,
      );
      if (mounted) setState(() => _changingVote = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final votes =
        Map<String, dynamic>.from(widget.leaderVoteData['votes'] ?? {});
    final eligibleVoters =
        List<String>.from(widget.leaderVoteData['eligibleVoters'] ?? []);

    final String? myVote = votes[_currentUserId] as String?;
    final bool iEligible =
        _currentUserId != null && eligibleVoters.contains(_currentUserId);
    final bool iAlreadyVoted = myVote != null;

    // قائمة التصويت = الأعضاء الحاليين باستثناء نفسك
    final votableMembers = widget.currentMembers
        .where((uid) => uid != _currentUserId)
        .toList();

    // حساب الأصوات للعرض
    final Map<String, int> tally = {};
    for (final v in votes.values) {
      tally[v.toString()] = (tally[v.toString()] ?? 0) + 1;
    }

    // هل يعرض قائمة التغيير؟
    final bool showVoteList =
        iEligible && (!iAlreadyVoted || _changingVote);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple.withOpacity(0.07), _lightPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _purple,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Icon(Icons.how_to_vote_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🗳️Select a new leader',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شريط التقدم
                _buildProgressRow(votes.length, eligibleVoters.length),
                const SizedBox(height: 14),

                if (_loadingNames)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: _purple),
                    ),
                  )
                else if (!iEligible)
                  _buildInfoChip(
                    icon: Icons.info_outline,
                    text: 'You can not vote.',
                    color: Colors.grey,
                  )
                else if (iAlreadyVoted && !_changingVote) ...[
                  // ── صوّت مسبقاً — عرض خياره + زر التغيير ──
                  _buildVotedState(myVote!, tally, votableMembers),
                ] else ...[
                  // ── قائمة التصويت (أول مرة أو تغيير) ────────
                  Text(
                    _changingVote
                        ? 'Choose a member'
                        : 'Choose a member to be the leader.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...votableMembers.map(
                    (uid) => _buildVoteOption(uid, myVote),
                  ),
                  if (_changingVote)
                    TextButton(
                      onPressed: () =>
                          setState(() => _changingVote = false),
                      child: const Text('cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── الحالة: صوّت مسبقاً ─────────────────────────────────────

  Widget _buildVotedState(
    String myVote,
    Map<String, int> tally,
    List<String> votableMembers,
  ) {
    final myVoteName = _nameCache[myVote] ?? myVote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صوتك الحالي
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    children: [
                      const TextSpan(text: 'صوّتك الحالي: '),
                      TextSpan(
                        text: myVoteName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // زر تغيير الصوت
              GestureDetector(
                onTap: () => setState(() => _changingVote = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, color: _purple, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'change',
                        style: TextStyle(
                          color: _purple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // النتائج الحالية
        if (tally.isNotEmpty) _buildTallyList(tally),
      ],
    );
  }

  // ── زر تصويت لعضو ───────────────────────────────────────────

  Widget _buildVoteOption(String uid, String? currentVote) {
    final name = _nameCache[uid] ?? uid;
    final bool isCurrentChoice = uid == currentVote;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _voting ? null : () => _castVote(uid),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrentChoice
                  ? _purple.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentChoice
                    ? _purple.withOpacity(0.4)
                    : Colors.grey.shade200,
                width: isCurrentChoice ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _lightPurple,
                  radius: 18,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_voting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _purple),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _purple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'vote',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────

  Widget _buildProgressRow(int votedCount, int totalEligible) {
    final pct =
        totalEligible == 0 ? 0.0 : votedCount / totalEligible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$votedCount / $totalEligible vote',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                color: _purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: _purple.withOpacity(0.12),
            valueColor:
                const AlwaysStoppedAnimation<Color>(_purple),
          ),
        ),
      ],
    );
  }

  // ── نتائج حالية ──────────────────────────────────────────────

  Widget _buildTallyList(Map<String, int> tally) {
    final sorted = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVotes = sorted.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Results:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...sorted.map((entry) {
          final name = _nameCache[entry.key] ?? entry.key;
          final isLeading = entry.value == maxVotes;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                if (isLeading)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                  )
                else
                  const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isLeading
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color:
                          isLeading ? _purple : Colors.grey.shade800,
                    ),
                  ),
                ),
                Text(
                  '${entry.value} ${entry.value == 1 ? 'vote' : 'voting'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isLeading ? _purple : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Info chip ────────────────────────────────────────────────

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
