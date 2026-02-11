import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/community/community_post.dart';
import '../../services/community/community_service.dart';
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityCreatePostPage()),
    );
  }

  Future<void> _openEdit(CommunityPost post) async {
    // Mo trang sua bai viet
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CommunityCreatePostPage(post: post)),
    );
  }

  Future<void> _deletePost(CommunityPost post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Xoa bai viet'),
          content: const Text('Ban chac chan muon xoa bai viet nay?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xoa'),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      // Xoa mem (khong mat du lieu)
      await _service.softDeletePost(post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Bai viet cua toi'),
          backgroundColor: bg,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Vui long dang nhap de xem bai viet.',
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
        title: const Text(
          'Bai viet cua toi',
          style: TextStyle(fontWeight: FontWeight.w700),
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
              child: Text('Khong the tai bai viet.', style: TextStyle(color: textSecondary)),
            );
          }

          final posts = snapshot.data ?? const <CommunityPost>[];
          if (posts.isEmpty) {
            return Center(
              child: Text('Ban chua co bai viet nao.', style: TextStyle(color: textSecondary)),
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
                  post.text.isNotEmpty ? post.text : 'Bai viet khong co noi dung.',
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
                              title: const Text('Sua bai viet'),
                              onTap: () {
                                Navigator.pop(ctx);
                                onEdit();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: const Text('Xoa bai viet'),
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
              Text(_formatTime(post.createdAt), style: TextStyle(color: textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
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
