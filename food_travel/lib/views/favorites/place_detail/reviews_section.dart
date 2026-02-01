import 'package:flutter/material.dart';

import '../../../services/map/serpapi_places_service.dart';

class PlaceReviewsSection extends StatelessWidget {
  const PlaceReviewsSection({
    super.key,
    required this.reviews,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<SerpApiReview> reviews;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Danh gia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFFE0C2)),
              ),
              child: const Text('Viet danh gia', style: TextStyle(fontSize: 11, color: Color(0xFFFF6A00), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          Text('Chua co bai danh gia.', style: TextStyle(color: textSecondary))
        else
          ...reviews.map(
            (r) => ReviewCard(
              review: r,
              cardBg: cardBg,
              borderColor: borderColor,
            ),
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
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
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
