import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/dish_model.dart';
import '../../models/province_model.dart';
import '../../services/auth_service.dart';
import '../../services/food_service.dart';
import '../../services/user_service.dart';
import '../../router/route_names.dart';
import '../../controller/favorite/favorite_controller.dart';
import '../../widgets/favorite_button.dart';
import '../onboarding/survey_sheet.dart';
import '../favorites/favorites_tabs_page.dart';
import '../personal/personal.dart';
import '../map/map_page.dart';
import '../../services/location_preference_service.dart';
import '../../services/location_service.dart';
import '../../services/map/geocode_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _checkedSurvey = false;

  final List<Widget> _pages = const [
    _HomeFeed(),
    Center(child: Text('Kham pha')),
    MapPage(),
    FavoritesTabsPage(),
    PersonalPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowSurvey();
    });
  }

  Future<void> _maybeShowSurvey() async {
    if (_checkedSurvey) return;
    _checkedSurvey = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await UserService().getUserById(user.uid);
    if (!mounted) return;

    if (profile?.onboardingCompleted == true) return;

    await showSurveySheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    final showAppBar = _currentIndex != 4;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person) : null,
                ),
              ),
              title: const Text('FoodG Travel'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await AuthService().logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.login,
                      (_) => false,
                    );
                  },
                  tooltip: 'Logout',
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B0F1A),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFF8A8F9A),
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Kham pha',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Luu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Toi',
          ),
        ],
      ),
    );
  }
}

class _HomeFeed extends StatefulWidget {
  const _HomeFeed({super.key});

