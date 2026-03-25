import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/community/community_post.dart';
import '../../services/community/community_service.dart';
import '../../widgets/app_notice_dialog.dart';
import 'community_create_post_page.dart';

class CommunityMyPostsPage extends StatefulWidget {
  const CommunityMyPostsPage({super.key});

  @override
  State<CommunityMyPostsPage> createState() => _CommunityMyPostsPageState();
}

class _CommunityMyPostsPageState extends State<CommunityMyPostsPage> {
  final _service = CommunityService();

  Future<void> _openCreatePost() async {
    // Mo trang tao bai viet moi
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CommunityCreatePostPage()),
    );
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    if (result == CommunityCreatePostPage.resultCreated) {
      await showAppNoticeDialog(
        context,
        title: t.noticeSuccessTitle,
        message: t.noticePostCreated,
        confirmText: t.commonConfirm,
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFFFF7A00),
          size: 30,
        ),
        barrierDismissible: false,
      );
    } else if (result == CommunityCreatePostPage.resultUpdated) {
      await showAppNoticeDialog(
        context,
        title: t.noticeSuccessTitle,
        message: t.noticePostUpdated,
        confirmText: t.commonConfirm,
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFFFF7A00),
          size: 30,
        ),
        barrierDismissible: false,
      );
    }
  }

  Future<void> _openEdit(CommunityPost post) async {
    // Mo trang sua bai viet
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CommunityCreatePostPage(post: post)),
    );
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    if (result == CommunityCreatePostPage.resultUpdated) {
      await showAppNoticeDialog(
        context,
        title: t.noticeSuccessTitle,
        message: t.noticePostUpdated,
        confirmText: t.commonConfirm,
        icon: const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFFFF7A00),
          size: 30,
        ),
        barrierDismissible: false,
      );
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showAppNoticeDialog(
      context,
      title: t.communityDeleteTitle,
      message: t.communityDeleteConfirm,
      confirmText: t.commonDelete,
      cancelText: t.commonCancel,
      icon: const Icon(
        Icons.delete_rounded,
        color: Color(0xFFFF7A00),
        size: 30,
      ),
      barrierDismissible: false,
    );
    if (ok == true) {
      // Xoa mem (khong mat du lieu)
      await _service.softDeletePost(post.id);
      if (!mounted) return;
      await showAppNoticeDialog(
        context,
        title: t.noticeSuccessTitle,
        message: t.noticePostDeleted,
        confirmText: t.commonConfirm,
        icon: const Icon(
          Icons.delete_rounded,
          color: Color(0xFFFF7A00),
          size: 30,
        ),
        barrierDismissible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(t.communityMyPostsTitle),
          backgroundColor: bg,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            t.communityMyPostsLoginRequired,
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          t.communityMyPostsTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            // Tao bai viet moi
            onPressed: _openCreatePost,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: _service.watchMyPosts(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                t.communityMyPostsLoadError,
                style: TextStyle(color: textSecondary),
              ),
            );
          }

          final posts = snapshot.data ?? const <CommunityPost>[];
          if (posts.isEmpty) {
            return Center(
              child: Text(
                t.communityMyPostsEmpty,
                style: TextStyle(color: textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _MyPostCard(
                post: post,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onEdit: () => _openEdit(post),
                onDelete: () => _deletePost(post),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyPostCard extends StatelessWidget {
  const _MyPostCard({
    required this.post,
    required this.textPrimary,
    required this.textSecondary,
    required this.onEdit,
    required this.onDelete,
  });

  final CommunityPost post;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final border = isDark ? const Color(0xFF232A33) : const Color(0xFFF1F5F9);
    final media = post.media;
    final place = post.place;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.text.isNotEmpty ? post.text : t.communityPostEmptyContent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                // Menu nhanh sua / xoa
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit_outlined),
                              title: Text(t.commonEdit),
                              onTap: () {
                                Navigator.pop(ctx);
                                onEdit();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: Text(t.commonDelete),
                              onTap: () {
                                Navigator.pop(ctx);
                                onDelete();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icon(Icons.more_vert, color: textSecondary),
              ),
            ],
          ),
          if (media.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  media.first.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0),
                      child: const Icon(Icons.image, size: 32),
                    );
                  },
                ),
              ),
            ),
          ],
          if (place != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Text('${post.likeCount}', style: TextStyle(color: textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.chat_bubble_outline, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Text('${post.commentCount}', style: TextStyle(color: textSecondary, fontSize: 12)),
              const Spacer(),
              Text(
                _formatTime(post.createdAt, t),
                style: TextStyle(color: textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTime(Timestamp? ts, AppLocalizations t) {
  if (ts == null) return t.timeJustNow;
  final now = DateTime.now();
  final dt = ts.toDate();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return t.timeJustNow;
  if (diff.inMinutes < 60) return t.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return t.timeDaysAgo(diff.inDays);
  final dateText = '${dt.day}/${dt.month}/${dt.year}';
  return t.timeOnDate(dateText);
}
