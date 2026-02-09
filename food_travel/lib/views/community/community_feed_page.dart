import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/community/post_like_controller.dart';
import '../../models/community/community_post.dart';
import '../../models/places_model.dart';
import '../../services/community/community_service.dart';
import 'community_create_post_page.dart';
import 'post_comments_sheet.dart';
import '../favorites/place_detail_page.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  final _service = CommunityService();

  Future<void> _openCreatePost() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CommunityCreatePostPage()),
    );

    if (posted == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: appBarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Cong dong',
          style: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
        ),
        actions: [
          _ActionIcon(icon: Icons.search_rounded, onTap: () {}),
          const SizedBox(width: 6),
          _ActionIcon(icon: Icons.tune_rounded, onTap: () {}),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: _service.watchLatestPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _FeedSkeleton();
          }
          if (snapshot.hasError) {
            return _buildEmpty('Khong the tai bai viet.');
          }

          final posts = snapshot.data ?? const <CommunityPost>[];
          if (posts.isEmpty) {
            return _buildEmpty('Chua co bai viet nao.');
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _PostCard(post: posts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF97316),
        onPressed: _openCreatePost,
        icon: const Icon(Icons.edit_rounded, size: 22),
        label: const Text(
          'Dang bai',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded = false;

  void _openPlaceDetail(CommunityPost post) {
    final place = post.place;
    if (place == null) return;

    // Tao seed place tu snapshot de mo trang chi tiet
    final rawId = (post.placeId ?? '').trim();
    final safeId = rawId.isNotEmpty
        ? rawId
        : '${place.name}_${place.lat}_${place.lng}'.replaceAll(' ', '_');

    final seed = GoongNearbyPlace(
      id: safeId,
      // Chi set serpDataId khi co data_id that (se duoc resolve tu SerpAPI)
      serpDataId: '',
      name: place.name,
      address: place.address,
      lat: place.lat,
      lng: place.lng,
      photoUrl: place.photoUrl,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FavoritePlaceDetailPage(place: seed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final media = post.media;
    final place = post.place;
    final text = post.text.trim();
    final hasText = text.isNotEmpty;
    final canExpand = text.length > 140;
    final likeController = context.watch<PostLikeController>();
    final isLiked = likeController.isLiked(post.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF232A33) : const Color(0xFFF1F5F9);
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.04);
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF475569);
    final timeColor = const Color(0xFF94A3B8);
    final actionColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (media.isNotEmpty)
            _MediaHero(
              media: media,
              place: place,
              onPlaceTap: () => _openPlaceDetail(post),
            ),

          const SizedBox(height: 10),

          // Header: avatar + name + time
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0),
                backgroundImage: post.authorPhoto.trim().isNotEmpty
                    ? NetworkImage(post.authorPhoto)
                    : null,
                child: post.authorPhoto.trim().isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName.isNotEmpty
                          ? post.authorName
                          : 'FoodG User',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: primaryText,
                      ),
                    ),
                    Text(
                      _formatTime(post.createdAt),
                      style: TextStyle(
                        color: timeColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasText) ...[
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                color: secondaryText,
                height: 1.45,
                fontSize: 13,
              ),
            ),
            if (canExpand)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _expanded ? 'Thu gon' : 'Xem them',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],

          if (media.isEmpty && place != null) ...[
            const SizedBox(height: 10),
            _InlinePlace(
              place: place,
              onTap: () => _openPlaceDetail(post),
            ),
          ],

          const SizedBox(height: 6),

          // Footer actions
          Row(
            children: [
              _ActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'Thich',
                count: post.likeCount,
                color: isLiked ? const Color(0xFFEF4444) : actionColor,
                onTap: () {
                  // Bam tim -> toggle like
                  likeController.toggleLike(post.id);
                },
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Binh luan',
                count: post.commentCount,
                color: actionColor,
                onTap: () {
                  // Mo bottom sheet binh luan
                  showPostCommentsSheet(context, post);
                },
              ),
              const Spacer(),
              Icon(Icons.share_outlined, size: 18, color: actionColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaHero extends StatefulWidget {
  const _MediaHero({
    required this.media,
    required this.place,
    this.onPlaceTap,
  });

  final List<PostMedia> media;
  final PlaceSnapshot? place;
  final VoidCallback? onPlaceTap;

  @override
  State<_MediaHero> createState() => _MediaHeroState();
}

class _MediaHeroState extends State<_MediaHero> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final place = widget.place;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: PageView.builder(
              controller: _controller,
              itemCount: media.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return Image.network(
                  media[i].url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: _imageFallbackBg(context),
                      child: const Icon(Icons.image, size: 32),
                    );
                  },
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.25),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          if (media.length > 1)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_index + 1}/${media.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (place != null)
            Positioned(
              left: 10,
              bottom: 10,
              child: _PlaceChip(
                place: place,
                onTap: widget.onPlaceTap,
              ),
            ),
          if (media.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(media.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({required this.place, this.onTap});

  final PlaceSnapshot place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Bam vao chip de mo trang chi tiet quan
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            SizedBox(
              width: 160,
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlinePlace extends StatelessWidget {
  const _InlinePlace({required this.place, this.onTap});

  final PlaceSnapshot place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1F27) : const Color(0xFFF8FAFC);
    final border =
        isDark ? const Color(0xFF2A303A) : const Color(0xFFF1F5F9);
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final subText = isDark ? Colors.white70 : const Color(0xFF64748B);

    return InkWell(
      // Bam vao khung dia diem de mo trang chi tiet
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: bg,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.place, color: subText, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subText, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Cho phep tap de like/comment
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 12, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1F27) : const Color(0xFFF8FAFC);
    final fg = isDark ? Colors.white70 : const Color(0xFF64748B);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final skeleton = isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0);
    final borderColor =
        isDark ? const Color(0xFF232A33) : const Color(0xFFF1F5F9);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: skeleton,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: skeleton,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                          color: skeleton,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 8,
                        width: 80,
                        decoration: BoxDecoration(
                          color: skeleton,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: skeleton,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                width: 180,
                decoration: BoxDecoration(
                  color: skeleton,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
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

Color _imageFallbackBg(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0);
}
