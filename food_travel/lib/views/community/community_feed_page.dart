import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controller/community/post_like_controller.dart';
import '../../models/community/community_post.dart';
import '../../models/province_model.dart';
import '../../models/places_model.dart';
import '../../services/community/community_service.dart';
import '../../services/food_service.dart';
import '../../services/location_service.dart';
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
  final _locationService = LocationService();
  final _foodService = FoodService();

  double? _userLat;
  double? _userLng;
  bool _locLoading = false;
  ProvinceModel? _selectedProvince;

  Future<void> _openCreatePost() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CommunityCreatePostPage()),
    );

    if (posted == true) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    if (_locLoading) return;
    setState(() => _locLoading = true);

    // Lay vi tri hien tai (neu co)
    final result = await _locationService.getCurrentLocation(
      useLastKnown: true,
      timeLimit: const Duration(seconds: 8),
    );
    if (!mounted) return;
    final pos = result.position;
    if (result.isSuccess && pos != null) {
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    }
    setState(() => _locLoading = false);
  }

  Future<void> _pickProvince() async {
    // Chon tinh tu danh sach Firebase
    final picked = await showModalBottomSheet<ProvinceModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: StreamBuilder<List<ProvinceModel>>(
            stream: _foodService.watchProvinces(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <ProvinceModel>[];
              if (items.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Text('Khong co danh sach tinh.')),
                );
              }
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = items[index];
                    return ListTile(
                      title: Text(p.name),
                      onTap: () => Navigator.pop(ctx, p),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedProvince = picked);
    }
  }

  // Tinh khoang cach (km) bang Haversine
  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  int _engagementScore(CommunityPost p) {
    // Diem noi bat: uu tien like + comment
    return (p.likeCount * 2) + p.commentCount;
  }

  bool _matchProvince(CommunityPost p, ProvinceModel province) {
    // Tam thoi match theo dia chi text (muon chinh xac can luu provinceId)
    final address = p.place?.address.toLowerCase() ?? '';
    final name = province.name.toLowerCase();
    if (address.contains(name)) return true;
    final slug = province.slug?.toLowerCase();
    if (slug != null && slug.isNotEmpty && address.contains(slug)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF0F1115) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
            _ActionIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
            const SizedBox(width: 10),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                labelColor: isDark ? Colors.white : const Color(0xFF0F172A),
                unselectedLabelColor:
                    isDark ? Colors.white60 : const Color(0xFF94A3B8),
                indicatorColor: const Color(0xFFF97316),
                tabs: const [
                  Tab(text: 'Moi nhat'),
                  Tab(text: 'Noi bat'),
                  Tab(text: 'Gan ban'),
                  Tab(text: 'Theo tinh'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildNewestTab(),
            _buildTrendingTab(),
            _buildNearYouTab(),
            _buildProvinceTab(),
          ],
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
      ),
    );
  }

  Widget _buildNewestTab() {
    return StreamBuilder<List<CommunityPost>>(
      stream: _service.watchLatestPosts(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FeedSkeleton();
        }
        if (snapshot.hasError) {
          return _buildEmpty('Khong the tai bai viet.');
        }
        final posts = snapshot.data ?? const <CommunityPost>[];
        return _buildPostsList(posts, emptyText: 'Chua co bai viet nao.');
      },
    );
  }

  Widget _buildTrendingTab() {
    return StreamBuilder<List<CommunityPost>>(
      stream: _service.watchLatestPosts(limit: 120),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FeedSkeleton();
        }
        if (snapshot.hasError) {
          return _buildEmpty('Khong the tai bai viet.');
        }
        final raw = snapshot.data ?? const <CommunityPost>[];
        final posts = [...raw];
        // Sap xep theo diem noi bat (like + comment)
        posts.sort((a, b) => _engagementScore(b).compareTo(_engagementScore(a)));
        return _buildPostsList(posts, emptyText: 'Chua co bai viet noi bat.');
      },
    );
  }

  Widget _buildNearYouTab() {
    if (_userLat == null || _userLng == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bat GPS de tim bai viet gan ban.'),
            const SizedBox(height: 8),
            OutlinedButton(
              // Thu xin vi tri lai
              onPressed: _locLoading ? null : _resolveLocation,
              child: Text(_locLoading ? 'Dang tai...' : 'Mo GPS'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<CommunityPost>>(
      stream: _service.watchLatestPosts(limit: 120),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FeedSkeleton();
        }
        if (snapshot.hasError) {
          return _buildEmpty('Khong the tai bai viet.');
        }
        final raw = snapshot.data ?? const <CommunityPost>[];
        // Loc bai trong ban kinh 10km
        final posts = raw.where((p) {
          final place = p.place;
          if (place == null) return false;
          final d = _distanceKm(_userLat!, _userLng!, place.lat, place.lng);
          return d <= 10;
        }).toList();
        return _buildPostsList(posts, emptyText: 'Khong co bai viet gan ban.');
      },
    );
  }

  Widget _buildProvinceTab() {
    final selected = _selectedProvince;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected == null ? 'Chon tinh' : selected.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                // Chon tinh
                onPressed: _pickProvince,
                child: const Text('Doi tinh'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: selected == null
              ? _buildEmpty('Chon tinh de xem bai viet.')
              : StreamBuilder<List<CommunityPost>>(
                  stream: _service.watchLatestPosts(limit: 150),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _FeedSkeleton();
                    }
                    if (snapshot.hasError) {
                      return _buildEmpty('Khong the tai bai viet.');
                    }
                    final raw = snapshot.data ?? const <CommunityPost>[];
                    final posts =
                        raw.where((p) => _matchProvince(p, selected)).toList();
                    return _buildPostsList(
                      posts,
                      emptyText: 'Khong co bai viet theo tinh.',
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPostsList(List<CommunityPost> posts,
      {required String emptyText}) {
    if (posts.isEmpty) {
      return _buildEmpty(emptyText);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _PostCard(post: posts[index]);
      },
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
  final _postService = CommunityService();

  Future<void> _openPostMenu(BuildContext context, CommunityPost post) async {
    // Menu 3 cham: sua / xoa
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Sua bai viet'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xoa bai viet'),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'edit') {
      // Mo man sua (dung lai trang tao bai)
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CommunityCreatePostPage(post: post),
        ),
      );
    }

    if (action == 'delete') {
      final ok = await _confirmDelete(context);
      if (ok == true) {
        await _postService.softDeletePost(post.id);
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    // Xac nhan truoc khi xoa mem
    return showDialog<bool>(
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == post.authorId;

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
              if (isOwner)
                IconButton(
                  // Mo menu sua/xoa
                  onPressed: () => _openPostMenu(context, post),
                  icon: Icon(Icons.more_vert, size: 20, color: timeColor),
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
            child: IgnorePointer(
              // Cho phep swipe anh (overlay chi de trang tri)
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
                // Khong chan swipe
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
                // Dots chi la trang tri, khong chan swipe
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


