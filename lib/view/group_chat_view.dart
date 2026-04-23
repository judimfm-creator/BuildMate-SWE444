import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/user_model.dart';
import '../services/chat_service.dart';
import 'video_call_view.dart';

class GroupChatView extends StatefulWidget {
  final String teamPostId;
  final String teamName;

  const GroupChatView({
    super.key,
    required this.teamPostId,
    required this.teamName,
  });

  @override
  State<GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  static const Color _purple = Color(0xFF6D56B3);
  static const Color _lightPurple = Color(0xFFF0EEFF);
  static const Color _pageBg = Color(0xFFF8F9FD);

  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final bool _showScrollButton = false;
  final Map<String, String?> _photoCache = {};

  UserModel? _currentUser;
  bool _loadingUser = true;

  final List<Color> _avatarBgColors = const [
    Color(0xFFE1F5EE),
    Color(0xFFE6F1FB),
    Color(0xFFFAECE7),
    Color(0xFFFBEAF0),
    Color(0xFFFAEEDA),
  ];
  final List<Color> _avatarTextColors = const [
    Color(0xFF0F6E56),
    Color(0xFF185FA5),
    Color(0xFF993C1D),
    Color(0xFF993556),
    Color(0xFF854F0B),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (_currentUser == null) return;
    final batch = FirebaseFirestore.instance.batch();
    bool hasUpdates = false;
    for (var doc in docs) {
      final data = doc.data();
      final List readBy = data['readBy'] ?? [];
      if (data['senderId'] != _currentUser!.uid &&
          !readBy.contains(_currentUser!.uid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([_currentUser!.uid])
        });
        hasUpdates = true;
      }
    }
    if (hasUpdates) batch.commit();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _chatService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _loadingUser = false;
        _photoCache.clear();
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_currentUser == null || _messageController.text.trim().isEmpty) return;
    final text = _messageController.text;
    _messageController.clear();
    await _chatService.sendMessage(
      teamPostId: widget.teamPostId,
      text: text,
      senderId: _currentUser!.uid,
      senderName: _currentUser!.fullName,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getAvatarBg(String senderId) {
    final index = senderId.hashCode.abs() % _avatarBgColors.length;
    return _avatarBgColors[index];
  }

  Color _getAvatarTextColor(String senderId) {
    final index = senderId.hashCode.abs() % _avatarTextColors.length;
    return _avatarTextColors[index];
  }

  String _getInitial(String name) =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  bool _isNewDay(QueryDocumentSnapshot<Map<String, dynamic>> current,
      QueryDocumentSnapshot<Map<String, dynamic>>? previous) {
    final currentTs = current.data()['createdAt'] as Timestamp?;
    if (currentTs == null) return false;
    if (previous == null) return true;
    final previousTs = previous.data()['createdAt'] as Timestamp?;
    if (previousTs == null) return true;
    final c = currentTs.toDate();
    final p = previousTs.toDate();
    return c.year != p.year || c.month != p.month || c.day != p.day;
  }

  String _formatDateDivider(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('d MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _purple)),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('team_posts')
          .doc(widget.teamPostId)
          .snapshots(),
      builder: (context, teamSnap) {
        final teamData = teamSnap.data?.data() ?? {};

        // removedMembers = array of UIDs
        final removedList = List<String>.from(teamData['removedMembers'] ?? []);
        final bool isRemoved =
            _currentUser != null && removedList.contains(_currentUser!.uid);

        // removedAt: وقت الطرد أو الانسحاب — نخفي الرسائل بعده عن المطرود
        final removedAtMap =
            Map<String, dynamic>.from(teamData['removedAt'] ?? {});
        final Timestamp? removedAt = (isRemoved &&
                _currentUser != null &&
                removedAtMap.containsKey(_currentUser!.uid))
            ? (removedAtMap[_currentUser!.uid] as Timestamp?)
            : null;

        // memberJoinedAt: للأعضاء الجدد — ما يشوفون رسائل قبل انضمامهم
        final memberJoinedAtMap =
            Map<String, dynamic>.from(teamData['memberJoinedAt'] ?? {});
        final Timestamp? joinedAt = (!isRemoved &&
                _currentUser != null &&
                memberJoinedAtMap.containsKey(_currentUser!.uid))
            ? (memberJoinedAtMap[_currentUser!.uid] as Timestamp?)
            : null;

        return Scaffold(
          backgroundColor: _pageBg,
          appBar: _buildAppBar(isRemoved: isRemoved),
          body: Column(
            children: [
              // الشات يظهر للجميع — المطرود والأعضاء
              Expanded(child: _buildMessagesList(joinedAt: joinedAt, removedAt: removedAt)),
              // المطرود: بانر مقفل — غيره: input عادي
              isRemoved ? _buildRemovedBanner() : _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar({bool isRemoved = false}) {
    return AppBar(
      backgroundColor: _purple,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: const BackButton(color: Colors.white),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _purple,
            child:
                const Icon(Icons.groups_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.teamName,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const Text('Group Chat',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ],
      ),
      actions: [
        if (!isRemoved)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_currentUser == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallView(
                        callID: widget.teamPostId,
                        userID: _currentUser!.uid,
                        userName: _currentUser!.fullName,
                      ),
                    ),
                  );
                },
                child: Container(
                  // التحكم في مساحة الزر الداخلية
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white, // خلفية بيضاء للبتن
                    borderRadius: BorderRadius.circular(20), // زوايا دائرية (شكل كبسولة)
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        color: _purple, // أيقونة الكاميرا باللون الموف
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Video Call',
                        style: TextStyle(
                          color: _purple, // نص الفيديو كول بالموف
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // بانر المطرود في الأسفل بدل input
  Widget _buildRemovedBanner() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You have been removed. You cannot send messages.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList({Timestamp? joinedAt, Timestamp? removedAt}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chatService.getMessagesStream(widget.teamPostId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        if (snapshot.hasError) {
          return const Center(
              child: Text('Could not load messages. Please try again.'));
        }

        var docs = snapshot.data?.docs ?? [];

        // المطرود أو المنسحب: ما يشوف رسائل بعد وقت طرده
        if (removedAt != null) {
          docs = docs.where((doc) {
            final msgTs = doc.data()['createdAt'] as Timestamp?;
            if (msgTs == null) return true;
            return msgTs.compareTo(removedAt) <= 0;
          }).toList();
        }

        // اليوزر الجديد: ما يشوف رسائل قبل تاريخ انضمامه
        if (joinedAt != null) {
          docs = docs.where((doc) {
            final msgTs = doc.data()['createdAt'] as Timestamp?;
            if (msgTs == null) return true;
            return msgTs.compareTo(joinedAt) >= 0;
          }).toList();
        }

        if (docs.isNotEmpty) {
          _markMessagesAsRead(docs);
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 48, color: Color(0xFFB4B2A9)),
                const SizedBox(height: 12),
                Text(
                  'No messages yet. Connect with your BuildMates and start building!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final isMe = data['senderId'] == _currentUser?.uid;
            final previous = index > 0 ? docs[index - 1] : null;
            final showDivider = _isNewDay(doc, previous);
            final timestamp = data['createdAt'] as Timestamp?;

            return Column(
              children: [
                if (showDivider && timestamp != null)
                  _buildDateDivider(_formatDateDivider(timestamp)),
                _buildMessageBubble(data, isMe, doc.id),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
          ),
          const Expanded(child: Divider(thickness: 0.5)),
        ],
      ),
    );
  }

  Future<String?> _getSenderPhoto(String senderId) async {
    if (_photoCache.containsKey(senderId)) return _photoCache[senderId];
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get();
    final photo = doc.data()?['profilePhotoPath'] as String?;
    _photoCache[senderId] = photo;
    return photo;
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> data, bool isMe, String messageId) {
    final senderId = data['senderId'] as String? ?? '';
    final senderName = data['senderName'] as String? ?? 'Unknown';
    final text = data['text'] as String? ?? '';
    final timestamp = data['createdAt'] as Timestamp?;
    final List readBy = data['readBy'] ?? [];
    bool isRead = readBy.any((uid) => uid != senderId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            FutureBuilder<String?>(
              future: _getSenderPhoto(senderId),
              builder: (context, snap) => _buildAvatar(
                  senderId: senderId,
                  senderName: senderName,
                  photoUrl: snap.data,
                  size: 28),
            ),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, right: 2, left: 2),
                  child: Text(senderName,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888780),
                          fontWeight: FontWeight.w500)),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe ? _purple : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: isMe
                          ? const Radius.circular(14)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(14),
                    ),
                    border:
                        isMe ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(text,
                      style: TextStyle(
                          fontSize: 13,
                          color: isMe ? Colors.white : Colors.black87,
                          height: 1.45)),
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatTime(timestamp),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF888780))),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(isRead ? Icons.done_all : Icons.done, size: 13),
                    ],
                    // 🗑️ زر حذف — لكل شخص على رسائله هو فقط
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Message'),
                              content: const Text(
                                  'This will delete the message for everyone. Are you sure?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _chatService.deleteMessage(
                              teamPostId: widget.teamPostId,
                              messageId: messageId,
                            );
                          }
                        },
                        child: Icon(Icons.delete_outline_rounded,
                            size: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            FutureBuilder<String?>(
              future: _getSenderPhoto(senderId),
              builder: (context, snap) => _buildAvatar(
                  senderId: senderId,
                  senderName: senderName,
                  photoUrl: snap.data,
                  size: 28),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required String senderId,
    required String senderName,
    String? photoUrl,
    double size = 36,
  }) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
          radius: size / 2, backgroundImage: NetworkImage(photoUrl));
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _getAvatarBg(senderId),
      child: Text(_getInitial(senderName),
          style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w500,
              color: _getAvatarTextColor(senderId))),
    );
  }

  Widget _buildAvatarCircle(Color bgColor, String label,
      {bool isCount = false}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: _purple, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                fontSize: isCount ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: isCount ? Colors.black54 : _purple)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: _pageBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: _purple, width: 1.2)),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 38,
              height: 38,
              decoration:
                  const BoxDecoration(color: _purple, shape: BoxShape.circle),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
