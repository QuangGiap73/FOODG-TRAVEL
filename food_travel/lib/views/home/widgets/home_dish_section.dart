import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controller/favorite/favorite_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/dish_model.dart';
import '../../../router/route_names.dart';
import 'home_community_eating_section.dart';
import 'home_system_posts_section.dart';

class HomeDishSection extends StatefulWidget {
  const HomeDishSection({
    super.key,
    required this.dishes,
    required this.userLat,
    required this.userLng,
  });

  final List<DishModel> dishes;
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
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 330,
                  ),
                  itemBuilder: (context, index) {
                    final dish = widget.dishes[index];
                    return _DishCardTapWrapper(
                      dish: dish,
                      child: _HomeDishCard(
                        dish: dish,
                        isFavorite: favoriteIds.contains(dish.id),
                        onToggle:
                            () => favoriteController.toggleFavorite(dish.id),
                      ),
                    );
                  },
                )
              else
                SizedBox(
                  height: 330,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        widget.dishes.length > 12 ? 12 : widget.dishes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final dish = widget.dishes[index];
                      return SizedBox(
                        width: 225,
                        child: _DishCardTapWrapper(
                          dish: dish,
                          child: _HomeDishCard(
                            dish: dish,
                            compact: true,
                            isFavorite: favoriteIds.contains(dish.id),
                            onToggle:
                                () =>
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
  const _DishCardTapWrapper({required this.dish, required this.child});

  final DishModel dish;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, RouteNames.dishDetail, arguments: dish.id);
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
    final province =
        dish.effectiveProvinceName.isNotEmpty
            ? dish.effectiveProvinceName
            : dish.getProvince(lang);
    final imageUrl = dish.imageUrl;
    final borderColor =
        isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000);
    final cardBg = isDark ? const Color(0xFF15181E) : theme.colorScheme.surface;
    final titleColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                        imageUrl.isNotEmpty
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
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5A1F),
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      ),
                      child: Text(
                        lang == 'vi' ? 'Phải thử' : 'Must try',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onToggle,
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: const Color(0xFFFF5A1F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 5),
              child: Text(
                dishName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _DishInfoRow(
                icon: Icons.ramen_dining_rounded,
                text: dishCategory.isEmpty ? dish.tag : dishCategory,
                color: subColor,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _DishInfoRow(
                icon: Icons.location_on_rounded,
                text: province,
                color: subColor,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _DishInfoRow(
                icon: Icons.local_fire_department_rounded,
                text:
                    '${_spicyText(lang, dish.spicyLevel)} · ${dish.spicyLevel}/5',
                color: subColor,
              ),
            ),
            const Spacer(),
            Divider(height: 1, indent: 14, endIndent: 14, color: borderColor),
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _openDetail(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5A1F),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.commonViewDetail,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 17),
                        ],
                      ),
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

  void _openDetail(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.dishDetail, arguments: dish.id);
  }

  String _spicyText(String lang, int level) {
    if (lang != 'vi') {
      if (level <= 0) return 'Not spicy';
      if (level <= 2) return 'Mild';
      if (level <= 4) return 'Spicy';
      return 'Very spicy';
    }
    if (level <= 0) return 'Không cay';
    if (level <= 2) return 'Cay nhẹ';
    if (level <= 4) return 'Cay vừa';
    return 'Rất cay';
  }
}

class _DishInfoRow extends StatelessWidget {
  const _DishInfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF5A1F)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text.trim().isEmpty ? '--' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image, size: 24),
    );
  }
}
