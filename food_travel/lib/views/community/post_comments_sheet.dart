import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/community/community_comment.dart';
import '../../models/community/community_post.dart';
import '../../services/community/post_comment_service.dart';

// Mo bottom sheet xem + viet binh luan
Future<void> showPostCommentsSheet(
  BuildContext context,
  CommunityPost post,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF0F1115) : Colors.white;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PostCommentsSheet(post: post),
  );
}

class _PostCommentsSheet extends StatefulWidget {
  const _PostCommentsSheet({required this.post});

  final CommunityPost post;

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final _service = PostCommentService();
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Can login de duoc binh luan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long dang nhap de binh luan.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final name = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : (user.email?.trim().isNotEmpty ?? false)
              ? user.email!.trim()
              : 'FoodG User';
      final photo = user.photoURL ?? '';

      await _service.addComment(
        postId: widget.post.id,
        uid: user.uid,
        authorName: name,
        authorPhoto: photo,
        text: text,
      );

      // Xoa text sau khi gui thanh cong
      _input.clear();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    await _service.deleteComment(
      postId: widget.post.id,
      commentId: comment.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : const Color(0xFF64748B);
    final border = isDark ? const Color(0xFF232A33) : const Color(0xFFF1F5F9);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A303A) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Binh luan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Dong', style: TextStyle(color: subText)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            Expanded(
              child: StreamBuilder<List<CommunityComment>>(
                stream: _service.watchComments(widget.post.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data ?? const <CommunityComment>[];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text('Chua co binh luan.', style: TextStyle(color: subText)),
                    );
                  }

                  final currentUid = FirebaseAuth.instance.currentUser?.uid;

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final canDelete = c.authorId == currentUid;
                      return _CommentTile(
                        comment: c,
                        canDelete: canDelete,
                        onDelete: () => _deleteComment(c),
                      );
                    },
                  );
                },
              ),
            ),
            Divider(height: 1, color: border),
            Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 3,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Viet binh luan...',
                        hintStyle: TextStyle(color: subText),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF15181E) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    color: const Color(0xFFF97316),
                  ),
                ],
              ),
            ),
            Container(height: 8, color: bg),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final CommunityComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0),
          backgroundImage: comment.authorPhoto.trim().isNotEmpty
              ? NetworkImage(comment.authorPhoto)
              : null,
          child: comment.authorPhoto.trim().isEmpty
              ? const Icon(Icons.person, size: 14)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.authorName.isNotEmpty
                          ? comment.authorName
                          : 'FoodG User',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (canDelete)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      color: subText,
                    ),
                ],
              ),
              Text(
                comment.text,
                style: TextStyle(color: textColor, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(comment.createdAt),
                style: TextStyle(color: subText, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatTime(Timestamp? ts) {
  if (ts == null) return 'vua xong';
  final now = DateTime.now();
  final dt = ts.toDate();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'vua xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phut truoc';
  if (diff.inHours < 24) return '${diff.inHours} gio truoc';
  if (diff.inDays < 7) return '${diff.inDays} ngay truoc';
  return '${dt.day}/${dt.month}/${dt.year}';
}
