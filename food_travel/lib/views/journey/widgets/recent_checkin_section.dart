import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/journey/checkin_model.dart';

class RecentCheckinSection extends StatelessWidget {
  const RecentCheckinSection({super.key, required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    final uid = userId?.trim();
    if (uid == null || uid.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<JourneyCheckin>>(
      stream: _watchRecentCheckins(uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <JourneyCheckin>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            items.isEmpty) {
          return const _RecentCheckinLoading();
        }
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF4E5D6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const _RecentHeader(),
              const SizedBox(height: 14),
              ...List.generate(items.length, (index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 10,
                  ),
                  child: _RecentCheckinTile(item: item),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Stream<List<JourneyCheckin>> _watchRecentCheckins(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journey')
        .doc('summary')
        .collection('checkins')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(JourneyCheckin.fromDoc).toList());
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFFF9A00)),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Check-in gần đây',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentCheckinTile extends StatelessWidget {
  const _RecentCheckinTile({required this.item});

  final JourneyCheckin item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _RecentImage(imageUrl: item.placeImageUrl ?? ''),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.placeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202531),
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (item.provinceName.trim().isNotEmpty)
                    _MetaText(item.provinceName.trim()),
                  if ((item.districtName ?? '').trim().isNotEmpty)
                    _MetaText(item.districtName!.trim()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _timeLabel(item.createdAt),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A909B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '+${item.pointsEarned} điểm',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF8A00),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _timeLabel(Timestamp? timestamp) {
    if (timestamp == null) return 'Vừa xong';
    final now = DateTime.now();
    final created = timestamp.toDate();
    final diff = now.difference(created);
    if (diff.inDays <= 0) return 'Hôm nay';
    if (diff.inDays == 1) return 'Hôm qua';
    return '${diff.inDays} ngày trước';
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

class _RecentImage extends StatelessWidget {
  const _RecentImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _fallback();
    }

    return Image.network(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: 60,
      height: 60,
      color: const Color(0xFFFFF1E4),
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_rounded, color: Color(0xFFFF8A00)),
    );
  }
}

class _RecentCheckinLoading extends StatelessWidget {
  const _RecentCheckinLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF4E5D6)),
      ),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == 2 ? 0 : 10),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAF5),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }),
      ),
    );
  }
}
