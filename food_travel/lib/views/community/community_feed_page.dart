import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../controller/community/post_like_controller.dart';
import '../../models/community/community_post.dart';
import '../../models/province_model.dart';
import '../../models/places_model.dart';
import '../../services/community/community_service.dart';
import '../../services/food_service.dart';
import '../../services/location_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../router/route_names.dart';
import '../../widgets/app_notice_dialog.dart';
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
      setState(() {});
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
                final t = AppLocalizations.of(context)!;
                return SizedBox(
                  height: 200,
                  child: Center(child: Text(t.communityProvinceListEmpty)),
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
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFFFFBF7);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CommunityHeader(
                title: t.communityTitle,
                subtitle: 'Chia sẻ hành trình ẩm thực của bạn',
                isDark: isDark,
                onSearchTap: () {},
                bellAction: _buildHeaderBellAction(),
                tabs: [
                  Tab(text: t.communityTabNewest),
                  Tab(text: t.communityTabTrending),
                  Tab(text: t.communityTabNear),
                  Tab(text: t.communityTabProvince),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildNewestTab(),
                    _buildTrendingTab(),
                    _buildNearYouTab(),
                    _buildProvinceTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFF97316),
          onPressed: _openCreatePost,
          child: const Icon(Icons.edit_rounded, size: 24),
        ),
      ),
    );
  }

  Widget _buildNewestTab() {
    final t = AppLocalizations.of(context)!;
    return StreamBuilder<List<CommunityPost>>(
      stream: _service.watchLatestPosts(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FeedSkeleton();
        }
        if (snapshot.hasError) {
          return _buildEmpty(t.communityLoadError);
        }
        final posts = snapshot.data ?? const <CommunityPost>[];
        return _buildPostsList(posts, emptyText: t.communityEmptyNewest);
      },
    );
  }

  Widget _buildTrendingTab() {
    final t = AppLocalizations.of(context)!;
    return StreamBuilder<List<CommunityPost>>(
      stream: _service.watchLatestPosts(limit: 120),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FeedSkeleton();
        }
        if (snapshot.hasError) {
          return _buildEmpty(t.communityLoadError);
        }
        final raw = snapshot.data ?? const <CommunityPost>[];
        final posts = [...raw];
        // Sap xep theo diem noi bat (like + comment)
        posts.sort((a, b) => _engagementScore(b).compareTo(_engagementScore(a)));
        return _buildPostsList(posts, emptyText: t.communityEmptyTrending);
      },
    );
  }

  Widget _buildNearYouTab() {
    final t = AppLocalizations.of(context)!;
    if (_userLat == null || _userLng == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.communityEnableGps),
            const SizedBox(height: 8),
            OutlinedButton(
              // Thu xin vi tri lai
              onPressed: _locLoading ? null : _resolveLocation,
              child: Text(
                _locLoading
                    ? t.communityGpsLoading
                    : t.communityEnableGpsButton,
              ),
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
          return _buildEmpty(t.communityLoadError);
        }
        final raw = snapshot.data ?? const <CommunityPost>[];
        // Loc bai trong ban kinh 10km
        final posts = raw.where((p) {
          final place = p.place;
          if (place == null) return false;
          final d = _distanceKm(_userLat!, _userLng!, place.lat, place.lng);
          return d <= 10;
        }).toList();
        return _buildPostsList(posts, emptyText: t.communityEmptyNear);
      },
    );
  }

  Widget _buildProvinceTab() {
    final t = AppLocalizations.of(context)!;
    final selected = _selectedProvince;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected == null ? t.communitySelectProvince : selected.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                // Chon tinh
                onPressed: _pickProvince,
                child: Text(t.communityChangeProvince),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: selected == null
              ? _buildEmpty(t.communitySelectProvinceHint)
              : StreamBuilder<List<CommunityPost>>(
                  stream: _service.watchLatestPosts(limit: 150),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _FeedSkeleton();
                    }
                    if (snapshot.hasError) {
                      return _buildEmpty(t.communityLoadError);
                    }
                    final raw = snapshot.data ?? const <CommunityPost>[];
                    final posts =
                        raw.where((p) => _matchProvince(p, selected)).toList();
                    return _buildPostsList(
                      posts,
                      emptyText: t.communityEmptyProvince,
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

  Widget _buildHeaderBellAction() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _HeaderActionIcon(
        icon: Icons.notifications_none_rounded,
        hasDot: false,
        onTap: () {
          Navigator.pushNamed(context, RouteNames.notifications);
        },
      );
    }

    return StreamBuilder<int>(
      stream: NotificationService().watchUnreadCount(uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _HeaderActionIcon(
              icon: Icons.notifications_none_rounded,
              hasDot: count > 0,
              onTap: () {
                Navigator.pushNamed(context, RouteNames.notifications);
              },
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBellAction() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _ActionIcon(
        icon: Icons.notifications_none_rounded,
        onTap: () {
          // Chua dang nhap thi van mo man thong bao
          Navigator.pushNamed(context, RouteNames.notifications);
        },
      );
    }

    return StreamBuilder<int>(
      stream: NotificationService().watchUnreadCount(uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _ActionIcon(
              icon: Icons.notifications_none_rounded,
              onTap: () {
                Navigator.pushNamed(context, RouteNames.notifications);
              },
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}


class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onSearchTap,
    required this.bellAction,
    required this.tabs,
  });

  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onSearchTap;
  final Widget bellAction;
  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

    return Container(
      color: isDark ? const Color(0xFF0F1115) : const Color(0xFFFFFBF7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 138,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    color: isDark ? const Color(0xFF1A1F27) : const Color(0xFFFFF1E2),
                    child: Image.asset(
                      'assets/community/community_banner_bg.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                      errorBuilder: (context, error, stackTrace) {
                        return const _CommunityHeaderFallbackBg();
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? Colors.black : Colors.white)
                              .withOpacity(isDark ? 0.18 : 0.02),
                          Colors.transparent,
                          (isDark ? Colors.black : Colors.white)
                              .withOpacity(isDark ? 0.06 : 0.10),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 36,
                  right: 126,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontSize: 30,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                  letterSpacing: -0.8,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: subtitleColor,
                            ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 52,
                  child: bellAction,
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: _HeaderActionIcon(
                    icon: Icons.search_rounded,
                    onTap: onSearchTap,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1115) : const Color(0xFFFFFBF7),
              border: Border(
                bottom: BorderSide(
                  color:
                      isDark ? const Color(0xFF232A33) : const Color(0xFFFFE6D0),
                  width: 1,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelColor: isDark ? Colors.white : const Color(0xFF0F172A),
                unselectedLabelColor:
                    isDark ? Colors.white60 : const Color(0xFF94A3B8),
                indicatorColor: const Color(0xFFF97316),
                indicatorWeight: 3,
                tabs: tabs,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityHeaderFallbackBg extends StatelessWidget {
  const _CommunityHeaderFallbackBg();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CommunityHeaderFallbackPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CommunityHeaderFallbackPainter extends CustomPainter {
  const _CommunityHeaderFallbackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFD8AD),
          Color(0xFFFFEAD2),
          Color(0xFFFFFBF7),
        ],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bgRect);

    canvas.drawRect(bgRect, bgPaint);

    final wavePaint = Paint()
      ..color = const Color(0xFFFFB15C).withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final wave = Path()
      ..moveTo(0, size.height * 0.70)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.58,
        size.width * 0.42,
        size.height * 0.84,
        size.width * 0.66,
        size.height * 0.66,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.55,
        size.width * 0.94,
        size.height * 0.66,
        size.width,
        size.height * 0.60,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(wave, wavePaint);

    final frontWavePaint = Paint()
      ..color = const Color(0xFFFFD9AE).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final frontWave = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.72,
        size.width * 0.45,
        size.height * 0.90,
        size.width * 0.70,
        size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.68,
        size.width * 0.94,
        size.height * 0.76,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(frontWave, frontWavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({
    required this.icon,
    required this.onTap,
    this.hasDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 29,
                color: const Color(0xFF0F172A),
              ),
              if (hasDot)
                Positioned(
                  top: 5,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B00),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
    final t = AppLocalizations.of(context)!;
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
                title: Text(t.commonEdit),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(t.commonDelete),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'edit') {
      // Mo man sua (dung lai trang tao bai)
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => CommunityCreatePostPage(post: post),
        ),
      );
      if (!mounted) return;
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

    if (action == 'delete') {
      final ok = await _confirmDelete(context);
      if (ok == true) {
        await _postService.softDeletePost(post.id);
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
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // Xac nhan truoc khi xoa mem
    return showAppNoticeDialog(
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
    final t = AppLocalizations.of(context)!;
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
                          : t.commonUserFallback,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: primaryText,
                      ),
                    ),
                    Text(
                      _formatTime(post.createdAt, t),
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
                  _expanded ? t.commonCollapse : t.commonSeeMore,
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
                label: t.actionLike,
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
                label: t.actionComment,
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
