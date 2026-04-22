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
  final Map<String, String?> _photoCache = {};

  UserModel? _currentUser;
  bool _loadingUser = true;
  bool _isRemoved = false; // لمعرفة هل المستخدم مطرود

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
    _listenToMemberStatus(); 
  }

  // دالة مراقبة حالة العضو إذا تم حذفه
  void _listenToMemberStatus() {
    FirebaseFirestore.instance
        .collection('team_posts')
        .doc(widget.teamPostId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final List removedIds = doc.data()?['removedMembers'] ?? [];
        setState(() {
          _isRemoved = removedIds.contains(_currentUser?.uid);
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (_currentUser == null) return;

    final batch = FirebaseFirestore.instance.batch();
    bool hasUpdates = false;

    for (var doc in docs) {
      final data = doc.data();
      final List readBy = data['readBy'] ?? [];

      if (data['senderId'] != _currentUser!.uid && !readBy.contains(_currentUser!.uid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([_currentUser!.uid])
        });
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      batch.commit();
    }
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
    if (_isRemoved) return; // منع المطرود من الإرسال
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

  String _getInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return DateFormat('hh:mm a').format(dt);
  }

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
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(dt);
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
          // التبديل بين حقل الإرسال ورسالة الطرد
          _isRemoved ? _buildRemovedNotice() : _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildRemovedNotice() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: MediaQuery.of(context).padding.bottom + 15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: const Text(
          "You can't send messages to this group because you're no longer a participant.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _purple,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: const BackButton(color: Colors.white),
      title: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: _purple,
            child: Icon(Icons.groups_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.teamName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const Text(
                'Group Chat',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (!_isRemoved) // لا تظهر زر الفيديو إذا كان مطروداً
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white, // خلفية الزر بيضاء
                    borderRadius: BorderRadius.circular(12), // حواف دائرية
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_rounded, color: _purple, size: 20), // الأيقونة بالموف
                      SizedBox(width: 6),
                      Text(
                        "Video Call", // يمكنك تغيير الكلمة إلى Call أو حذفها تماماً
                        style: TextStyle(
                          color: _purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
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

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chatService.getMessagesStream(widget.teamPostId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _purple));
        if (snapshot.hasError) return const Center(child: Text('Oops! Failed to load messages.'));

        final docs = snapshot.data?.docs ?? [];
        if (docs.isNotEmpty) _markMessagesAsRead(docs);
        if (docs.isEmpty) return _buildEmptyState();

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
                _buildMessageBubble(data, isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFB4B2A9)),
          const SizedBox(height: 12),
          Text(
            'No messages yet \n connect with your BuildMates and start building!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
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
            child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
          ),
          const Expanded(child: Divider(thickness: 0.5)),
        ],
      ),
    );
  }

  Future<String?> _getSenderPhoto(String senderId) async {
    if (_photoCache.containsKey(senderId)) return _photoCache[senderId];
    final doc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
    final photo = doc.data()?['profilePhotoPath'] as String?;
    _photoCache[senderId] = photo;
    return photo;
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final senderId = data['senderId'] as String? ?? '';
    final senderName = data['senderName'] as String? ?? 'Unknown';
    final text = data['text'] as String? ?? '';
    final timestamp = data['createdAt'] as Timestamp?;
    final List readBy = data['readBy'] ?? [];
    bool isRead = readBy.any((uid) => uid != senderId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            FutureBuilder<String?>(
              future: _getSenderPhoto(senderId),
              builder: (context, snap) => _buildAvatar(
                senderId: senderId,
                senderName: senderName,
                photoUrl: snap.data,
                size: 28,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(senderName, style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe ? _purple : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(14),
                    ),
                    border: isMe ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 13, color: isMe ? Colors.white : Colors.black87, height: 1.45),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatTime(timestamp), style: const TextStyle(fontSize: 10, color: Color(0xFF888780))),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(isRead ? Icons.done_all : Icons.done, size: 13, color: isRead ? Colors.blue : Colors.grey),
                  ],
                ],
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
                size: 28,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required String senderId, required String senderName, String? photoUrl, double size = 36}) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(photoUrl));
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _getAvatarBg(senderId),
      child: Text(_getInitial(senderName), style: TextStyle(fontSize: size * 0.38, color: _getAvatarTextColor(senderId))),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a message...',
                filled: true,
                fillColor: _pageBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: _purple, width: 1.2)),
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
              decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}