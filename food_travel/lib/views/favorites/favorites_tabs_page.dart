import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/dish_model.dart';
import '../../models/places_model.dart';
import '../../services/favorite_service.dart';
import '../../services/restaurants/favorite_place_service.dart';
import 'tabs/favorite_dishes_tab.dart';
import 'tabs/favorite_places_tab.dart';

class FavoritesTabsPage extends StatefulWidget {
  const FavoritesTabsPage({super.key});

  @override
  State<FavoritesTabsPage> createState() => _FavoritesTabsPageState();
}

class _FavoritesTabsPageState extends State<FavoritesTabsPage> {
  int _tabIndex = 0;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(t.favoritesLoginRequired),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1218) : Colors.white;

    return StreamBuilder<List<DishModel>>(
      stream: FavoriteService().watchFavoriteDishes(user.uid),
      builder: (context, dishSnap) {
        final dishCount = dishSnap.data?.length ?? 0;

        return StreamBuilder<List<GoongNearbyPlace>>(
          stream: FavoritePlaceService().watchFavoritePlaces(user.uid),
          builder: (context, placeSnap) {
            final placeCount = placeSnap.data?.length ?? 0;

            return Scaffold(
              backgroundColor: bg,
              body: SafeArea(
                top: false,
                bottom: false,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                        child: _HeroHeader(
                          title: t.favoritesTitle,
                          subtitle: t.favoritesSubtitle,
                          dishLabel: t.favoritesTabDishes,
                          placeLabel: t.favoritesTabPlaces,
                          tabIndex: _tabIndex,
                          onTabChanged: (i) {
                            if (_tabIndex == i) return;
                            setState(() => _tabIndex = i);
                          },
                          dishCount: dishCount,
                          placeCount: placeCount,
                          searchHint: t.favoritesSearchHint,
                          savedDishesLabel: t.favoritesStatSavedDishes,
                          savedPlacesLabel: t.favoritesStatSavedPlaces,
                          todaySuggestionsLabel: t.favoritesStatTodaySuggestions,
                          searchController: _searchController,
                          onSearchChanged: (value) {
                            setState(() => _query = value.trim());
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: _tabIndex == 0
                            ? FavoriteDishesTab(
                                key: const ValueKey('dish-tab'),
                                uid: user.uid,
                                query: _query,
                              )
                            : FavoritePlacesTab(
                                key: const ValueKey('place-tab'),
                                uid: user.uid,
                                query: _query,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.dishLabel,
    required this.placeLabel,
    required this.tabIndex,
    required this.onTabChanged,
    required this.dishCount,
    required this.placeCount,
    required this.searchHint,
    required this.savedDishesLabel,
    required this.savedPlacesLabel,
    required this.todaySuggestionsLabel,
    required this.searchController,
    required this.onSearchChanged,
  });

  final String title;
  final String subtitle;
  final String dishLabel;
  final String placeLabel;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final int dishCount;
  final int placeCount;
  final String searchHint;
  final String savedDishesLabel;
  final String savedPlacesLabel;
  final String todaySuggestionsLabel;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [
                      Color(0xFF3A2414),
                      Color(0xFF1C2330),
                      Color(0xFF0D1218),
                    ],
                    stops: [0.0, 0.56, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFFFFD8AD),
                      Color(0xFFFFECDD),
                      Color(0xFFFFFFFF),
                    ],
                    stops: [0.0, 0.46, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.28)
                    : const Color(0xFFFF8A2A).withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -38,
                top: -42,
                child: IgnorePointer(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF9F43).withOpacity(isDark ? 0.18 : 0.30),
                          const Color(0xFFFF9F43).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, topInset + 12, 18, 18),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.06,
                                  letterSpacing: -0.4,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.25,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _MascotImage(isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SearchBarCard(
                      isDark: isDark,
                      hint: searchHint,
                      controller: searchController,
                      onChanged: onSearchChanged,
                    ),
                    const SizedBox(height: 12),
                    _TabSwitcher(
                      index: tabIndex,
                      onChanged: onTabChanged,
                      dishLabel: dishLabel,
                      placeLabel: placeLabel,
                    ),
                    const SizedBox(height: 12),
                    _StatsStrip(
                      dishCount: dishCount,
                      placeCount: placeCount,
                      savedDishesLabel: savedDishesLabel,
                      savedPlacesLabel: savedPlacesLabel,
                      todaySuggestionsLabel: todaySuggestionsLabel,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MascotImage extends StatelessWidget {
  const _MascotImage({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFB36A).withOpacity(isDark ? 0.18 : 0.28),
                  const Color(0xFFFFB36A).withOpacity(0.0),
                ],
              ),
            ),
          ),
          Image.asset(
            'assets/favorites/favorites1.png',
            width: 128,
            height: 118,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFFFF3EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFFF97316),
                  size: 42,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchBarCard extends StatelessWidget {
  const _SearchBarCard({
    required this.isDark,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final bool isDark;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827).withOpacity(0.92) : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF293141) : const Color(0xFFFFE1C5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.18) : const Color(0xFFFF8A2A).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFFF97316),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF7A8699),
                    ),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFFFF4EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFFF97316),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.index,
    required this.onChanged,
    required this.dishLabel,
    required this.placeLabel,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final String dishLabel;
  final String placeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F28).withOpacity(0.92) : const Color(0xFFF2F4F7).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF293141) : const Color(0xFFEDEFF3),
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(
              label: dishLabel,
              icon: Icons.restaurant_menu_rounded,
              active: index == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TabPill(
              label: placeLabel,
              icon: Icons.storefront_rounded,
              active: index == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF2A3344) : Colors.white;
    final textColor = active
        ? const Color(0xFFF97316)
        : (isDark ? const Color(0xFFB6C2D2) : const Color(0xFF64748B));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? const Color(0xFFFFD7B5) : Colors.transparent,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.16) : const Color(0xFFFF8A2A).withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.dishCount,
    required this.placeCount,
    required this.savedDishesLabel,
    required this.savedPlacesLabel,
    required this.todaySuggestionsLabel,
    required this.isDark,
  });

  final int dishCount;
  final int placeCount;
  final String savedDishesLabel;
  final String savedPlacesLabel;
  final String todaySuggestionsLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827).withOpacity(0.94) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF293141) : const Color(0xFFFFE7D3),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.14) : const Color(0xFFFF8A2A).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatBlock(
              icon: Icons.bookmark_border_rounded,
              value: dishCount,
              label: savedDishesLabel,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _StatBlock(
              icon: Icons.favorite_border_rounded,
              value: placeCount,
              label: savedPlacesLabel,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _StatBlock(
              icon: Icons.auto_awesome_rounded,
              value: 3,
              label: todaySuggestionsLabel,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? const Color(0xFF293141) : const Color(0xFFF1E3D7),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final int value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final effectiveDark = dark || isDark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: effectiveDark ? const Color(0xFF1F2937) : const Color(0xFFFFF3EA),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF97316),
            size: 20,
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  color: effectiveDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: effectiveDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
