import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/system_post.dart';
import '../../../services/system_posts/system_post_service.dart';
import '../system_post_detail_page.dart';

class HomeSystemPostsSection extends StatelessWidget {
  const HomeSystemPostsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;

    return StreamBuilder<List<SystemPost>>(
      stream: SystemPostService().watchPublishedPosts(limit: 6),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final posts = snapshot.data ?? const <SystemPost>[];
        if (posts.isEmpty) return const SizedBox.shrink();

        final featured = posts.first;
        final title = featured.title(languageCode);
        final summary = featured.summary(languageCode);
        final category = featured.category(languageCode);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 18,
                  color: Color(0xFFFF8A00),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.systemGuideTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SystemPostDetailPage(postId: featured.id),
                  ),
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF2A1C14)
                          : const Color(0xFFFFF1E4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDark
                            ? const Color(0xFF55321D)
                            : const Color(0xFFFFD8B5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFFF8A00,
                      ).withValues(alpha: isDark ? 0.10 : 0.08),
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
                            if (category.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E4),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF7A00),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              title.isNotEmpty ? title : 'Bài viết hệ thống',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              summary.trim().isNotEmpty
                                  ? summary
                                  : 'Khám phá thêm các nội dung hệ thống được biên tập sẵn.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.55,
                                color:
                                    isDark
                                        ? Colors.white70
                                        : const Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              (featured.provinceName34 ??
                                      featured.regionCode ??
                                      'Xem chi tiết')
                                  .toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 118,
                          height: 82,
                          color:
                              isDark
                                  ? const Color(0xFF211A16)
                                  : const Color(0xFFFFE9D4),
                          child:
                              featured.coverImage.trim().isNotEmpty
                                  ? Image.network(
                                    featured.coverImage,
                                    // Ảnh cẩm nang có thể không cùng tỷ lệ với
                                    // thumbnail. contain giữ lại toàn bộ banner
                                    // thay vì cắt mất hai cạnh như BoxFit.cover.
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder:
                                        (_, __, ___) => _fallbackImage(),
                                  )
                                  : _fallbackImage(),
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

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFFFF1E4),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: Color(0xFFFF8A00),
        size: 28,
      ),
    );
  }
}
