import 'package:flutter/material.dart';

import '../../models/system_post.dart';
import '../../services/system_posts/system_post_service.dart';

class SystemPostDetailPage extends StatelessWidget {
  const SystemPostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final service = SystemPostService();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Bài viết hệ thống',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<SystemPost?>(
        stream: service.watchPost(postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _SystemPostEmptyState(
              message: 'Không thể tải bài viết hệ thống.',
            );
          }

          final post = snapshot.data;
          if (post == null) {
            return const _SystemPostEmptyState(
              message: 'Bài viết hệ thống không còn hiển thị.',
            );
          }

          final title = post.title(languageCode);
          final summary = post.summary(languageCode);
          final content = post.content(languageCode);
          final category = post.category(languageCode);
          final paragraphs = content
              .split(RegExp(r'\r?\n+'))
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
          final region = (post.regionCode ?? '').trim();
          final province = (post.provinceName34 ?? '').trim();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171B22) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A303A) : const Color(0xFFF1E7D8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.coverImage.trim().isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            post.coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackImage(isDark),
                          ),
                        ),
                      )
                    else
                      _fallbackImage(isDark),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (category.trim().isNotEmpty) _infoChip(category),
                              if (province.isNotEmpty) _infoChip(province),
                              if (region.isNotEmpty) _infoChip(region),
                              if (post.featured) _infoChip('Nổi bật'),
                              if (post.pinned) _infoChip('Ghim'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            title.isNotEmpty ? title : 'Bài viết hệ thống',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (summary.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              summary,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          ...paragraphs.map(
                            (paragraph) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                paragraph,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.72,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ),
                          if (post.tags.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: post.tags.map(_tagChip).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fallbackImage(bool isDark) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF20262F), Color(0xFF14181E)]
              : const [Color(0xFFFFF3E0), Color(0xFFFFE1B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.article_outlined,
          size: 54,
          color: Color(0xFFFF8A00),
        ),
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF7A00),
        ),
      ),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF2DFC9)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7C5A3B),
        ),
      ),
    );
  }
}

class _SystemPostEmptyState extends StatelessWidget {
  const _SystemPostEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
