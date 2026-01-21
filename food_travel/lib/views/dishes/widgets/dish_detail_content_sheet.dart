import 'package:flutter/material.dart';

import '../../../models/dish_model.dart';

class DishDetailContentSheet extends StatelessWidget {
  const DishDetailContentSheet({
    required this.dish,
    required this.descExpanded,
    required this.onToggleDesc,
  });

  final DishModel dish;
  final bool descExpanded;
  final VoidCallback onToggleDesc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final spicy = _clampLevel(dish.spicyLevel);
    final satiety = _clampLevel(dish.satietyLevel);

    final tags = _dedupeTags([
      ...dish.tags,
      if (dish.provinceName.isNotEmpty) dish.provinceName,
      if (dish.tag.isNotEmpty) dish.tag,
    ]);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Text(
            dish.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            dish.tag.isNotEmpty ? dish.tag : 'Món ăn đặc sản',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 18, color: Colors.orange.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _buildLocationText(dish),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tags
          if (tags.isNotEmpty) Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) {
              final isProvince = t == dish.provinceName;
              return _TagChip(
                text: t,
                highlight: isProvince,
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          _DashedDivider(color: theme.dividerColor.withOpacity(0.8)),
          const SizedBox(height: 18),

          // Quick meters
          Row(
            children: [
              Expanded(
                child: _Meter(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: Colors.red.shade500,
                  label: 'Độ cay',
                  level: spicy,
                  activeColor: Colors.red.shade500,
                  inactiveColor: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.10),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _Meter(
                  icon: Icons.emoji_food_beverage_outlined,
                  iconColor: Colors.orange.shade600,
                  label: 'Độ no',
                  level: satiety,
                  activeColor: Colors.orange.shade600,
                  inactiveColor: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.10),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Best time cards
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.calendar_month_outlined,
                  iconBg: Colors.blue.withOpacity(isDark ? 0.25 : 0.14),
                  iconColor: Colors.blue.shade600,
                  title: 'Mùa ngon nhất',
                  value: dish.bestSeason.isNotEmpty
                      ? dish.bestSeason
                      : 'Chưa cập nhật',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.access_time_outlined,
                  iconBg: Colors.amber.withOpacity(isDark ? 0.25 : 0.16),
                  iconColor: Colors.amber.shade700,
                  title: 'Thời điểm ăn',
                  value: dish.bestTime.isNotEmpty
                      ? dish.bestTime
                      : 'Chưa cập nhật',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Description
          _SectionTitle(title: 'Giới thiệu'),
          const SizedBox(height: 8),
          Text(
            dish.description.isNotEmpty
                ? dish.description
                : 'Chưa có mô tả cho món ăn này.',
            maxLines: descExpanded ? null : 3,
            overflow: descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurface.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 6),
          if ((dish.description).trim().isNotEmpty)
            TextButton(
              onPressed: onToggleDesc,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                descExpanded ? 'Thu gọn' : 'Đọc thêm',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade700,
                ),
              ),
            ),

          const SizedBox(height: 14),

          // Origin story quote
          if (dish.originStory.trim().isNotEmpty)
            _QuoteCard(text: dish.originStory),

          const SizedBox(height: 18),

          // Ingredients
          _SectionTitle(title: 'Nguyên liệu', icon: Icons.shopping_bag_outlined),
          const SizedBox(height: 10),
          ..._toLines(dish.ingredients).map((x) => _BulletLine(text: x)),

          const SizedBox(height: 18),

          // Instructions timeline
          _SectionTitle(
              title: 'Cách chế biến', icon: Icons.list_alt_outlined),
          const SizedBox(height: 12),
          _TimelineSteps(steps: _toLines(dish.instructions)),

          const SizedBox(height: 18),

          // Price range
          if (dish.priceRange.trim().isNotEmpty)
            _PriceCard(priceRange: dish.priceRange),
        ],
      ),
    );
  }

  int _clampLevel(int v) => v.clamp(0, 5);

  String _buildLocationText(DishModel dish) {
    final parts = <String>[];
    if (dish.provinceName.trim().isNotEmpty) parts.add(dish.provinceName.trim());
    if (dish.regionCode.trim().isNotEmpty) parts.add(dish.regionCode.trim());
    if (parts.isEmpty) return 'Chưa cập nhật';
    return parts.join(', ');
  }

  List<String> _dedupeTags(List<String> input) {
    final set = <String>{};
    for (final t in input) {
      final s = t.trim();
      if (s.isEmpty) continue;
      set.add(s);
    }
    return set.toList();
  }

  List<String> _toLines(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return const [];
    // Tách theo xuống dòng / dấu chấm phẩy / dấu chấm / dấu phẩy, giữ logic đơn giản
    final parts = s
        .split(RegExp(r'[\n;•]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Nếu vẫn chỉ có 1 dòng dài, thử tách theo ". " để ra step
    if (parts.length == 1 && parts.first.length > 140) {
      return parts.first
          .split(RegExp(r'\.\s+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return parts;
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.highlight});
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseBg = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);

    final hlBg = theme.brightness == Brightness.dark
        ? Colors.orange.withOpacity(0.16)
        : Colors.orange.withOpacity(0.10);

    final hlBorder = theme.brightness == Brightness.dark
        ? Colors.orange.withOpacity(0.25)
        : Colors.orange.withOpacity(0.18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight ? hlBg : baseBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight ? hlBorder : theme.dividerColor.withOpacity(0.22),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: highlight
              ? Colors.orange.shade700
              : theme.colorScheme.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.level,
    required this.activeColor,
    required this.inactiveColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int level; // 0..5
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(5, (i) {
            final active = i < level;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                decoration: BoxDecoration(
                  color: active ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.03);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: theme.colorScheme.onSurface.withOpacity(0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.25);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface.withOpacity(0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSteps extends StatelessWidget {
  const _TimelineSteps({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.dividerColor.withOpacity(0.4);

    if (steps.isEmpty) {
      return Text(
        'Chưa có hướng dẫn chế biến.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.65),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Container(width: 1, color: lineColor),
        ),
        Column(
          children: List.generate(steps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(left: 0, bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.orange.shade700, width: 2),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: theme.colorScheme.onSurface.withOpacity(0.72),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.05)
        : Colors.orange.withOpacity(0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.12)
              : Colors.orange.withOpacity(0.18),
        ),
      ),
      child: Text(
        '"$text"',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          height: 1.55,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.78),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.priceRange});
  final String priceRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.03);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(
                theme.brightness == Brightness.dark ? 0.22 : 0.12,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(Icons.sell_outlined, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khoảng giá',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  priceRange,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final dashes = (c.maxWidth / 10).floor();
      return Row(
        children: List.generate(dashes, (i) {
          return Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              color: color,
            ),
          );
        }),
      );
    });
  }
}

