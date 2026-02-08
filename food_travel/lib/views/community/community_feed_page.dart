import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/community/community_post.dart';
import '../../services/community/community_service.dart';
import 'community_create_post_page.dart';

// Trang feed cong dong
class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  final _service = CommunityService();

  Future<void> _openCreatePost() async {
    // Mo trang tao bai viet
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CommunityCreatePostPage()),
    );

    // Neu vua dang bai thanh cong thi rebuild UI
    if (posted == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // StreamBuilder lay feed tu Firestore
        StreamBuilder<List<CommunityPost>>(
          stream: _service.watchLatestPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildEmpty('Khong the tai bai viet.');
            }

            final posts = snapshot.data ?? const <CommunityPost>[];
            if (posts.isEmpty) {
              return _buildEmpty('Chua co bai viet nao.');
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _PostCard(post: posts[index]);
              },
            );
          },
        ),

        // Nut tao bai viet (floating)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _openCreatePost,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}

// ---------- Post card ----------
class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final media = post.media;
    final place = post.place;
    final hasText = post.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + time
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: post.authorPhoto.trim().isNotEmpty
                    ? NetworkImage(post.authorPhoto)
                    : null,
                child: post.authorPhoto.trim().isEmpty
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.authorName.isNotEmpty ? post.authorName : 'FoodG User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatTime(post.createdAt),
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (hasText) ...[
            const SizedBox(height: 10),
            Text(
              post.text,
              style: const TextStyle(height: 1.4),
            ),
          ],

          // Media preview (hien 1 anh dai dien)
          if (media.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      media.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Icon(Icons.image, size: 32),
                        );
                      },
                    ),
                  ),
                  if (media.length > 1)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '1/${media.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Place card
          if (place != null) ...[
            const SizedBox(height: 10),
            _PlaceCard(place: place),
          ],

          const SizedBox(height: 8),

          // Footer: like / comment count (UI only)
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 18),
              const SizedBox(width: 6),
              Text(post.likeCount.toString()),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 18),
              const SizedBox(width: 6),
              Text(post.commentCount.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Place card ----------
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final PlaceSnapshot place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: Color(0xFFFF6A00)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  place.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Helper time ----------
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
