import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_chat_view.dart';
import 'my_team_post_view.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gal/gal.dart';

class TeamWorkspaceView extends StatelessWidget {
  final String teamPostId;
  final String hackathonId;

   TeamWorkspaceView({
    super.key,
    required this.teamPostId,
    required this.hackathonId,
  });

  static const Color _purple = Color(0xFF6D56B3);
  static const Color _pageBg = Colors.white;

  // متغير لمراقبة حالة الرفع
  final ValueNotifier<bool> _isUploading = ValueNotifier(false);

  // دالة اختيار ورفع الملف
  Future<void> _uploadFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      if (!file.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: File not found on device.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      String originalName = result.files.single.name;
      String safeFileName = "${DateTime.now().millisecondsSinceEpoch}_${originalName.replaceAll(RegExp(r'[^a-zA-Z0-9\.]'), '_')}";

      _isUploading.value = true;

      try {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('team_files/$teamPostId/$safeFileName');

        await ref.putFile(file);
        String downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .collection('shared_files')
            .add({
          'fileName': originalName,
          'fileUrl': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully! ✅'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        _isUploading.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          "Team Workspace",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _purple,
        elevation: 0,
      ),
      // 👈 استخدام Snapshots بدلاً من Future ليحس التطبيق فوراً بأي تغيير في الحالة
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .doc(teamPostId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _purple));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Team workspace not found."));
          }

          final data = snapshot.data!.data()!;
          final String teamName = data['teamName'] ?? 'Our Team';
          final String leaderId = data['createdBy'] ?? '';
          final List members = data['members'] ?? [];
          final List<String> removedMembers =
              List<String>.from(data['removedMembers'] ?? []);

          // 🔴 التحقق من حالة المستخدم الحالي
          final bool isLeader = currentUid == leaderId;
          final bool isRemoved = removedMembers.contains(currentUid);


          // فقط لو مو ليدر ومو عضو ومو مطرود = دخل بالخطأ
          if (!isLeader && !members.contains(currentUid) && !isRemoved) {
            return const Center(child: Text("Access Denied."));
          }

          // لو المستخدم أخفى الـ workspace عنده
          final List<String> hiddenFor =
              List<String>.from(data['hiddenFor'] ?? []);
          if (hiddenFor.contains(currentUid)) {
            return const Center(child: Text("Workspace not available."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernHeader(teamName, isRemoved),
                // زر إخفاء الـ workspace (لنفس المستخدم فقط)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Workspace'),
                          content: const Text(
                              'You will be removed from this workspace.'),
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
                        await FirebaseFirestore.instance
                            .collection('team_posts')
                            .doc(teamPostId)
                            .update({
                          'members': FieldValue.arrayRemove([currentUid]),
                          'hiddenFor': FieldValue.arrayUnion([currentUid]),
                        });
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 16),
                    label: const Text('Delete Workspace',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),


                const SizedBox(height: 25),

                // زر تفاصيل الفريق
                _buildActionCard(
                  context,
                  title: "Team Details",
                  subtitle:
                      isRemoved ? "View-only mode" : "View roles and members",
                  icon: Icons.auto_awesome_mosaic_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyTeamPostView(
                          teamPostId: teamPostId,
                          hackathonId: hackathonId,
                          hackathonTeamSize: data['hackathonTeamSize'] ?? 5,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Tasks Section ─────────────────────────────────────────
                if (isLeader)
                  _buildSectionContainer(
                    title: "Tasks",
                    icon: Icons.task_alt_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('team_posts')
                              .doc(teamPostId)
                              .collection('tasks')
                              .orderBy('createdAt', descending: false)
                              .snapshots(),
                          builder: (context, taskSnap) {
                            if (taskSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: _purple, strokeWidth: 2));
                            }
                            final docs = taskSnap.data?.docs ?? [];
                            return Column(
                              children: [
                                ...docs.map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              final deadline = (d['deadline'] as Timestamp?)?.toDate();
                              final label = deadline == null
                                  ? '—'
                                  : '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
                              final List<String> assignedUids =
                              List<String>.from(d['assignedTo'] ?? []);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: FutureBuilder<List<String>>(
                                  future: Future.wait(
                                    assignedUids.map((uid) async {
                                      try {
                                        final userDoc = await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(uid)
                                            .get();
                                        return userDoc.data()?['name'] ??
                                            userDoc.data()?['displayName'] ??
                                            userDoc.data()?['username'] ??
                                            'Member';
                                      } catch (_) {
                                        return 'Member';
                                      }
                                    }),
                                  ),
                                  builder: (context, nameSnap) {
                                    final names = nameSnap.data ?? [];
                                    return _TaskRow(
                                      title: d['title'] ?? '',
                                      deadline: label,
                                      assigneeNames: names,
                                    );
                                  },
                                ),
                              );
                            }),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final List<Map<String, String>> membersList = [];

                                      // أضف الـ Leader نفسه
                                      final leaderDoc = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(leaderId)
                                          .get();
                                      final leaderName = leaderDoc.data()?['name'] ??
                                          leaderDoc.data()?['displayName'] ??
                                          leaderDoc.data()?['username'] ??
                                          'Leader';
                                      membersList.add({'uid': leaderId, 'name': leaderName});

                                      // أضف باقي الأعضاء
                                      for (final uid in members.cast<String>()) {
                                        if (uid == leaderId) continue;
                                        try {
                                          final userDoc = await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(uid)
                                              .get();

                                          // اطبع الداتا عشان تشوف الحقول الموجودة
                                          debugPrint('User data for $uid: ${userDoc.data()}');

                                          final name = userDoc.data()?['name'] ??
                                              userDoc.data()?['displayName'] ??
                                              userDoc.data()?['username'] ??
                                              'Member';
                                          membersList.add({'uid': uid, 'name': name});
                                        } catch (e) {
                                          debugPrint('Error fetching user $uid: $e');
                                          membersList.add({'uid': uid, 'name': 'Member'});
                                        }
                                      }

                                      if (context.mounted) {
                                        await showDialog(
                                          context: context,
                                          builder: (_) => _CreateTaskDialog(
                                            teamPostId: teamPostId,
                                            members: membersList,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add_rounded,
                                        size: 18),
                                    label: const Text('Create Task'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _purple,
                                      side: BorderSide(
                                          color: _purple.withOpacity(0.5)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                if (!isLeader)
                  _buildSectionContainer(
                    title: "Current Tasks",
                    icon: Icons.task_alt_rounded,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('team_posts')
                          .doc(teamPostId)
                          .collection('tasks')
                          .orderBy('createdAt')
                          .snapshots(),
                      builder: (context, taskSnap) {
                        final docs = taskSnap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Text('No tasks yet.',
                              style:
                              TextStyle(color: Colors.grey.shade500));
                        }
                        return Column(
                          children: docs.map((doc) {
                            final d =
                            doc.data() as Map<String, dynamic>;
                            final deadline =
                            (d['deadline'] as Timestamp?)?.toDate();
                            final label = deadline == null
                                ? '—'
                                : '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TaskRow(
                                  title: d['title'] ?? '',
                                  deadline: label),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                // كارد المحادثة
                _buildActionCard(
                  context,
                  title: "Group Chat",
                  subtitle: isRemoved
                      ? "Read-only"
                      : "Discuss ideas with your team",
                  icon: Icons.forum_rounded,
                  isPrimary: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatView(
                          teamPostId: teamPostId,
                          teamName: teamName,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _buildSectionContainer(
                  title: "Team Resources",
                  icon: Icons.folder_copy_rounded,
                  trailing: isRemoved ? null : ValueListenableBuilder<bool>(
                    valueListenable: _isUploading,
                    builder: (context, uploading, child) {
                      return uploading
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _purple))
                          : IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: _purple),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _uploadFile(context),
                      );
                    },
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('team_posts')
                        .doc(teamPostId)
                        .collection('shared_files')
                        .orderBy('uploadedAt', descending: true)
                        .snapshots(),
                    builder: (context, fileSnapshot) {
                      if (!fileSnapshot.hasData || fileSnapshot.data!.docs.isEmpty) {
                        return const Text("No files shared yet.", style: TextStyle(color: Colors.grey, fontSize: 12));
                      }
                      return Column(
                        children: fileSnapshot.data!.docs.map((doc) {
                          final fData = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DocumentRow(
                              fileName: fData['fileName'] ?? '',
                              fileUrl: fData['fileUrl'] ?? '',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(String teamName, bool isRemoved) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isRemoved
            ? Colors.grey.withOpacity(0.05)
            : _purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: isRemoved
                ? Colors.grey.withOpacity(0.1)
                : _purple.withOpacity(0.1),
            width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isRemoved ? Colors.grey : _purple,
            child:
                const Icon(Icons.groups_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: isRemoved ? Colors.grey : Colors.black87),
                ),
                Text(
                  isRemoved ? "Read-only" : "Collaboration Hub",
                  style: TextStyle(
                      color: isRemoved ? Colors.grey : _purple.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(
      {required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purple.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: _purple, size: 20),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _purple)),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
      bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? _purple.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _purple.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: _purple.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: _purple, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _purple.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String deadline;
  final List<String> assigneeNames; // 👈 جديد

  const _TaskRow({
    required this.title,
    required this.deadline,
    this.assigneeNames = const [], // 👈 جديد
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15)),
      child: Column( // 👈 غيرنا Row لـ Column
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radio_button_unchecked,
                  size: 18, color: Color(0xFF6D56B3)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(deadline,
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
              ),
            ],
          ),
          // 👈 أسماء الأعضاء تحت
          if (assigneeNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                assigneeNames.join(' · '),
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

///FILES
class _DocumentRow extends StatelessWidget {
  final String fileName;
  final String fileUrl;

  const _DocumentRow({required this.fileName, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (fileUrl.isEmpty) return;
        final bool isImage = fileName.toLowerCase().endsWith('.png') ||
            fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg');

        showDialog(
          context: context,
          builder: (context) => _SmartFileDialog(
            fileName: fileName,
            fileUrl: fileUrl,
            isImage: isImage,
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                size: 18, color: Color(0xFF6D56B3)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.visibility_rounded, size: 20, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

class ActiveDownloads {
  static final Map<String, ValueNotifier<double>> tasks = {};
}

class _SmartFileDialog extends StatefulWidget {
  final String fileName;
  final String fileUrl;
  final bool isImage;

  const _SmartFileDialog({
    required this.fileName,
    required this.fileUrl,
    required this.isImage,
  });

  @override
  State<_SmartFileDialog> createState() => _SmartFileDialogState();
}

class _SmartFileDialogState extends State<_SmartFileDialog> {
  ValueNotifier<double>? _progressNotifier;
  String _fileSize = "Calculating size...";

  @override
  void initState() {
    super.initState();
    _fetchFileSize();

    if (ActiveDownloads.tasks.containsKey(widget.fileUrl)) {
      _progressNotifier = ActiveDownloads.tasks[widget.fileUrl];
    }
  }

  Future<void> _fetchFileSize() async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.fileUrl);
      final metadata = await ref.getMetadata();
      final sizeInBytes = metadata.size ?? 0;
      final sizeInMb = sizeInBytes / (1024 * 1024);

      if (mounted) {
        setState(() {
          _fileSize = sizeInMb < 1.0
              ? "${(sizeInBytes / 1024).toStringAsFixed(1)} KB"
              : "${sizeInMb.toStringAsFixed(2)} MB";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _fileSize = "Unknown size");
    }
  }

  Future<void> _startDownload() async {
    if (ActiveDownloads.tasks.containsKey(widget.fileUrl)) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final currentDialogContext = context;

    final notifier = ValueNotifier<double>(0.0);
    ActiveDownloads.tasks[widget.fileUrl] = notifier;

    if (mounted) {
      setState(() {
        _progressNotifier = notifier;
      });
    }

    try {
      Directory dir = Directory('/storage/emulated/0/Download');
      String uniqueName = "${DateTime.now().millisecondsSinceEpoch}_${widget.fileName}";
      File file = File('${dir.path}/$uniqueName');

      final ref = FirebaseStorage.instance.refFromURL(widget.fileUrl);
      final DownloadTask task = ref.writeToFile(file);

      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        notifier.value = snapshot.bytesTransferred / snapshot.totalBytes;
      });

      await task;

      if (widget.isImage) {
        try {
          if (!await Gal.hasAccess()) {
            await Gal.requestAccess();
          }
          await Gal.putImage(file.path);
        } catch (galError) {
          debugPrint('Gallery save ignored: $galError');
        }
      }

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(widget.isImage
              ? 'Image saved to Gallery & Downloads! 🖼️✅'
              : 'Saved! Find it in "My Files -> Downloads". Opening... 📁'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));

      ActiveDownloads.tasks.remove(widget.fileUrl);

      if (currentDialogContext.mounted) {
        Navigator.pop(currentDialogContext);
      }

      if (!widget.isImage) {
        await OpenFilex.open(file.path);
      }

    } catch (e) {
      ActiveDownloads.tasks.remove(widget.fileUrl);
      if (mounted) {
        setState(() {
          _progressNotifier = null;
        });
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (widget.isImage)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: Image.network(widget.fileUrl, fit: BoxFit.contain),
            )
          else
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Icon(Icons.picture_as_pdf_rounded, size: 80, color: Color(0xFF6D56B3)),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _fileSize,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildActionArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    if (_progressNotifier != null) {
      return ValueListenableBuilder<double>(
        valueListenable: _progressNotifier!,
        builder: (context, progress, child) {
          if (progress >= 1.0) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Opening...', style: TextStyle(color: Color(0xFF6D56B3), fontWeight: FontWeight.bold)),
            );
          }
          return Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF6D56B3),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text(
                'Downloading... ${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Color(0xFF6D56B3), fontWeight: FontWeight.bold),
              ),
            ],
          );
        },
      );
    }
    return ElevatedButton.icon(
      onPressed: _startDownload,
      icon: const Icon(Icons.download_rounded),
      label: const Text('Download to Device'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6D56B3),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// _CreateTaskDialog
// ─────────────────────────────────────────────────────────────────────────────

class _CreateTaskDialog extends StatefulWidget {
  final String teamPostId;
  final List<Map<String, String>> members;


  const _CreateTaskDialog({
    required this.teamPostId,
    required this.members,
  });

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  static const Color _purple = Color(0xFF6D56B3);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _errorMessage;
  bool _showAssignError = false;
  bool _showDeadlineError = false;

  List<String> _selectedUids = [];
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    setState(() => _errorMessage = null); // 👈 امسح الخطأ القديم

    if (!_formKey.currentState!.validate()) return;

    if (_selectedUids.isEmpty) {
      setState(() => _errorMessage = 'Please assign at least one member.');
      return;
    }

    if (_deadline == null) {
      setState(() => _errorMessage = 'Please select a deadline.');
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('team_posts')
          .doc(widget.teamPostId)
          .collection('tasks')
          .add({
        'title': _titleController.text.trim(),
        'assignedTo': _selectedUids,
        'deadline': Timestamp.fromDate(_deadline!),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final String deadlineLabel =
          '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}';
      final String taskTitle = _titleController.text.trim();
      final notifBatch = FirebaseFirestore.instance.batch();
      for (final uid in _selectedUids) {
        final ref = FirebaseFirestore.instance.collection('notifications').doc();
        notifBatch.set(ref, {
          'receiverId': uid,
          'type': 'task_deadline',
          'title': 'New Task Assigned',
          'message': '$taskTitle — deadline $deadlineLabel',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'teamPostId': widget.teamPostId,
        });
      }
      await notifBatch.commit();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = 'Something went wrong, please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String deadlineLabel = _deadline == null
        ? 'Pick a deadline'
        : '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.task_alt_rounded,
                        color: _purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Task',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _purple),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Task Name
              TextFormField(
                controller: _titleController,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'Max 20 characters',
                  prefixIcon: const Icon(Icons.drive_file_rename_outline,
                      color: _purple),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                    const BorderSide(color: _purple, width: 1.5),
                  ),
                  counterStyle:
                  const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Task name cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Assign Members
              const Text(
                'Assign to',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.members.map((m) {
                  final isSelected = _selectedUids.contains(m['uid']);
                  return FilterChip(
                    label: Text(m['name'] ?? 'Member'),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedUids.add(m['uid']!);
                        } else {
                          _selectedUids.remove(m['uid']);
                        }
                      });
                    },
                    selectedColor: _purple.withOpacity(0.15),
                    checkmarkColor: _purple,
                    labelStyle: TextStyle(
                      color: isSelected ? _purple : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                        color:
                        isSelected ? _purple : Colors.grey.shade300),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Deadline
              const Text(
                'Deadline',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _deadline != null
                            ? _purple
                            : Colors.grey.shade300,
                        width: _deadline != null ? 1.5 : 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: _deadline != null ? _purple : Colors.grey,
                          size: 18),
                      const SizedBox(width: 10),
                      Text(
                        deadlineLabel,
                        style: TextStyle(
                          color: _deadline != null
                              ? Colors.black87
                              : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
// قبل Row الـ buttons
        if (_errorMessage != null) ...[
    Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
    color: Colors.red.withOpacity(0.08),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Row(
    children: [
    const Icon(Icons.error_outline_rounded,
    color: Colors.redAccent, size: 16),
    const SizedBox(width: 8),
    Expanded(
    child: Text(
    _errorMessage!,
    style: const TextStyle(
    color: Colors.redAccent,
    fontSize: 12,
    fontWeight: FontWeight.w500),
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 12),
    ],

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                    _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _saving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Create',
                        style:
                        TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


