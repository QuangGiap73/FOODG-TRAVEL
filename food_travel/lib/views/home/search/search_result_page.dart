import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/dish_model.dart';
import '../../../models/places_model.dart';
import '../../../services/food_service.dart';
import '../../../services/map/serpapi_places_service.dart';
import '../../dishes/dish_detail_page.dart';
import '../../favorites/place_detail_page.dart';

class SearchPageArgs {
  const SearchPageArgs({
    required this.initialQuery,
    this.provinceCode,
    this.provinceName,
    this.userLat,
    this.userLng,
  });

  final String initialQuery;
  final String? provinceCode;
  final String? provinceName;
  final double? userLat;
  final double? userLng;
}

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key, this.args});

  final SearchPageArgs? args;

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final TextEditingController _controller;
  final _foodService = FoodService();
  final _placesService = SerpApiPlacesService();

  Future<List<DishModel>>? _dishFuture;
  Future<List<GoongNearbyPlace>>? _placeFuture;
  Timer? _debounce;

  String get _query => _controller.text.trim();
  String get _provinceLabel => widget.args?.provinceName?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _controller = TextEditingController(text: widget.args?.initialQuery ?? '');
    _runSearch(immediate: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tab.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _runSearch({bool immediate = false}) {
    final q = _query;

    void exec() {
      setState(() {
        _dishFuture = _foodService.searchDishes(
          query: q,
          provinceCode: widget.args?.provinceCode,
        );
        _placeFuture =
            q.isEmpty
                ? Future.value(const <GoongNearbyPlace>[])
                : _placesService.searchText(query: q, limit: 20).then((items) {
                  final lat = widget.args?.userLat;
                  final lng = widget.args?.userLng;
                  if (lat == null || lng == null) return items;
                  return items..sort((a, b) {
                    final da = Geolocator.distanceBetween(
                      lat,
                      lng,
                      a.lat,
                      a.lng,
                    );
                    final db = Geolocator.distanceBetween(
                      lat,
                      lng,
                      b.lat,
                      b.lng,
                    );
                    return da.compareTo(db);
                  });
                });
      });
    }

    _debounce?.cancel();
    if (immediate) {
      exec();
    } else {
      _debounce = Timer(const Duration(milliseconds: 350), exec);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasContextHeader = _provinceLabel.isNotEmpty || _query.isNotEmpty;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E1116) : const Color(0xFFF8F5F1),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF0E1116) : const Color(0xFFF8F5F1),
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _SearchInput(
            controller: _controller,
            autofocus: (widget.args?.initialQuery ?? '').isEmpty,
            onChanged: (_) => _runSearch(),
            onSubmitted: (_) => _runSearch(immediate: true),
            onClear: () {
              _controller.clear();
              _runSearch(immediate: true);
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(hasContextHeader ? 92 : 56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasContextHeader)
                  _SearchContextHeader(
                    query: _query,
                    provinceLabel: _provinceLabel,
                  ),
                SizedBox(height: hasContextHeader ? 10 : 0),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF171B22) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFFF7A1A),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        isDark ? Colors.white70 : const Color(0xFF7A6F66),
                    tabs: const [Tab(text: 'Mon an'), Tab(text: 'Quan an')],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _DishResultList(
            future: _dishFuture,
            provinceLabel: _provinceLabel,
            query: _query,
          ),
          _PlaceResultList(
            future: _placeFuture,
            userLat: widget.args?.userLat,
            userLng: widget.args?.userLng,
            query: _query,
          ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.autofocus,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFFFD6B2),
        ),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: 'Tim mon an, nguyen lieu, quan ngon...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF9A8F86),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFFF7A1A),
          ),
          suffixIcon:
              controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onClear,
                  ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _SearchContextHeader extends StatelessWidget {
  const _SearchContextHeader({
    required this.query,
    required this.provinceLabel,
  });

  final String query;
  final String provinceLabel;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (query.isNotEmpty) {
      chips.add(_InfoChip(icon: Icons.restaurant_menu_rounded, label: query));
    }
    if (provinceLabel.isNotEmpty) {
      chips.add(
        _InfoChip(icon: Icons.location_on_outlined, label: provinceLabel),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF2A303A) : const Color(0xFFFFE2C7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFFF7A1A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DishResultList extends StatelessWidget {
  const _DishResultList({
    required this.future,
    required this.provinceLabel,
    required this.query,
  });

  final Future<List<DishModel>>? future;
  final String provinceLabel;
  final String query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DishModel>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const _EmptySearchState(
            icon: Icons.error_outline_rounded,
            title: 'Khong the tim mon an',
            subtitle: 'Du lieu tim kiem dang gap loi. Thu lai sau.',
          );
        }
        final data = snap.data ?? const <DishModel>[];
        if (data.isEmpty) {
          return _EmptySearchState(
            icon: Icons.ramen_dining_outlined,
            title: 'Chua tim thay mon phu hop',
            subtitle:
                query.isEmpty
                    ? 'Nhap ten mon, nguyen lieu hoac dac san de bat dau tim.'
                    : 'Thu doi tu khoa ngan hon hoac tim theo tinh thanh khac.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: data.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ResultSectionHeader(
                title: '${data.length} mon an phu hop',
                subtitle:
                    provinceLabel.isNotEmpty
                        ? 'Uu tien dac san tai $provinceLabel'
                        : 'Ket qua duoc sap xep theo do lien quan',
              );
            }

            final dish = data[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DishSearchCard(
                dish: dish,
                fallbackProvinceLabel: provinceLabel,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DishDetailPage(dishId: dish.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _PlaceResultList extends StatelessWidget {
  const _PlaceResultList({
    required this.future,
    required this.userLat,
    required this.userLng,
    required this.query,
  });

  final Future<List<GoongNearbyPlace>>? future;
  final double? userLat;
  final double? userLng;
  final String query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GoongNearbyPlace>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const _EmptySearchState(
            icon: Icons.store_mall_directory_outlined,
            title: 'Khong the tim quan an',
            subtitle: 'Dich vu tim dia diem dang tam thoi gian doan.',
          );
        }
        final data = snap.data ?? const <GoongNearbyPlace>[];
        if (data.isEmpty) {
          return _EmptySearchState(
            icon: Icons.storefront_outlined,
            title: 'Khong tim thay quan an',
            subtitle:
                query.isEmpty
                    ? 'Nhap ten quan hoac khu vuc de hien thi ket qua.'
                    : 'Thu them ten duong, khu vuc hoac mot tu khoa cu the hon.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: data.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ResultSectionHeader(
                title: '${data.length} quan an lien quan',
                subtitle:
                    userLat != null && userLng != null
                        ? 'Da uu tien sap xep theo khoang cach gan ban'
                        : 'Ket qua dia diem phu hop voi tu khoa cua ban',
              );
            }

            final place = data[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PlaceSearchCard(
                place: place,
                distanceText:
                    (userLat != null && userLng != null)
                        ? _distanceText(userLat!, userLng!, place)
                        : '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritePlaceDetailPage(place: place),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _distanceText(double lat, double lng, GoongNearbyPlace p) {
    final meters = Geolocator.distanceBetween(lat, lng, p.lat, p.lng);
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _ResultSectionHeader extends StatelessWidget {
  const _ResultSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishSearchCard extends StatelessWidget {
  const _DishSearchCard({
    required this.dish,
    required this.fallbackProvinceLabel,
    required this.onTap,
  });

  final DishModel dish;
  final String fallbackProvinceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;
    final province =
        dish.effectiveProvinceName.isNotEmpty
            ? dish.effectiveProvinceName
            : fallbackProvinceLabel;
    final category = dish.getCategory(lang);
    final ingredients = dish.getIngredients(lang);
    final summary =
        ingredients.isNotEmpty ? ingredients : dish.getDescription(lang);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171B22) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF2A303A) : const Color(0xFFFFD8B7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardImage(
                  imageUrl: dish.imageUrl,
                  icon: Icons.ramen_dining_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (province.isNotEmpty)
                            _Badge(
                              label: province,
                              icon: Icons.location_on_outlined,
                            ),
                          if (category.isNotEmpty)
                            _Badge(
                              label: category,
                              icon: Icons.local_dining_outlined,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dish.getName(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (summary.isNotEmpty)
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.45,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.74,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: Color(0xFFFF7A1A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cay ${dish.spicyLevel}/5',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Color(0xFFFF7A1A),
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
      ),
    );
  }
}

class _PlaceSearchCard extends StatelessWidget {
  const _PlaceSearchCard({
    required this.place,
    required this.distanceText,
    required this.onTap,
  });

  final GoongNearbyPlace place;
  final String distanceText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meta = <Widget>[];

    if ((place.category ?? '').trim().isNotEmpty) {
      meta.add(
        _Badge(label: place.category!.trim(), icon: Icons.storefront_outlined),
      );
    }
    if (distanceText.isNotEmpty) {
      meta.add(_Badge(label: distanceText, icon: Icons.near_me_outlined));
    }
    if (place.rating != null) {
      meta.add(
        _Badge(
          label: place.rating!.toStringAsFixed(1),
          icon: Icons.star_rounded,
        ),
      );
    }

    final openLabel =
        place.isOpen == null
            ? ''
            : (place.isOpen! ? 'Dang mo cua' : 'Tam dong');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171B22) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF2A303A) : const Color(0xFFFFD8B7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardImage(
                  imageUrl: place.photoUrl,
                  icon: Icons.storefront_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (meta.isNotEmpty)
                        Wrap(spacing: 8, runSpacing: 8, children: meta),
                      if (meta.isNotEmpty) const SizedBox(height: 10),
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (openLabel.isNotEmpty)
                            Expanded(
                              child: Text(
                                openLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color:
                                      place.isOpen == true
                                          ? const Color(0xFF1D9D57)
                                          : const Color(0xFFC75A2C),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Color(0xFFFF7A1A),
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
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.imageUrl, required this.icon});

  final String imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 104,
        height: 104,
        child:
            imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(theme),
                )
                : _fallback(theme),
      ),
    );
  }

  Widget _fallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      child: Icon(icon, size: 34, color: const Color(0xFFFF7A1A)),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202733) : const Color(0xFFFFF1E4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFFF7A1A)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171B22) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2A303A) : const Color(0xFFFFE2C7),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: const Color(0xFFFF7A1A)),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.74,
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
