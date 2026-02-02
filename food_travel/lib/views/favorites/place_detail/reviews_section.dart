import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/place_review_model.dart';
import '../../../models/places_model.dart';
import '../../../services/map/serpapi_places_service.dart';
import '../../../services/restaurants/place_review_service.dart';

class PlaceReviewsSection extends StatelessWidget {
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

    // Xoa review trong Firestore, stream se tu cap nhat lai UI.
    final service = PlaceReviewService();
    final placeId = service.placeIdOf(place);
    await service.deleteMyReview(
      placeId: placeId,
      userId: review.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh gia ($fallbackCount)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFFE0C2)),
              ),
              child: InkWell(
                onTap: onWriteReview,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Text(
                    'Viet danh gia',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF6A00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Uu tien review Firebase len tren, sau do fallback SerpAPI.
        StreamBuilder<List<PlaceReviewModel>>(
          stream: PlaceReviewService().watchReviews(
            PlaceReviewService().placeIdOf(place),
          ),
          builder: (context, snap) {
            final firebaseReviews = snap.data ?? const <PlaceReviewModel>[];
            if (firebaseReviews.isEmpty && reviews.isEmpty) {
              return Text(
                'Chua co bai danh gia.',
                style: TextStyle(color: textSecondary),
              );
            }

            return Column(
              children: [
                ...firebaseReviews.map(
                  (r) => FirebaseReviewCard(
                    review: r,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    canDelete: r.userId == currentUid,
                    onDelete: () => _confirmDeleteReview(context, r),
                  ),
                ),
                ...reviews.map(
                  (r) => ReviewCard(
                    review: r,
                    cardBg: cardBg,
                    borderColor: borderColor,
                  ),
                ),
              ],
            );
          },
        ),
      ],
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
        ? '${review.dateText} ? Da an o quan nay'
        : 'Da an o quan nay';
    final rating = review.rating;

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
                  style: TextStyle(color: textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(children: _buildStars(rating)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.text,
            style: TextStyle(color: textSecondary, height: 1.4),
          ),
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
                  style: TextStyle(color: textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$dateText ? Danh gia tu nguoi dung',
                      style: TextStyle(color: textSecondary, fontSize: 11),
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
          Text(
            review.comment,
            style: TextStyle(color: textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
