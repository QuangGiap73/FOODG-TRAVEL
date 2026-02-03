import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/dish_model.dart';

class TodayEatSection extends StatefulWidget {
  const TodayEatSection({
    super.key,
    required this.dishes,
    required this.provinceSeed,
    this.onTapDish,
  });

  final List<DishModel> dishes;
  final String provinceSeed;
  final ValueChanged<DishModel>? onTapDish;

  @override
  State<TodayEatSection> createState() => _TodayEatSectionState();
}

class _TodayEatSectionState extends State<TodayEatSection> {
  int _refreshVersion = 0;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final picks = _pickThreeDishes(
      dishes: widget.dishes,
      provinceSeed: widget.provinceSeed,
      refreshVersion: _refreshVersion,
    );

    if (picks.isEmpty) return const SizedBox.shrink();

    // Clamp để không vượt quá index hợp lệ
    final selected = _selectedIndex.clamp(0, picks.length - 1);
    final activeDish = picks[selected];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9.8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ========= BACKGROUND: image + tap + swipe =========
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,

                // Tap vào nền (không phải chip/nút) -> mở chi tiết món
                onTap: () => widget.onTapDish?.call(activeDish),

                // Vuốt ngang để đổi món
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v == 0) return;

                  setState(() {
                    if (v < 0) {
                      // Vuốt sang trái -> next
                      _selectedIndex = (_selectedIndex + 1).clamp(
                        0,
                        picks.length - 1,
                      );
                    } else {
                      // Vuốt sang phải -> prev
                      _selectedIndex = (_selectedIndex - 1).clamp(
                        0,
                        picks.length - 1,
                      );
                    }
                  });
                },

                child: _buildImage(activeDish.imageUrl),
              ),
            ),

            // ========= GRADIENT OVERLAY =========
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x55000000),
                      Color(0xCC000000),
                    ],
                  ),
                ),
              ),
            ),

            // ========= REFRESH BUTTON =========
            Positioned(
              top: 12,
              right: 12,
              child: _RefreshButton(
                onTap: () {
                  setState(() {
                    // Nhấn "Đổi gợi ý" => random 3 món mới
                    _refreshVersion++;
                    _selectedIndex = 0;
                  });
                },
              ),
            ),

            // ========= TITLE + CHIPS =========
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hom nay an gi?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(picks.length, (index) {
                      final dish = picks[index];
                      return _DishTabChip(
                        label: _twoWordLabel(dish.name),
                        isActive: selected == index,
                        onTap: () {
                          setState(() => _selectedIndex = index);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFF1A2233),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white70, size: 32),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFF1A2233),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: 32,
            ),
          ),
        );
      },
    );
  }
}

class _DishTabChip extends StatelessWidget {
  const _DishTabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive ? const Color(0xFFFF7A1A) : const Color(0x883A3D45),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xCC3C5E80),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.autorenew_rounded, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Doi goi y',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _twoWordLabel(String name) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return 'Mon';
  if (words.length == 1) return words.first;
  return '${words[0]} ${words[1]}';
}

List<DishModel> _pickThreeDishes({
  required List<DishModel> dishes,
  required String provinceSeed,
  required int refreshVersion,
}) {
  if (dishes.isEmpty) return const [];
  if (dishes.length <= 3) return List<DishModel>.from(dishes);

  final now = DateTime.now();
  // Seed theo ngay + tinh + so lan doi goi y
  final daySeed = now.year * 1000 + _dayOfYear(now);
  final seed = '$provinceSeed-$daySeed-$refreshVersion'.hashCode;
  final random = Random(seed);

  final pool = List<DishModel>.from(dishes);
  final picks = <DishModel>[];
  while (picks.length < 3 && pool.isNotEmpty) {
    final index = random.nextInt(pool.length);
    picks.add(pool.removeAt(index));
  }
  return picks;
}

int _dayOfYear(DateTime date) {
  final first = DateTime(date.year, 1, 1);
  return date.difference(first).inDays + 1;
}
