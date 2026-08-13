import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../../models/dish_model.dart';
import '../../../services/recommendation/recommended_dish.dart';

class TodayEatSection extends StatefulWidget {
  const TodayEatSection({
    super.key,
    required this.recommendations,
    this.onTapDish,
  });

  final List<RecommendedDish> recommendations;
  final ValueChanged<DishModel>? onTapDish;

  @override
  State<TodayEatSection> createState() => _TodayEatSectionState();
}

class _TodayEatSectionState extends State<TodayEatSection> {
  int _refreshVersion = 0;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final picks = _pickThreeDishes(
      recommendations: widget.recommendations,
      refreshVersion: _refreshVersion,
    );

    if (picks.isEmpty) return const SizedBox.shrink();

    // Clamp để không vượt quá index hợp lệ
    final selected = _selectedIndex.clamp(0, picks.length - 1);
    final activeRecommendation = picks[selected];
    final activeDish = activeRecommendation.dish;

    // Nội dung phủ trên ảnh cần ổn định khi thiết bị đặt cỡ chữ lớn.
    // Vẫn cho phép tăng chữ nhẹ nhưng giới hạn để không che kín món ăn.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 1, maxScaleFactor: 1.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          // Tăng nhẹ chiều cao card để tiêu đề, lý do và ba món không chồng nhau.
          aspectRatio: 1.42,
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
                  label: t.homeTodayRefresh,
                  onTap: () {
                    setState(() {
                      // Nhan "Doi goi y" => random 3 mon moi
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
                    Text(
                      t.homeTodayEatTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _RecommendationReason(
                      text: activeRecommendation.explanation,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(picks.length, (index) {
                        final dish = picks[index].dish;
                        final lang =
                            Localizations.localeOf(context).languageCode;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == picks.length - 1 ? 0 : 6,
                            ),
                            child: _DishTabChip(
                              label: _twoWordLabel(dish.getName(lang), t),
                              isActive: selected == index,
                              onTap: () {
                                setState(() => _selectedIndex = index);
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

class _RecommendationReason extends StatefulWidget {
  const _RecommendationReason({required this.text});

  final String text;

  @override
  State<_RecommendationReason> createState() => _RecommendationReasonState();
}

class _RecommendationReasonState extends State<_RecommendationReason>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final displayText =
        isEnglish
            ? '✨ Suggested because: ${widget.text}'
            : '✨ Gợi ý vì: ${widget.text}';
    const style = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      alignment: Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: displayText, style: style),
            maxLines: 1,
            textDirection: Directionality.of(context),
          )..layout();
          final overflow = painter.width - constraints.maxWidth;

          if (overflow <= 0) {
            return Text(displayText, maxLines: 1, style: style);
          }

          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: painter.width,
              maxWidth: painter.width,
              child: AnimatedBuilder(
                animation: _controller,
                child: Text(displayText, maxLines: 1, style: style),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(-overflow * _controller.value, 0),
                    child: child,
                  );
                },
              ),
            ),
          );
        },
      ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.autorenew_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
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

String _twoWordLabel(String name, AppLocalizations t) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return t.homeDishFallback;
  if (words.length == 1) return words.first;
  return '${words[0]} ${words[1]}';
}

List<RecommendedDish> _pickThreeDishes({
  required List<RecommendedDish> recommendations,
  required int refreshVersion,
}) {
  if (recommendations.isEmpty) return const [];
  if (recommendations.length <= 3) {
    return List<RecommendedDish>.from(recommendations);
  }

  // Danh sach dau vao da duoc recommendation service xep hang.
  // Moi lan doi goi y se lay nhom 3 mon tiep theo, khong random lai top score.
  final start = (refreshVersion * 3) % recommendations.length;
  final picks = <RecommendedDish>[];
  for (var i = 0; i < 3; i++) {
    picks.add(recommendations[(start + i) % recommendations.length]);
  }
  return picks;
}
