import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controller/favorite/favorite_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/dish_model.dart';
import '../../../router/route_names.dart';
import '../../../widgets/favorite_button.dart';
import 'home_community_eating_section.dart';
import 'home_system_posts_section.dart';

class HomeDishSection extends StatefulWidget {
  const HomeDishSection({
    super.key,
    required this.dishes,
    required this.crossAxisCount,
    required this.userLat,
    required this.userLng,
  });

  final List<DishModel> dishes;
  final int crossAxisCount;
  final double? userLat;
  final double? userLng;

  @override
  State<HomeDishSection> createState() => _HomeDishSectionState();
}

class _HomeDishSectionState extends State<HomeDishSection> {
  bool _showAllSpecialties = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Consumer<FavoriteController>(
      builder: (context, favoriteController, _) {
        final favoriteIds = favoriteController.favoriteIds;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.homeSpecialtiesTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllSpecialties = !_showAllSpecialties;
                      });
                    },
                    child: Text(
                      _showAllSpecialties
                          ? t.homeSpecialtiesCollapse
                          : t.homeSpecialtiesSeeAll,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_showAllSpecialties)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.dishes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final dish = widget.dishes[index];
                    return _DishCardTapWrapper(
                      dish: dish,
                      child: _HomeDishCard(
                        dish: dish,
                        isFavorite: favoriteIds.contains(dish.id),
                        onToggle: () =>
                            favoriteController.toggleFavorite(dish.id),
                      ),
                    );
                  },
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        widget.dishes.length > 12 ? 12 : widget.dishes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final dish = widget.dishes[index];
                      return SizedBox(
                        width: 190,
                        child: _DishCardTapWrapper(
                          dish: dish,
                          child: _HomeDishCard(
                            dish: dish,
                            compact: true,
                            isFavorite: favoriteIds.contains(dish.id),
                            onToggle: () =>
                                favoriteController.toggleFavorite(dish.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              const HomeSystemPostsSection(),
              const SizedBox(height: 20),
              HomeCommunityEatingSection(
                userLat: widget.userLat,
                userLng: widget.userLng,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DishCardTapWrapper extends StatelessWidget {
  const _DishCardTapWrapper({
    required this.dish,
    required this.child,
  });

  final DishModel dish;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteNames.dishDetail,
          arguments: dish.id,
        );
      },
      child: child,
    );
  }
}

class _HomeDishCard extends StatelessWidget {
  const _HomeDishCard({
    required this.dish,
    required this.isFavorite,
    required this.onToggle,
    this.compact = false,
  });

  final DishModel dish;
  final bool compact;
  final bool isFavorite;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;
    final dishName = dish.getName(lang);
    final dishCategory = dish.getCategory(lang);
    final imageUrl = dish.imageUrl;
    final borderColor =
        isDark ? const Color(0xFF8A4B14) : const Color(0xFFFFC999);
    final cardBg = isDark ? const Color(0xFF15181E) : theme.colorScheme.surface;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withValues(alpha: isDark ? 0.16 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: compact ? 16 / 10 : 16 / 11,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            cacheWidth: compact ? 380 : 520,
                            errorBuilder: (context, error, stackTrace) {
                              return _ImageFallback(theme: theme);
                            },
                          )
                        : _ImageFallback(theme: theme),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: onToggle,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 2),
              child: Text(
                dishName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            if (dishCategory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  dishCategory,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subColor,
                    fontSize: 11,
                  ),
                ),
              ),
            if (compact) const SizedBox(height: 6) else const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 14,
                    color: Color(0xFFFF6A00),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${dish.spicyLevel}/5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: const Icon(Icons.image, size: 24),
    );
  }
}
