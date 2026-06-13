import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/community/community_post.dart';
import '../../services/community/community_service.dart';
import '../../widgets/app_notice_dialog.dart';
import 'community_create_post_page.dart';
import 'community_post_detail_page.dart';

class CommunityMyPostsPage extends StatefulWidget {
  const CommunityMyPostsPage({super.key});

  @override
  State<CommunityMyPostsPage> createState() => _CommunityMyPostsPageState();
}

class _CommunityMyPostsPageState extends State<CommunityMyPostsPage> {
  final _service = CommunityService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _PostFilter _selectedFilter = _PostFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _openDetail(CommunityPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailPage(postId: post.id),
      ),
    );
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
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
          final summary = _PostSummary.fromPosts(posts);
          final filteredPosts = _applyFilters(posts);

          if (posts.isEmpty) {
            return _MyPostsEmptyState(
              isDark: isDark,
              onCreate: _openCreatePost,
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _PostOverviewCard(
                    totalCount: summary.total,
                    publishedCount: summary.published,
                    approvedCount: summary.approved,
                  ),
                  const SizedBox(height: 16),
                  _PostsSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim().toLowerCase());
                    },
                  ),
                  const SizedBox(height: 14),
                  _PostFilterRow(
                    selectedFilter: _selectedFilter,
                    counts: summary,
                    onSelected: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (filteredPosts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'KhÃ´ng cÃ³ bÃ i viáº¿t phÃ¹ há»£p',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    ...filteredPosts.map((post) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _MyPostCard(
                          post: post,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () => _openDetail(post),
                          onEdit: () => _openEdit(post),
                          onDelete: () => _deletePost(post),
                        ),
                      );
                    }),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: _openCreatePost,
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  child: const Icon(Icons.add_rounded, size: 30),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<CommunityPost> _applyFilters(List<CommunityPost> posts) {
    final filtered =
        posts.where((post) {
          if (_searchQuery.isEmpty) return true;
          final haystacks =
              [
                post.text,
                post.place?.name ?? '',
                post.place?.address ?? '',
              ].join(' ').toLowerCase();
          return haystacks.contains(_searchQuery);
        }).toList();

    return filtered.where((post) {
      switch (_selectedFilter) {
        case _PostFilter.all:
          return true;
        case _PostFilter.published:
          return true;
        case _PostFilter.draft:
          return false;
        case _PostFilter.pending:
          return false;
        case _PostFilter.hidden:
          return false;
      }
    }).toList();
  }
}

class _MyPostsEmptyState extends StatelessWidget {
  const _MyPostsEmptyState({required this.isDark, required this.onCreate});

