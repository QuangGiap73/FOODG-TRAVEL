import 'package:flutter/material.dart';

import '../../models/places_model.dart';
import '../../services/map/serpapi_places_service.dart';

class FavoritePlaceDetailPage extends StatelessWidget {
  const FavoritePlaceDetailPage({super.key, required this.place});

  final GoongNearbyPlace place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F131A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Chi tiet quan an'),
        backgroundColor: bg,
        elevation: 0,
      ),
      body: FutureBuilder<GoongNearbyPlace?>(
        future: SerpApiPlacesService().fetchPlaceDetail(place),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator(minHeight: 2);
          }

          final detail = snapshot.data ?? place;
          return FutureBuilder<List<SerpApiReview>>(
            future: SerpApiPlacesService().fetchReviews(
              dataId: detail.serpDataId,
              limit: 6,
            ),
            builder: (context, reviewSnap) {
              final reviews = reviewSnap.data ?? const <SerpApiReview>[];
              return _DetailBody(place: detail, reviews: reviews);
            },
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.place, required this.reviews});

  final GoongNearbyPlace place;
  final List<SerpApiReview> reviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262B33) : const Color(0xFFE2E8F0);

    final name = place.name.trim().isEmpty ? 'Quan an' : place.name.trim();
    final address = place.address.trim().isEmpty
        ? 'Dang cap nhat dia chi'
        : place.address.trim();
    final rating = place.rating?.toStringAsFixed(1) ?? '';
    final reviewCount = place.reviewCount;
    final price = place.price?.trim() ?? '';
    final phone = place.phone?.trim() ?? '';
    final category = place.category?.trim() ?? '';
    final isOpen = place.isOpen;
    final closingTime = place.closingTime?.trim() ?? '';
    final photos = place.photoUrls.isNotEmpty
        ? place.photoUrls
        : (place.photoUrl.isNotEmpty ? [place.photoUrl] : const <String>[]);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderGallery(photoUrls: photos),
        const SizedBox(height: 12),
        Text(
          name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        if (category.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(category, style: TextStyle(color: textSecondary)),
        ],
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Danh gia',
          child: Row(
            children: [
              const Icon(Icons.star, size: 16, color: Color(0xFFF97316)),
              const SizedBox(width: 6),
              Text(
                rating.isEmpty ? 'Chua co danh gia' : rating,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (reviewCount != null) ...[
                const SizedBox(width: 6),
                Text('($reviewCount)', style: TextStyle(color: textSecondary)),
              ],
            ],
          ),
          cardBg: cardBg,
          borderColor: borderColor,
        ),
        const SizedBox(height: 10),
        _InfoCard(
          title: 'Trang thai',
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: isOpen == null
                    ? textSecondary
                    : (isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isOpen == null
                      ? 'Dang cap nhat gio mo cua'
                      : (isOpen ? 'Dang mo cua' : 'Dang dong cua'),
                  style: TextStyle(color: textSecondary),
                ),
              ),
              if (closingTime.isNotEmpty)
                Text('Dong luc $closingTime', style: TextStyle(color: textSecondary)),
            ],
          ),
          cardBg: cardBg,
          borderColor: borderColor,
        ),
        const SizedBox(height: 10),
        _InfoCard(
          title: 'Dia chi',
          child: Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(address, style: TextStyle(color: textPrimary)),
              ),
            ],
          ),
          cardBg: cardBg,
          borderColor: borderColor,
        ),
        const SizedBox(height: 10),
        _InfoCard(
          title: 'Lien he',
          child: Row(
            children: [
              Icon(Icons.call_outlined, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                phone.isEmpty ? 'Chua co so dien thoai' : phone,
                style: TextStyle(color: textPrimary),
              ),
            ],
          ),
          cardBg: cardBg,
          borderColor: borderColor,
        ),
        if (price.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoCard(
            title: 'Muc gia',
            child: Text(price, style: TextStyle(color: textPrimary)),
            cardBg: cardBg,
            borderColor: borderColor,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Danh gia gan day',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          Text(
            'Chua co bai danh gia.',
            style: TextStyle(color: textSecondary),
          )
        else
          ...reviews.map(
            (r) => _ReviewCard(
              review: r,
              cardBg: cardBg,
              borderColor: borderColor,
            ),
          ),
      ],
    );
  }
}

class _HeaderGallery extends StatefulWidget {
  const _HeaderGallery({required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<_HeaderGallery> createState() => _HeaderGalleryState();
}

class _HeaderGalleryState extends State<_HeaderGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final placeholder = isDark ? const Color(0xFF1F242C) : const Color(0xFFE2E8F0);
    final urls = widget.photoUrls;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: urls.isEmpty
            ? Container(
                color: placeholder,
                child: const Icon(Icons.storefront_outlined, size: 40),
              )
            : Stack(
                children: [
                  PageView.builder(
                    itemCount: urls.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      return Image.network(urls[i], fit: BoxFit.cover);
                    },
                  ),
                  if (urls.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(urls.length, (i) {
                          final active = i == _index;
                          return Container(
                            width: active ? 10 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
    required this.cardBg,
    required this.borderColor,
  });

  final String title;
  final Widget child;
  final Color cardBg;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.cardBg,
    required this.borderColor,
  });

  final SerpApiReview review;
  final Color cardBg;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.user.isEmpty ? 'Nguoi dung' : review.user,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (review.dateText.isNotEmpty)
                Text(
                  review.dateText,
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Color(0xFFF97316)),
              const SizedBox(width: 4),
              Text(
                review.rating == 0 ? 'N/A' : review.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.text,
            style: TextStyle(color: textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
