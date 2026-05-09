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
    final q = _controller.text.trim();

    void exec() {
      setState(() {
        _dishFuture = _foodService.searchDishes(
          query: q,
          provinceCode: widget.args?.provinceCode,
        );
        _placeFuture = q.isEmpty
            ? Future.value(const <GoongNearbyPlace>[])
            : _placesService.searchText(
                query: q,
                limit: 20,
              ).then((items) {
                final lat = widget.args?.userLat;
                final lng = widget.args?.userLng;
                if (lat == null || lng == null) return items;
                return items
                  ..sort((a, b) {
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
      _debounce = Timer(const Duration(milliseconds: 400), exec);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provinceLabel = widget.args?.provinceName ?? '';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _controller,
            autofocus: (widget.args?.initialQuery ?? '').isEmpty,
            textInputAction: TextInputAction.search,
            onChanged: (_) => _runSearch(),
            onSubmitted: (_) => _runSearch(immediate: true),
            decoration: InputDecoration(
              hintText: 'Tim mon an, quan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _runSearch(immediate: true);
                },
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Mon an'),
            Tab(text: 'Quan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _DishResultList(future: _dishFuture, provinceLabel: provinceLabel),
          _PlaceResultList(
            future: _placeFuture,
            userLat: widget.args?.userLat,
            userLng: widget.args?.userLng,
          ),
        ],
      ),
    );
  }
}

class _DishResultList extends StatelessWidget {
  const _DishResultList({required this.future, required this.provinceLabel});

  final Future<List<DishModel>>? future;
  final String provinceLabel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DishModel>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data ?? const <DishModel>[];
        if (data.isEmpty) {
          return const Center(child: Text('Khong tim thay mon'));
        }
        return ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final d = data[i];
            return ListTile(
              leading: d.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        d.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.ramen_dining),
              title: Text(d.name),
              subtitle: Text(
                d.provinceName.isNotEmpty ? d.provinceName : provinceLabel,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DishDetailPage(dishId: d.id),
                  ),
                );
              },
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
  });

  final Future<List<GoongNearbyPlace>>? future;
  final double? userLat;
  final double? userLng;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GoongNearbyPlace>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data ?? const <GoongNearbyPlace>[];
        if (data.isEmpty) {
          return const Center(child: Text('Khong tim thay quan'));
        }
        return ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = data[i];
            final distance = (userLat != null && userLng != null)
                ? _distanceText(userLat!, userLng!, p)
                : '';
            return ListTile(
              leading: p.photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.photoUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.storefront),
              title: Text(p.name),
              subtitle: Text(
                [
                  p.address,
                  distance,
                ].where((e) => e.isNotEmpty).join(' • '),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FavoritePlaceDetailPage(place: p),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _distanceText(double lat, double lng, GoongNearbyPlace p) {
    final meters = Geolocator.distanceBetween(lat, lng, p.lat, p.lng);
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
