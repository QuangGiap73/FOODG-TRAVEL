import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/community/community_post.dart';
import '../../../services/community/community_service.dart';
import '../../community/community_feed_page.dart';
import '../../community/community_post_detail_page.dart';

class HomeCommunityEatingSection extends StatelessWidget {
  const HomeCommunityEatingSection({
    super.key,
    required this.userLat,
    required this.userLng,
  });

  final double? userLat;
  final double? userLng;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<CommunityPost>>(
      stream: CommunityService().watchLatestPosts(limit: 80),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final posts = snapshot.data ?? const <CommunityPost>[];
        final featured = _pickFeaturedPost(posts);
        if (featured == null) return const SizedBox.shrink();

        final imageUrl = featured.media.isNotEmpty
            ? featured.media.first.url
            : (featured.place?.photoUrl ?? '');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: Color(0xFFFF8A00),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cong dong dang an gi?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CommunityFeedPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A1A),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Xem cong dong',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommunityPostDetailPage(postId: featured.id),
                    ),
                  );
                },
                child: Ink(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF171B22) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A303A)
                          : const Color(0xFFF4E5D6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: featured.authorPhoto.trim().isNotEmpty
                                        ? NetworkImage(featured.authorPhoto)
                                        : null,
                                    child: featured.authorPhoto.trim().isEmpty
                                        ? const Icon(Icons.person, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          featured.authorName.isNotEmpty
                                              ? featured.authorName
                                              : 'FoodG User',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          featured.place?.name.isNotEmpty == true
                                              ? featured.place!.name
                                              : 'Food Lover',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF8A6E55),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                featured.text.trim().isNotEmpty
                                    ? featured.text.trim()
                                    : 'Hom nay cong dong dang chia se quan nay.',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (featured.place?.address.isNotEmpty == true)
                                    Expanded(
                                      child: Text(
                                        featured.place!.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 16,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${featured.likeCount}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 15,
                                    color: Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${featured.commentCount}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 118,
                            height: 82,
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _fallbackImage(),
                                  )
                                : _fallbackImage(),
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
      },
    );
  }

  CommunityPost? _pickFeaturedPost(List<CommunityPost> posts) {
    if (posts.isEmpty) return null;

    final now = DateTime.now();
    final todayPosts = posts.where((post) {
      final created = post.createdAt?.toDate();
      if (created == null) return false;
      return created.year == now.year &&
          created.month == now.month &&
          created.day == now.day;
    }).toList();

    final nearbyToday = todayPosts.where((post) {
      final place = post.place;
      if (place == null || userLat == null || userLng == null) return false;
      return _distanceKm(userLat!, userLng!, place.lat, place.lng) <= 12;
    }).toList();

    if (nearbyToday.isNotEmpty) {
      nearbyToday.sort((a, b) {
        final da = _distanceForPost(a);
        final db = _distanceForPost(b);
        return da.compareTo(db);
      });
      return nearbyToday.first;
    }

    if (todayPosts.isNotEmpty) {
      todayPosts.sort(_sortByNewest);
      return todayPosts.first;
    }

    final recent = [...posts]..sort(_sortByNewest);
    return recent.first;
  }

  int _sortByNewest(CommunityPost a, CommunityPost b) {
    final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
    final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
    return tb.compareTo(ta);
  }

  double _distanceForPost(CommunityPost post) {
    final place = post.place;
    if (place == null || userLat == null || userLng == null) {
      return double.infinity;
    }
    return _distanceKm(userLat!, userLng!, place.lat, place.lng);
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFFFF1E4),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: Color(0xFFFF8A00),
        size: 28,
      ),
    );
  }
}
