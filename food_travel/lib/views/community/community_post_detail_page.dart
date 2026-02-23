import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/community/post_like_controller.dart';
import '../../models/community/community_post.dart';
import '../../models/places_model.dart';
import '../../services/community/community_service.dart';
import '../favorites/place_detail_page.dart';
import 'post_comments_sheet.dart';

class CommunityPostDetailPage extends StatefulWidget {
  const CommunityPostDetailPage({
    super.key,
    required this.postId,
    this.openComments = false,
  });

  final String postId;
  final bool openComments;

  @override
  State<CommunityPostDetailPage> createState() =>
      _CommunityPostDetailPageState();
}

class _CommunityPostDetailPageState extends State<CommunityPostDetailPage> {
  final _service = CommunityService();
  bool _didOpenComments = false;

  void _maybeOpenComments(CommunityPost post) {
    if (!widget.openComments || _didOpenComments) return;
    _didOpenComments = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showPostCommentsSheet(context, post);
    });
  }

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
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          t.postDetailTitle,
          style: TextStyle(fontWeight: FontWeight.w700, color: titleColor),
        ),
      ),
      body: StreamBuilder<CommunityPost?>(
        stream: _service.watchPost(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DetailSkeleton();
          }
          if (snapshot.hasError) {
            return _EmptyState(message: t.postDetailLoadError);
          }

          final post = snapshot.data;
          if (post == null) {
            return _EmptyState(message: t.postDetailNotFound);
          }

          _maybeOpenComments(post);

          final likeController = context.watch<PostLikeController>();
          final isLiked = likeController.isLiked(post.id);
          final actionColor =
              isDark ? Colors.white70 : const Color(0xFF64748B);
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final subText = isDark ? Colors.white70 : const Color(0xFF475569);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? const Color(0xFF1F2630)
                        : const Color(0xFFE2E8F0),
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
                              : t.commonUserFallback,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        Text(
                          _formatTime(post.createdAt, t),
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (post.media.isNotEmpty)
                _MediaHero(
                  media: post.media,
                  place: post.place,
                  onPlaceTap: () => _openPlaceDetail(post),
                ),
              if (post.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  post.text,
                  style: TextStyle(color: subText, height: 1.5, fontSize: 14),
                ),
              ],
              if (post.media.isEmpty && post.place != null) ...[
                const SizedBox(height: 12),
                _InlinePlace(
                  place: post.place!,
                  onTap: () => _openPlaceDetail(post),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: t.actionLike,
                    count: post.likeCount,
                    color:
                        isLiked ? const Color(0xFFEF4444) : actionColor,
                    onTap: () => likeController.toggleLike(post.id),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: t.actionComment,
                    count: post.commentCount,
                    color: actionColor,
                    onTap: () => showPostCommentsSheet(context, post),
                  ),
                ],
              ),
            ],
          );
        },
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
      borderRadius: BorderRadius.circular(16),
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
            child: IgnorePointer(
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
          ),
          if (media.length > 1)
            Positioned(
              right: 10,
              top: 10,
              child: IgnorePointer(
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
              child: IgnorePointer(
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
              width: 180,
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
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

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC);
    final skeleton = isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0);

    return Container(
      color: bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                    width: 140,
                    height: 10,
                    decoration: BoxDecoration(
                      color: skeleton,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 8,
                    decoration: BoxDecoration(
                      color: skeleton,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: skeleton,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: skeleton,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 200,
            decoration: BoxDecoration(
              color: skeleton,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    return Center(
      child: Text(message, style: TextStyle(color: textColor)),
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

Color _imageFallbackBg(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0);
}
