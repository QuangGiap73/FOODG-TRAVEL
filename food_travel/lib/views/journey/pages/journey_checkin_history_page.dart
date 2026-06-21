import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/journey/checkin_model.dart';

class JourneyCheckinHistoryPage extends StatelessWidget {
  const JourneyCheckinHistoryPage({
    super.key,
    required this.userId,
    required this.provinceCode,
    required this.provinceName,
  });

  final String userId;
  final String provinceCode;
  final String provinceName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  _TopIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Lịch sử check-in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF202531),
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<JourneyCheckin>>(
                stream: _watchProvinceCheckins(),
                builder: (context, snapshot) {
                  final checkins = snapshot.data ?? const <JourneyCheckin>[];
                  return _HistoryContent(
                    provinceName: provinceName,
                    checkins: checkins,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<JourneyCheckin>> _watchProvinceCheckins() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journey')
        .doc('summary')
        .collection('checkins')
        .orderBy('createdAt', descending: true)
        .limit(120)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(JourneyCheckin.fromDoc)
              .where(
                (item) =>
                    item.provinceCode.trim().toLowerCase() ==
                    provinceCode.trim().toLowerCase(),
              )
              .toList();
        });
  }
}

class _HistoryContent extends StatefulWidget {
  const _HistoryContent({
    required this.provinceName,
    required this.checkins,
  });

  final String provinceName;
  final List<JourneyCheckin> checkins;

  @override
  State<_HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends State<_HistoryContent> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(widget.checkins);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 10,
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: _filter == _HistoryFilter.all,
                  onTap: () => setState(() => _filter = _HistoryFilter.all),
                ),
                _FilterChip(
                  label: 'Quán ăn',
                  selected: _filter == _HistoryFilter.restaurant,
                  onTap: () =>
                      setState(() => _filter = _HistoryFilter.restaurant),
                ),
                _FilterChip(
                  label: 'Quán cafe',
                  selected: _filter == _HistoryFilter.cafe,
                  onTap: () => setState(() => _filter = _HistoryFilter.cafe),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyHistoryState(provinceName: widget.provinceName)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _HistoryCheckinTile(item: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<JourneyCheckin> _applyFilter(List<JourneyCheckin> items) {
    switch (_filter) {
      case _HistoryFilter.all:
        return items;
      case _HistoryFilter.restaurant:
        return items.where((item) => !_isCafe(item.placeType)).toList();
      case _HistoryFilter.cafe:
        return items.where((item) => _isCafe(item.placeType)).toList();
    }
  }

  bool _isCafe(String value) {
    final text = value.trim().toLowerCase();
    return text.contains('cafe') || text.contains('coffee');
  }
}

enum _HistoryFilter {
  all,
  restaurant,
  cafe,
}

class _HistoryCheckinTile extends StatelessWidget {
  const _HistoryCheckinTile({required this.item});

  final JourneyCheckin item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _HistoryImage(imageUrl: item.placeImageUrl ?? ''),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.placeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202531),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.placeAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF707680),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeText(item.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A909B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '+${item.pointsEarned} điểm',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF7A00),
            ),
          ),
        ],
      ),
    );
  }

  String _timeText(Timestamp? createdAt) {
    if (createdAt == null) return 'Vừa xong';
    final date = createdAt.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 2) {
      return '${difference.inDays} ngày trước';
    }
    if (difference.inDays >= 1) {
      return 'Hôm qua';
    }
    return 'Hôm nay ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _HistoryImage extends StatelessWidget {
  const _HistoryImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: 72,
        height: 72,
        color: const Color(0xFFFFF1E2),
        alignment: Alignment.center,
        child: const Icon(
          Icons.restaurant_rounded,
          size: 28,
          color: Color(0xFFFF7A00),
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 72,
          height: 72,
          color: const Color(0xFFFFF1E2),
          alignment: Alignment.center,
          child: const Icon(
            Icons.restaurant_rounded,
            size: 28,
            color: Color(0xFFFF7A00),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF7A00) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFFF7A00) : const Color(0xFFF0E2D3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF4A505B),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.provinceName});

  final String provinceName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 54,
              color: Color(0xFFFFB366),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có lịch sử check-in',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF202531),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Khi bạn check-in ở $provinceName, lịch sử sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF727985),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: const Color(0xFF262B34)),
        ),
      ),
    );
  }
}
