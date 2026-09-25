import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/system_post.dart';
import '../../../services/system_posts/system_post_service.dart';
import '../system_post_detail_page.dart';

class HomeSystemPostsSection extends StatefulWidget {
  const HomeSystemPostsSection({super.key});

  @override
  State<HomeSystemPostsSection> createState() => _HomeSystemPostsSectionState();
}

class _HomeSystemPostsSectionState extends State<HomeSystemPostsSection> {
  late final Stream<List<SystemPost>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = SystemPostService().watchPublishedPosts(limit: 6);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final language = Localizations.localeOf(context).languageCode;

    return StreamBuilder<List<SystemPost>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final posts = snapshot.data ?? const <SystemPost>[];
        if (posts.isEmpty) return const SizedBox.shrink();

        final post = posts.first;
        final title = post.title(language);
        final summary = post.summary(language);
        final category = post.category(language);
        final location = post.provinceName34 ??
            post.regionCode ??
            (language == 'vi' ? 'Toàn quốc' : 'Nationwide');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A2518)
                        : const Color(0xFFFFE9D2),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.celebration_rounded,
                      size: 19, color: Color(0xFFF97316)),
                ),
                const SizedBox(width: 10),
                Text(t.systemGuideTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SystemPostDetailPage(postId: post.id),
              )),
              child: Ink(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A1C14)
                      : const Color(0xFFFFF1E4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2B303A)
                        : const Color(0xFFFFD9B8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.24 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 130,
                        child: Stack(fit: StackFit.expand, children: [
                          post.coverImage.trim().isNotEmpty
                              ? Image.network(post.coverImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _fallbackImage(isDark))
                              : _fallbackImage(isDark),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x24000000),
                                  Color(0x05000000),
                                  Color(0x90000000)
                                ],
                              ),
                            ),
                          ),
                          if (category.trim().isNotEmpty)
                            Positioned(
                              left: 11,
                              top: 10,
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 190),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Color(0xFFF97316),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          Positioned(
                            left: 11,
                            bottom: 9,
                            child: Row(children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 13, color: Color(0xFFFFB45C)),
                              const SizedBox(width: 5),
                              Text(
                                language == 'vi'
                                    ? 'Nổi bật hôm nay'
                                    : 'Featured today',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(13, 11, 10, 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isNotEmpty
                                  ? title
                                  : (language == 'vi'
                                      ? 'Bài viết nổi bật'
                                      : 'Featured story'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.28,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF172033),
                              ),
                            ),
                            if (summary.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(summary,
                                maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isDark
                                        ? const Color(0xFFB8C0CC)
                                        : const Color(0xFF667085),
                                  )),
                            ],
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: Color(0xFFF97316)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF9DA7B5)
                                          : const Color(0xFF7A8494),
                                    )),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: Colors.white),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fallbackImage(bool isDark) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF342015), Color(0xFF1C2028)]
                : const [Color(0xFFFFE3C6), Color(0xFFFFF4E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.celebration_rounded,
            color: Color(0xFFFF8A00), size: 42),
      );
}
