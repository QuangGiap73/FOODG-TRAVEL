import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/dish_model.dart';
import '../../models/province_model.dart';
import '../../services/food_service.dart';
import '../dishes/dish_detail_page.dart';

class ProvinceDetailPage extends StatefulWidget {
  const ProvinceDetailPage({super.key, required this.provinceId});

  final String provinceId;

  @override
  State<ProvinceDetailPage> createState() => _ProvinceDetailPageState();
}

class _ProvinceDetailPageState extends State<ProvinceDetailPage> {
  final _service = FoodService();
  final _pageController = PageController();
  final _scrollController = ScrollController();
  final _infoSectionKey = GlobalKey();
  final _foodSectionKey = GlobalKey();
  final ValueNotifier<int> _imageIndex = ValueNotifier<int>(0);
  final ValueNotifier<bool> _introExpanded = ValueNotifier<bool>(false);

  Timer? _autoSlideTimer;
  int _imageCount = 0;
  String _selectedLegacyFilter = '';

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    _imageIndex.dispose();
    _introExpanded.dispose();
    super.dispose();
  }

  void _startAutoSlide(int count) {
    if (_imageCount == count) return;
    _imageCount = count;
    _imageIndex.value = 0;
    _autoSlideTimer?.cancel();
    if (_imageCount < 2) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final current = _pageController.page?.round() ?? _imageIndex.value;
      final next = (current + 1) % _imageCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  List<String> _provinceQueryKeys(ProvinceModel province) {
    return [
      province.code,
      province.name,
      province.id,
      ...province.mergedFrom,
    ]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  String _formatRegion(String raw) {
    return raw.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  String _humanizeProvince(String value) {
    final normalized = value.trim().replaceAll('_', ' ').replaceAll('-', ' ');
    if (normalized.isEmpty) return '';
    return normalized
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _legacyLabel(String code) {
    final humanized = _humanizeProvince(code);
    return humanized.isEmpty ? '' : '$humanized c\u0169';
  }

  String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _legacyCodesOf(ProvinceModel province) {
    final ignored = {
      province.id.trim().toLowerCase(),
      province.code.trim().toLowerCase(),
      province.name.trim().toLowerCase(),
    };
    return province.mergedFrom
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .where((value) => !ignored.contains(value.toLowerCase()))
        .toSet()
        .toList();
  }

  List<DishModel> _filterDishes(
    List<DishModel> dishes, {
    ProvinceModel? displayProvince,
  }) {
    if (_selectedLegacyFilter.isEmpty) return dishes;
    final targetKeys = {
      _selectedLegacyFilter,
      _legacyLabel(_selectedLegacyFilter).replaceAll(' c\u0169', ''),
      displayProvince?.id ?? '',
      displayProvince?.code ?? '',
      displayProvince?.name ?? '',
      displayProvince?.slug ?? '',
    }.map(_normalizeKey).where((value) => value.isNotEmpty).toSet();

    return dishes
        .where((dish) => _dishMatchesProvinceKeys(dish, targetKeys))
        .toList();
  }

  bool _dishMatchesProvinceKeys(DishModel dish, Set<String> targetKeys) {
    final dishKeys = {
      dish.legacyProvinceCode,
      dish.legacyProvinceName,
      dish.provinceCode,
      dish.provinceName,
      dish.provinceCode34,
      dish.provinceName34,
      dish.provinceI18n['vi'] ?? '',
      dish.provinceI18n['en'] ?? '',
    }.map(_normalizeKey).where((value) => value.isNotEmpty).toSet();

    return dishKeys.any(targetKeys.contains);
  }

  Stream<ProvinceModel?> _watchDisplayProvince(ProvinceModel province) {
    if (_selectedLegacyFilter.trim().isEmpty) {
      return Stream.value(province);
    }
    return _service.watchProvinceDetailByCode(_selectedLegacyFilter);
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null || !_scrollController.hasClients) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return StreamBuilder<ProvinceModel?>(
      stream: _service.watchProvinceDetailByCode(widget.provinceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text(t.provinceLoadError)),
          );
        }

        final province = snapshot.data;
        if (province == null) {
          return Scaffold(
            body: Center(child: Text(t.provinceNotFound)),
          );
        }

        final legacyCodes = _legacyCodesOf(province);

        if (_selectedLegacyFilter.isNotEmpty &&
            !legacyCodes.contains(_selectedLegacyFilter)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedLegacyFilter = '');
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFFBF5),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: const Color(0xFF1F2937),
            centerTitle: true,
            title: Text(
              province.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              _buildPageBannerBackground(),
              StreamBuilder<ProvinceModel?>(
                stream: _watchDisplayProvince(province),
                builder: (context, displaySnapshot) {
                  final displayProvince = displaySnapshot.data ?? province;
                  final images = displayProvince.imageUrls.isNotEmpty
                      ? displayProvince.imageUrls
                      : (displayProvince.imageUrl.isNotEmpty
                          ? [displayProvince.imageUrl]
                          : const <String>[]);
                  _startAutoSlide(images.length);

                  final region = (displayProvince.regionCode ?? '').trim();

                  return StreamBuilder<List<DishModel>>(
                    stream: _service.watchDishesByProvinceKeys(
                      _provinceQueryKeys(province),
                    ),
                    builder: (context, dishSnapshot) {
                      final dishes = dishSnapshot.data ?? const <DishModel>[];
                      final visibleDishes = _filterDishes(
                        dishes,
                        displayProvince: displayProvince,
                      );

                      return ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 104, 16, 28),
                        children: [
                          _buildHeroSection(
                            theme: theme,
                            province: displayProvince,
                            images: images,
                            region: region,
                            dishCount: visibleDishes.length,
                            legacyCount: legacyCodes.length,
                          ),
                          const SizedBox(height: 18),
                          if (legacyCodes.isNotEmpty) ...[
                            _buildLegacySection(theme, legacyCodes),
                            const SizedBox(height: 18),
                          ],
                          _buildIntroSection(
                            theme,
                            displayProvince,
                            key: _infoSectionKey,
                          ),
                          const SizedBox(height: 18),
                          _buildFoodSection(
                            key: _foodSectionKey,
                            theme: theme,
                            province: displayProvince,
                            legacyCodes: legacyCodes,
                            snapshot: dishSnapshot,
                            dishes: visibleDishes,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageBannerBackground() {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/person/profile_A.png',
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.42),
                  const Color(0xFFFFFBF5).withValues(alpha: 0.84),
                  const Color(0xFFFFFBF5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection({
    required ThemeData theme,
    required ProvinceModel province,
    required List<String> images,
    required String region,
    required int dishCount,
    required int legacyCount,
  }) {
    final t = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF2DE), Color(0xFFFFF8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8A00).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(
                  'assets/person/profile_A.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.38),
                      Colors.white.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBanner(
                    theme: theme,
                    province: province,
                    region: region,
                  ),
                  const SizedBox(height: 12),
                  _buildHero(images, province.name),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetricChip(
                        theme,
                        Icons.location_on_rounded,
                        region.isEmpty
                            ? t.provinceDefaultRegion
                            : _formatRegion(region),
                      ),
                      _buildMetricChip(
                        theme,
                        Icons.restaurant_menu_rounded,
                        t.provinceDishMetric(dishCount),
                      ),
                      if (legacyCount > 0)
                        _buildMetricChip(
                          theme,
                          Icons.layers_rounded,
                          t.provinceLegacyMetric(legacyCount),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner({
    required ThemeData theme,
    required ProvinceModel province,
    required String region,
  }) {
    final t = AppLocalizations.of(context)!;
    final regionText =
        region.isEmpty ? t.provinceDefaultRegion : _formatRegion(region);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.provinceExploreTitle(province.name),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.provinceHeroSubtitle(regionText),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacySection(ThemeData theme, List<String> legacyCodes) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.provinceLegacySectionTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.provinceLegacySectionSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: legacyCodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final code = legacyCodes[index];
              final isActive = _selectedLegacyFilter == code;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLegacyFilter = isActive ? '' : code;
                    _introExpanded.value = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 182,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFF8A00) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFFF8A00)
                          : const Color(0xFFF2D7B3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isActive
                            ? const Color(0xFFFF8A00).withValues(alpha: 0.22)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFFFFF2DE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.landscape_rounded,
                          color:
                              isActive ? Colors.white : const Color(0xFFFF8A00),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _legacyLabel(code),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color:
                              isActive ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? t.provinceLegacyActiveHint
                            : t.provinceLegacyInactiveHint,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.92)
                              : const Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIntroSection(
    ThemeData theme,
    ProvinceModel province, {
    Key? key,
  }) {
    final t = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final desc = (languageCode == 'en'
            ? province.descriptionEn ?? province.description
            : province.description)
        ?.trim() ??
        '';

    return Container(
      key: key,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3DEC1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2DE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFF8A00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.provinceOverviewTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.provinceOverviewSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildActionButton(
                label: t.provinceOverviewAction,
                icon: Icons.article_outlined,
                onTap: () => _scrollToSection(_infoSectionKey),
              ),
              _buildActionButton(
                label: t.provinceFoodAction,
                icon: Icons.restaurant_menu_rounded,
                onTap: () => _scrollToSection(_foodSectionKey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<bool>(
            valueListenable: _introExpanded,
            builder: (context, expanded, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desc.isEmpty
                        ? t.provinceDescriptionUpdating
                        : desc,
                    maxLines: expanded ? null : 5,
                    overflow: expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                      height: 1.6,
                    ),
                  ),
                  if (desc.length > 180) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _introExpanded.value = !expanded,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8A00),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        expanded ? t.commonCollapse : t.commonSeeMore,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSection({
    Key? key,
    required ThemeData theme,
    required ProvinceModel province,
    required List<String> legacyCodes,
    required AsyncSnapshot<List<DishModel>> snapshot,
    required List<DishModel> dishes,
  }) {
    final t = AppLocalizations.of(context)!;
    return Container(
      key: key,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3DEC1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.provinceFeaturedDishesTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.provinceFeaturedDishesSubtitle(province.name),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2DE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${dishes.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFFF8A00),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (legacyCodes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(theme, '', t.provinceAllFilter),
                ...legacyCodes.map(
                  (code) => _buildFilterChip(theme, code, _legacyLabel(code)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (snapshot.connectionState == ConnectionState.waiting)
            const Center(child: CircularProgressIndicator())
          else if (snapshot.hasError)
            Text(
              t.provinceDishLoadError,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFB91C1C),
              ),
            )
          else if (dishes.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _selectedLegacyFilter.isEmpty
                    ? t.provinceDishEmpty
                    : t.provinceLegacyDishEmpty(
                        _legacyLabel(_selectedLegacyFilter),
                      ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            )
          else
            _buildHorizontalDishList(theme, dishes.take(10).toList()),
          if (province.places.isNotEmpty) ...[
            const SizedBox(height: 22),
            _buildFamousPlacesSection(
              theme,
              province.places.take(10).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalDishList(ThemeData theme, List<DishModel> dishes) {
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dishes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildSmallDishCard(dishes[index], theme);
        },
      ),
    );
  }

  Widget _buildSmallDishCard(DishModel dish, ThemeData theme) {
    final imageUrl = dish.imageUrl.trim();
    final lang = Localizations.localeOf(context).languageCode;
    final dishName = dish.getName(lang).trim();
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DishDetailPage(dishId: dish.id),
          ),
        );
      },
      child: SizedBox(
        width: 124,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 124,
                height: 92,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildImagePlaceholder(Icons.restaurant_rounded),
                      )
                    : _buildImagePlaceholder(Icons.restaurant_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dishName.isNotEmpty ? dishName : dish.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: Color(0xFFFF8A00),
                ),
                const SizedBox(width: 3),
                Text(
                  '${dish.spicyLevel}/5',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamousPlacesSection(
    ThemeData theme,
    List<ProvincePlaceModel> places,
  ) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.provinceFamousPlacesTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF8A00),
                padding: EdgeInsets.zero,
              ),
              child: Text(t.homeBadgesSeeAll),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildPlaceCard(theme, places[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(ThemeData theme, ProvincePlaceModel place) {
    final imageUrl = place.imageUrl.trim();
    return SizedBox(
      width: 124,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 124,
              height: 92,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildImagePlaceholder(Icons.place_rounded),
                    )
                  : _buildImagePlaceholder(Icons.place_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            place.displayName('vi'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(IconData icon) {
    return Container(
      color: const Color(0xFFF6E9D9),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFFFF8A00), size: 28),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme,
    String code,
    String label,
  ) {
    final isActive = _selectedLegacyFilter == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLegacyFilter = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF8A00) : const Color(0xFFFFF7EC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? const Color(0xFFFF8A00) : const Color(0xFFF3DEC1),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isActive ? Colors.white : const Color(0xFF92400E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2DE),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFF3DEC1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFFF8A00)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(List<String> images, String name) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    if (images.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFF6E9D9),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_outlined,
              size: 38,
              color: Color(0xFFFF8A00),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) => _imageIndex.value = index,
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF6E9D9),
                    child: const Icon(Icons.image, size: 40),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.56),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t.provinceHeroBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: ValueListenableBuilder<int>(
                  valueListenable: _imageIndex,
                  builder: (context, value, _) {
                    return Center(child: _buildDots(images.length, value));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF8A00)),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(DishModel dish, ThemeData theme) {
    final imageUrl = dish.imageUrl;
    final lang = Localizations.localeOf(context).languageCode;
    final dishName = dish.getName(lang).trim();
    final category = dish.getCategory(lang).trim();
    final t = AppLocalizations.of(context)!;
    final legacyText = dish.effectiveLegacyProvinceName.trim().isEmpty
        ? dish.effectiveProvinceName
        : '${dish.effectiveLegacyProvinceName} c\u0169';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DishDetailPage(dishId: dish.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF3DEC1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 98,
                  height: 98,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF6E9D9),
                            child: const Icon(Icons.image_outlined),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF6E9D9),
                          child: const Icon(Icons.image_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2DE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        legacyText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFF8A00),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dishName.isNotEmpty ? dishName : dish.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.isEmpty ? t.dishSpecialtyFallback : category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: Color(0xFFFF8A00),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cay ${dish.spicyLevel}/5',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF374151),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
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

  Widget _buildDots(int count, int activeIndex) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF8A00) : Colors.white54,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
