import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/user_model.dart';
import '../services/chat_service.dart';

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

  UserModel? _currentUser;
  bool _loadingUser = true;

  // ألوان الافتار للأعضاء
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

  Future<void> _loadCurrentUser() async {
    final user = await _chatService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _loadingUser = false;
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
      senderPhoto: _currentUser!.profilePhotoPath,
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

  // لون الافتار بناءً على senderId
  Color _getAvatarBg(String senderId) {
    final index = senderId.hashCode.abs() % _avatarBgColors.length;
    return _avatarBgColors[index];
  }

  Color _getAvatarTextColor(String senderId) {
    final index = senderId.hashCode.abs() % _avatarTextColors.length;
    return _avatarTextColors[index];
  }

  String _getInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return DateFormat('hh:mm a').format(dt);
  }

  // timestamp
  bool _isNewDay(
      QueryDocumentSnapshot<Map<String, dynamic>> current,
      QueryDocumentSnapshot<Map<String, dynamic>>? previous) {
    final currentTs = current.data()['createdAt'] as Timestamp?;
    if (currentTs == null) return false;
    if (previous == null) return true;

    final previousTs = previous.data()['createdAt'] as Timestamp?;
    if (previousTs == null) return true;

    final currentDate = currentTs.toDate();
    final previousDate = previousTs.toDate();

    return currentDate.year != previousDate.year ||
        currentDate.month != previousDate.month ||
        currentDate.day != previousDate.day;
  }

  String _formatDateDivider(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final now = DateTime.now();
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('d MMM yyyy', 'ar').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  // AppBar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _purple,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: const BackButton(color: Colors.white),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EEFF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 16)),
            ),
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
                  color: Colors.white,
                ),
              ),
              const Text(
                'Group Chat',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // video call
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.white),
          tooltip: 'Video Call',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Soon...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  // Messages list
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chatService.getMessagesStream(widget.teamPostId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _purple),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Oops! We couldn’t load your messages. Please try again.'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 48, color: Color(0xFFB4B2A9)),
                const SizedBox(height: 12),
                Text(
                  'No messages yet \n connect with your BuildMates and start building!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());

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
                _buildMessageBubble(data, isMe),
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888780),
              ),
            ),
          ),
          const Expanded(child: Divider(thickness: 0.5)),
        ],
      ),
    );
  }

  // msg bubble
  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final senderId = data['senderId'] as String? ?? '';
    final senderName = data['senderName'] as String? ?? 'مجهول';
    final text = data['text'] as String? ?? '';
    final timestamp = data['createdAt'] as Timestamp?;
    final senderPhoto = data['senderPhoto'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(
              senderId: senderId,
              senderName: senderName,
              photoUrl: senderPhoto,
              size: 28,
            ),
            const SizedBox(width: 6),
          ],

          // msg content
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, right: 2, left: 2),
                  child: Text(
                    senderName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888780),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
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
                    border: isMe
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF888780),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.done_all,
                          size: 13, color: Color(0xFF888780)),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // أفاتار المستخدم الحالي
          if (isMe) ...[
            const SizedBox(width: 6),
            _buildAvatar(
              senderId: senderId,
              senderName: senderName,
              photoUrl: senderPhoto,
              size: 28,
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
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _getAvatarBg(senderId),
      child: Text(
        _getInitial(senderName),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w500,
          color: _getAvatarTextColor(senderId),
        ),
      ),
    );
  }

  // ─── صندوق الإرسال ───────────────────────────────────────────────────
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

          // حقل الكتابة
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: _pageBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                  const BorderSide(color: _purple, width: 1.2),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // زر الإرسال
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: _purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
