import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/place_review_model.dart';
import '../../../models/places_model.dart';
import '../../../services/map/serpapi_places_service.dart';
import '../../../services/restaurants/place_review_service.dart';
import 'place_detail_typography.dart';

class PlaceReviewsSection extends StatefulWidget {
  const PlaceReviewsSection({
    super.key,
    required this.place,
    required this.reviews,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onWriteReview,
  });

  final GoongNearbyPlace place;
  final List<SerpApiReview> reviews;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onWriteReview;

  @override
  State<PlaceReviewsSection> createState() => _PlaceReviewsSectionState();
}

class _PlaceReviewsSectionState extends State<PlaceReviewsSection> {
  bool _showAll = false;

  Future<void> _confirmDeleteReview(
    BuildContext context,
    PlaceReviewModel review,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xoa binh luan'),
          content: const Text('Ban chac chan muon xoa binh luan nay?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Huy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xoa'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final service = PlaceReviewService();
    final placeId = service.placeIdOf(widget.place);
    await service.deleteMyReview(
      placeId: placeId,
      userId: review.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<PlaceReviewModel>>(
      stream: PlaceReviewService().watchReviews(
        PlaceReviewService().placeIdOf(widget.place),
      ),
      builder: (context, snap) {
        final firebaseReviews = snap.data ?? const <PlaceReviewModel>[];
        final reviewCount = firebaseReviews.length + widget.reviews.length;

        final cards = <Widget>[
          ...firebaseReviews.map(
            (r) => FirebaseReviewCard(
              review: r,
              cardBg: widget.cardBg,
              borderColor: widget.borderColor,
              canDelete: r.userId == currentUid,
              onDelete: () => _confirmDeleteReview(context, r),
            ),
          ),
          ...widget.reviews.map(
            (r) => ReviewCard(
              review: r,
              cardBg: widget.cardBg,
              borderColor: widget.borderColor,
            ),
          ),
        ];

        final hasMore = cards.length > 5;
        final visibleCards = _showAll ? cards : cards.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh gia ($reviewCount)',
                  style: PlaceDetailTypography.sectionTitle(widget.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFE0C2)),
                  ),
                  child: InkWell(
                    onTap: widget.onWriteReview,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Text(
                        'Viet danh gia',
                        style: PlaceDetailTypography.chip(const Color(0xFFFF6A00)).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (cards.isEmpty)
              Text(
                'Chua co bai danh gia.',
                style: PlaceDetailTypography.body(widget.textSecondary),
              )
            else ...[
              ...visibleCards,
              if (hasMore)
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(_showAll ? 'Thu gon' : 'Xem them'),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    required this.cardBg,
    required this.borderColor,
  });

  final SerpApiReview review;
  final Color cardBg;
  final Color borderColor;

  List<Widget> _buildStars(double rating) {
    final out = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      if (rating >= i) {
        out.add(const Icon(Icons.star, size: 14, color: Color(0xFFFF6A00)));
      } else if (rating >= i - 0.5) {
        out.add(const Icon(Icons.star_half, size: 14, color: Color(0xFFFF6A00)));
      } else {
        out.add(const Icon(Icons.star_border, size: 14, color: Color(0xFFFF6A00)));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final avatarBg = isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0);
    final name = review.userName.isEmpty ? 'Nguoi dung' : review.userName;
    final subtitle = review.dateText.isNotEmpty
        ? '${review.dateText} - Da an o quan nay'
        : 'Da an o quan nay';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: avatarBg,
                child: Text(
                  name[0].toUpperCase(),
                  style: PlaceDetailTypography.chip(textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: PlaceDetailTypography.bodyStrong(textPrimary)),
                    Text(subtitle, style: PlaceDetailTypography.caption(textSecondary)),
                  ],
                ),
              ),
              Row(children: _buildStars(review.rating)),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.text, style: PlaceDetailTypography.body(textSecondary)),
        ],
      ),
    );
  }
}

class FirebaseReviewCard extends StatelessWidget {
  const FirebaseReviewCard({
    super.key,
    required this.review,
    required this.cardBg,
    required this.borderColor,
    required this.canDelete,
    this.onDelete,
  });

  final PlaceReviewModel review;
  final Color cardBg;
  final Color borderColor;
  final VoidCallback? onDelete;
  final bool canDelete;

  List<Widget> _buildStars(double rating) {
    final out = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      if (rating >= i) {
        out.add(const Icon(Icons.star, size: 14, color: Color(0xFFFF6A00)));
      } else if (rating >= i - 0.5) {
        out.add(const Icon(Icons.star_half, size: 14, color: Color(0xFFFF6A00)));
      } else {
        out.add(const Icon(Icons.star_border, size: 14, color: Color(0xFFFF6A00)));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final avatarBg = isDark ? const Color(0xFF1F2630) : const Color(0xFFE2E8F0);
    final name = review.userName.isEmpty ? 'Nguoi dung' : review.userName;
    final dateText =
        '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: avatarBg,
                child: Text(
                  name[0].toUpperCase(),
                  style: PlaceDetailTypography.chip(textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: PlaceDetailTypography.bodyStrong(textPrimary)),
                    Text(
                      '$dateText - Danh gia tu nguoi dung',
                      style: PlaceDetailTypography.caption(textSecondary),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              Row(children: _buildStars(review.rating)),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: PlaceDetailTypography.body(textSecondary)),
        ],
      ),
    );
  }
}