  final bool isDark;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/community/post_manage_1.png',
              width: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text(
              'Bạn chưa có bài viết nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Hãy chia sẻ món ngon đầu tiên\ncủa bạn nhé',
              textAlign: TextAlign.center,
              style: TextStyle(color: subColor, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 170,
              height: 48,
              child: ElevatedButton(
                onPressed: onCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Tạo bài viết ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PostFilter { all, published, draft, pending, hidden }

class _PostSummary {
  const _PostSummary({
    required this.total,
    required this.published,
    required this.approved,
  });

  final int total;
  final int published;
  final int approved;

  factory _PostSummary.fromPosts(List<CommunityPost> posts) {
    final total = posts.length;
    final published = posts.length;
    final approved = posts.where((post) => post.likeCount > 0).length;
    return _PostSummary(total: total, published: published, approved: approved);
  }

  int countFor(_PostFilter filter) {
    switch (filter) {
      case _PostFilter.all:
        return total;
      case _PostFilter.published:
        return published;
      case _PostFilter.draft:
        return 0;
      case _PostFilter.pending:
        return approved;
      case _PostFilter.hidden:
        return 0;
    }
  }
}

class _PostOverviewCard extends StatelessWidget {
  const _PostOverviewCard({
    required this.totalCount,
    required this.publishedCount,
    required this.approvedCount,
  });

  final int totalCount;
  final int publishedCount;
  final int approvedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE7B8), Color(0xFFFFD08C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AFF8A00),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¢ng quan bÃƒÆ’Ã‚Â i viÃƒÂ¡Ã‚ÂºÃ‚Â¿t',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A5300),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _OverviewMetric(
                        icon: Icons.article_outlined,
                        value: '$totalCount',
                        label: 'TÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¢ng bÃƒÆ’Ã‚Â i viÃƒÂ¡Ã‚ÂºÃ‚Â¿t',
                      ),
                    ),
                    Expanded(
                      child: _OverviewMetric(
                        icon: Icons.check_circle_outline_rounded,
                        value: '$publishedCount',
                        label: 'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ Ãƒâ€žÃ¢â‚¬ËœÃƒâ€žÃ†â€™ng',
                      ),
                    ),
                    Expanded(
                      child: _OverviewMetric(
                        icon: Icons.timelapse_rounded,
                        value: '$approvedCount',
                        label: 'ChÃƒÂ¡Ã‚Â»Ã‚Â duyÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡t',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: const DecorationImage(
                image: AssetImage('assets/community/community_post3.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4DE),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Color(0xFFFF7A00)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 27,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _PostsSearchBar extends StatelessWidget {
  const _PostsSearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText:
                  'TÃƒÆ’Ã‚Â¬m bÃƒÆ’Ã‚Â i viÃƒÂ¡Ã‚ÂºÃ‚Â¿t cÃƒÂ¡Ã‚Â»Ã‚Â§a bÃƒÂ¡Ã‚ÂºÃ‚Â¡n...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFF1E7D8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFF1E7D8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFFB766)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1E7D8)),
          ),
          child: const Icon(Icons.tune_rounded, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _PostFilterRow extends StatelessWidget {
  const _PostFilterRow({
    required this.selectedFilter,
    required this.counts,
    required this.onSelected,
  });

  final _PostFilter selectedFilter;
  final _PostSummary counts;
  final ValueChanged<_PostFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_PostFilter.all, 'TÃƒÂ¡Ã‚ÂºÃ‚Â¥t cÃƒÂ¡Ã‚ÂºÃ‚Â£'),
      (_PostFilter.published, 'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ Ãƒâ€žÃ¢â‚¬ËœÃƒâ€žÃ†â€™ng'),
      (_PostFilter.draft, 'NhÃƒÆ’Ã‚Â¡p'),
      (_PostFilter.pending, 'ChÃƒÂ¡Ã‚Â»Ã‚Â duyÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡t'),
      (_PostFilter.hidden, 'BÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¹ ÃƒÂ¡Ã‚ÂºÃ‚Â©n'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          final isSelected = filter == selectedFilter;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF7A00) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFFFF7A00)
                          : const Color(0xFFF1E7D8),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
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
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CommunityPost post;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final border = isDark ? const Color(0xFF232A33) : const Color(0xFFF6E9DA);
    final media = post.media;
    final place = post.place;
    final title =
        post.text.trim().isNotEmpty
            ? post.text.trim()
            : 'BÃƒÆ’Ã‚Â i viÃƒÂ¡Ã‚ÂºÃ‚Â¿t mÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi';
    final subtitle =
        place != null
            ? '${place.name}${place.address.trim().isNotEmpty ? ' Ãƒâ€šÃ‚Â· ${place.address}' : ''}'
            : 'Chia sÃƒÂ¡Ã‚ÂºÃ‚Â» trÃƒÂ¡Ã‚ÂºÃ‚Â£i nghiÃƒÂ¡Ã‚Â»Ã¢â‚¬Â¡m ÃƒÂ¡Ã‚ÂºÃ‚Â©m thÃƒÂ¡Ã‚Â»Ã‚Â±c';
    final statusLabel = 'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ Ãƒâ€žÃ¢â‚¬ËœÃƒâ€žÃ†â€™ng';
    final imageUrl =
        media.isNotEmpty ? media.first.url : (place?.photoUrl ?? '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 86,
                      height: 86,
                      child:
                          imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        _PostThumbFallback(isDark: isDark),
                              )
                              : _PostThumbFallback(isDark: isDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              _formatTime(
                                post.createdAt,
                                AppLocalizations.of(context)!,
                              ),
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF8ED),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ Ãƒâ€žÃ¢â‚¬ËœÃƒâ€žÃ†â€™ng',
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _PostMoreButton(
                    textSecondary: textSecondary,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likeCount}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.remove_red_eye_outlined,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(post.likeCount * 10) + post.commentCount * 3 + 120}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Color(0xFFFF7A00),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _PostThumbFallback extends StatelessWidget {
  const _PostThumbFallback({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1F2630) : const Color(0xFFFFF1DE),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        size: 28,
        color: Color(0xFFFF7A00),
      ),
    );
  }
}

class _PostMoreButton extends StatelessWidget {
  const _PostMoreButton({
    required this.textSecondary,
    required this.onEdit,
    required this.onDelete,
  });

  final Color textSecondary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return IconButton(
      visualDensity: VisualDensity.compact,
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
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
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
      icon: Icon(Icons.more_vert_rounded, color: textSecondary),
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