  @override
  State<_HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<_HomeFeed> {
  final _service = FoodService();
  final _pageController = PageController();
  final _searchController = TextEditingController();
  final _userService = UserService();
  StreamSubscription? _profileSub;
  Timer? _autoSlideTimer;
  final ValueNotifier<int> _imageIndex = ValueNotifier<int>(0);
  String? _lastProvinceId;
  Stream<List<DishModel>>? _dishesStream;

  final _locationPrefs = LocationPreferenceService();
  final _locationService = LocationService();
  final _geocodeService = GeocodeService();
  StreamSubscription<Position>? _gpsSub;
  Position? _gpsPosition;
  bool _gpsEnabled = false;
  bool _gpsResolving = false;
  String? _gpsProvinceName;
  String? _gpsProvinceCode;

  ProvinceModel? _selectedProvince;
  String _query = '';
  bool _selectionInitialized = false;
  String? _preferredProvinceCode;
  String? _preferredProvinceName;
  int _imageCount = 0;

  @override
  void initState() {
    super.initState();
    _startProfileListener();

    // Doc trang thai GPS da luu (bat/tat).
    _locationPrefs.load();
    _gpsEnabled = LocationPreferenceService.enabled.value;
    LocationPreferenceService.enabled.addListener(_onLocationPrefChanged);

    if (_gpsEnabled) {
      _resolveGpsProvince();
    }
  }

  @override
  void dispose() {
    LocationPreferenceService.enabled.removeListener(_onLocationPrefChanged);
    _stopGpsListener();
    _profileSub?.cancel();
    _autoSlideTimer?.cancel();
    _imageIndex.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startProfileListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    _profileSub?.cancel();
    _profileSub = _userService.watchUserById(user.uid).listen((profile) {
      final prefs = profile?.preferences;
      final nextCode = prefs?.provinceCode?.trim();
      final nextName = prefs?.provinceName?.trim();
      if (nextCode == _preferredProvinceCode &&
          nextName == _preferredProvinceName) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _preferredProvinceCode = nextCode;
        _preferredProvinceName = nextName;
        _selectionInitialized = false;
      });
    });
  }

  void _setProvince(ProvinceModel province) {
    if (_selectedProvince?.id == province.id) {
      return;
    }
    setState(() {
      _selectedProvince = province;
      _dishesStream =
          _service.watchDishesByProvinceKeys(_provinceQueryKeys(province));
    });
    _imageIndex.value = 0;
  }

  List<String> _provinceQueryKeys(ProvinceModel province) {
    return [
      province.code,
      province.name,
      province.id,
    ]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  String _slugify(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    final cleaned = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    return cleaned.split(RegExp(r'\s+')).join('_');
  }

  String _normalizeKey(String raw) {
    return raw.trim().toLowerCase().replaceAll('-', '_');
  }

  ProvinceModel? _findPreferredProvince(List<ProvinceModel> provinces) {
    // Neu co GPS va co vi tri, uu tien chon tinh gan nhat theo centerLat/centerLng.
    if (_gpsEnabled && _gpsPosition != null) {
      final nearest = _findNearestProvinceByGps(provinces, _gpsPosition!);
      if (nearest != null) {
        return nearest;
      }
    }

    // Uu tien GPS neu co du lieu tinh tu vi tri.
    final gpsHasValue = _gpsEnabled &&
        ((_gpsProvinceName?.trim().isNotEmpty ?? false) ||
            (_gpsProvinceCode?.trim().isNotEmpty ?? false));

    var prefCode =
        gpsHasValue ? _gpsProvinceCode?.trim() : _preferredProvinceCode?.trim();
    var prefName =
        gpsHasValue ? _gpsProvinceName?.trim() : _preferredProvinceName?.trim();

    // Neu khong co GPS va cung chua chon tinh trong khao sat -> default Ha Noi.
    if ((prefCode == null || prefCode.isEmpty) &&
        (prefName == null || prefName.isEmpty)) {
      prefName = 'Ha Noi';
    }

    if (prefCode != null && prefCode.isNotEmpty) {
      final normalizedPref = _normalizeKey(prefCode);
      for (final province in provinces) {
        final codeKey = _normalizeKey(province.code);
        final idKey = _normalizeKey(province.id);
        if (codeKey == normalizedPref || idKey == normalizedPref) {
          return province;
        }
      }
    }
    if (prefName != null && prefName.isNotEmpty) {
      final prefSlug = _slugify(prefName);
      for (final province in provinces) {
        if (province.name == prefName) {
          return province;
        }
        if (prefSlug.isNotEmpty) {
          final provinceSlug = _slugify(province.name);
          if (provinceSlug == prefSlug) {
            return province;
          }
          final codeKey = _normalizeKey(province.code);
          final idKey = _normalizeKey(province.id);
          if (codeKey == prefSlug || idKey == prefSlug) {
            return province;
          }
        }
      }
    }
    return null;
  }

  ProvinceModel? _findNearestProvinceByGps(
    List<ProvinceModel> provinces,
    Position position,
  ) {
    ProvinceModel? nearest;
    double? nearestDistance;
    for (final province in provinces) {
      final lat = province.centerLat;
      final lng = province.centerLng;
      if (lat == null || lng == null) continue;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      );
      if (nearestDistance == null || distance < nearestDistance) {
        nearestDistance = distance;
        nearest = province;
      }
    }
    return nearest;
  }

  void _startImageAutoSlide(int count) {
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
  // Xu ly khi nguoi dung bat/tat GPS trong cai dat.
  void _onLocationPrefChanged() {
    final enabled = LocationPreferenceService.enabled.value;
    if (enabled == _gpsEnabled) return;

    setState(() {
      _gpsEnabled = enabled;
      _selectionInitialized = false;
      if (!enabled) {
        _gpsPosition = null;
        _gpsProvinceName = null;
        _gpsProvinceCode = null;
      }
    });

    if (enabled) {
      _resolveGpsProvince();
    } else {
      _stopGpsListener();
    }
  }

  void _startGpsListener() {
    if (_gpsSub != null) return;
    // Lang nghe 1 vai cap nhat vi tri de lay tinh, sau do dung lai.
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 2000,
      ),
    ).listen((pos) async {
      final updated = await _updateGpsProvinceFromPosition(pos);
      if (updated) {
        await _gpsSub?.cancel();
        _gpsSub = null;
      }
    });
  }

  void _stopGpsListener() {
    _gpsSub?.cancel();
    _gpsSub = null;
  }

  Future<bool> _updateGpsProvinceFromPosition(Position pos) async {
    if (!_gpsEnabled) return false;
    // Luu vi tri GPS hien tai de map theo centerLat/centerLng.
    _gpsPosition = pos;
    // Reverse geocode de lay ten tinh.
    final rawName =
        await _geocodeService.reverseProvinceName(pos.latitude, pos.longitude);
    if (!mounted) return false;
    if (rawName == null || rawName.trim().isEmpty) {
      // Van se map theo khoang cach neu co centerLat/centerLng.
      setState(() {
        _selectionInitialized = false;
      });
      return true;
    }

    final cleaned = _cleanProvinceName(rawName);
    final nextCode = _slugify(cleaned);

    if (cleaned == _gpsProvinceName && nextCode == _gpsProvinceCode) {
      setState(() {
        _selectionInitialized = false;
      });
      return true;
    }

    setState(() {
      _gpsProvinceName = cleaned;
      _gpsProvinceCode = nextCode;
      _selectionInitialized = false; // bat buoc re-chon tinh tren Home
    });
    return true;
  }

  Future<void> _resolveGpsProvince() async {
    if (_gpsResolving) return;
    _gpsResolving = true;
    try {
      // Lay vi tri hien tai (uu tien last known de nhanh hon).
      final result = await _locationService.getCurrentLocation(
        accuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
        useLastKnown: true,
      );

      if (!result.isSuccess) {
        // Neu chua lay duoc vi tri, bat listener de cho vi tri on dinh.
        _startGpsListener();
        return;
      }

      final updated = await _updateGpsProvinceFromPosition(result.position!);
      if (!updated) {
        _startGpsListener();
      }
    } finally {
      _gpsResolving = false;
    }
  }

  String _cleanProvinceName(String name) {
    // Loai bo tien to de de so khop voi ten tinh trong DB.
    var result = name.trim();
    const prefixes = ['Tinh ', 'Thanh pho ', 'TP. ', 'TP '];
    for (final prefix in prefixes) {
      if (result.startsWith(prefix)) {
        result = result.substring(prefix.length);
        break;
      }
    }
    return result;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 720 ? 3 : 2;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchField(theme),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ProvinceModel>>(
          stream: _service.watchProvinces(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return _buildEmpty('Khong the tai danh sach tinh.');
            }

            final provinces = snapshot.data ?? [];
            if (provinces.isEmpty) {
              return _buildEmpty('Chua co tinh thanh.');
            }

            final selected = _selectedProvince;
            final selectedInList = selected != null &&
                provinces.any((p) => p.id == selected.id);
            if (!selectedInList) {
              _selectionInitialized = false;
            }

            final preferred = _findPreferredProvince(provinces);
            final target = (!_selectionInitialized && preferred != null)
                ? preferred
                : (selectedInList ? selected! : (preferred ?? provinces.first));

            if (!_selectionInitialized || !selectedInList) {
              _selectionInitialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _setProvince(target);
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
            }

            final images = target.imageUrls.isNotEmpty
                ? target.imageUrls
                : (target.imageUrl.isNotEmpty
                    ? [target.imageUrl]
                    : const <String>[]);

            if (_lastProvinceId != target.id) {
              _lastProvinceId = target.id;
              _imageIndex.value = 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                for (final url in images) {
                  precacheImage(NetworkImage(url), context);
                }
              });
            }

            _startImageAutoSlide(images.length);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tinh noi bat',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (images.isEmpty)
                  _buildEmpty('Tinh nay chua co anh.')
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 190,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => _imageIndex.value = index,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final imageUrl = images[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RouteNames.provinceDetail,
                                arguments: target.id,
                              );
                            },
                            child: _buildProvinceImageSlide(
                              imageUrl: imageUrl,
                              name: target.name,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (images.length > 1)
                  Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _imageIndex,
                      builder: (context, value, _) {
                        return _buildDots(images.length, value);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Dac san theo tinh',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedProvince == null)
          _buildEmpty('Chon tinh de xem mon an.'),
        if (_selectedProvince != null && _dishesStream != null)
          StreamBuilder<List<DishModel>>(
            stream: _dishesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return _buildEmpty('Khong the tai danh sach mon.');
              }

              final dishes = snapshot.data ?? [];
              final query = _query.toLowerCase();
              final filtered = query.isEmpty
                  ? dishes
                  : dishes.where((dish) {
                      final name = dish.name.toLowerCase();
                      final tag = dish.tag.toLowerCase();
                      return name.contains(query) || tag.contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return _buildEmpty('Khong tim thay mon an phu hop.');
              }

              return Consumer<FavoriteController>(
                builder: (context, favoriteController, _) {
                  final favoriteIds = favoriteController.favoriteIds;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        final dish = filtered[index];
                        final isFavorite = favoriteIds.contains(dish.id);
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.dishDetail,
                              arguments: dish.id,
                            );
                          },
                          child: _buildDishCard(
                            dish,
                            isFavorite: isFavorite,
                            onToggle: () =>
                                favoriteController.toggleFavorite(dish.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          hintText: 'Tim mon an, nguyen lieu...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildProvinceImageSlide({
    required String imageUrl,
    required String name,
  }) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceVariant,
              child: const Icon(Icons.image, size: 32),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(
    DishModel dish, {
    required bool isFavorite,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final imageUrl = dish.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: const Icon(Icons.image, size: 32),
                              );
                            },
                          )
                        : Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: const Icon(Icons.image, size: 32),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: onToggle,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                dish.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (dish.tag.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  dish.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dish.spicyLevel}/5',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(int count, int activeIndex) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary : theme.dividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Widget _buildEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).hintColor),
      ),
    );
  }
}
