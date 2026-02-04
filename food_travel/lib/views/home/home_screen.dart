import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/dish_model.dart';
import '../../models/province_model.dart';
import '../../services/food_service.dart';
import '../../services/user_service.dart';
import '../../router/route_names.dart';
import '../../controller/favorite/favorite_controller.dart';
import '../../controller/home/nearby_home_controlled.dart';
import '../../widgets/favorite_button.dart';
import '../onboarding/survey_sheet.dart';
import '../favorites/favorites_tabs_page.dart';
import '../personal/personal.dart';
import '../map/map_page.dart';
import '../../services/location_preference_service.dart';
import '../../services/location_service.dart';
import '../../services/map/geocode_service.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/nearby_places_section.dart';
import 'widgets/today_eat_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _checkedSurvey = false;
  // Ten tinh dang hien thi tren app bar (duoc HomeFeed cap nhat theo GPS/khao sat).
  String _appBarProvinceText = 'Ban o dau?';
  // Callback de app bar goi mo danh sach tinh trong HomeFeed.
  VoidCallback? _openProvincePickerFromHome;

  List<Widget> _buildPages() {
    return [
      _HomeFeed(
        onProvinceLabelChanged: (value) {
          if (!mounted || value == _appBarProvinceText) return;
          // Tranh setState trung luc cay widget dang build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || value == _appBarProvinceText) return;
            setState(() => _appBarProvinceText = value);
          });
        },
        onProvincePickerReady: (callback) {
          _openProvincePickerFromHome = callback;
        },
      ),
      const Center(child: Text('Kham pha')),
      const MapPage(),
      const FavoritesTabsPage(),
      const PersonalPage(),
    ];
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Neu da xac dinh duoc tinh thi dong tren doi thanh 'Dang o'.
    final hasProvince =
        _appBarProvinceText.trim().isNotEmpty &&
        _appBarProvinceText.trim().toLowerCase() != 'ban o dau?';
    final topLocationText = hasProvince ? 'Dang o' : 'Ban dang o dau?';

    // An AppBar o tab "Luu" va "Toi"
    final showAppBar = _currentIndex != 4 && _currentIndex != 3;
    return Scaffold(
      appBar:
          showAppBar
              ? AppBar(
                toolbarHeight: 72,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor:
                    isDark ? const Color(0xFF0F131A) : Colors.white,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person) : null,
                  ),
                ),
                titleSpacing: 0,
                centerTitle: true,
                title: Align(
                  alignment: Alignment.center,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (_currentIndex != 0) {
                        setState(() => _currentIndex = 0);
                        return;
                      }
                      // Mo danh sach tinh ngay tren app bar (chi khi dang o Home).
                      _openProvincePickerFromHome?.call();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topLocationText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? Colors.white54
                                      : const Color(0xFF98A2B3),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Color(0xFFFF6A00),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _appBarProvinceText,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF6A00),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color:
                                    isDark
                                        ? Colors.white54
                                        : const Color(0xFF98A2B3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () {},
                    tooltip: 'Thong bao',
                    visualDensity: VisualDensity.compact,
                  ),
                  // IconButton(
                  //   icon: const Icon(Icons.favorite_border_rounded),
                  //   onPressed: () => setState(() => _currentIndex = 3),
                  //   tooltip: 'Yeu thich',
                  //   visualDensity: VisualDensity.compact,
                  // ),
                  const SizedBox(width: 6),
                ],
              )
              : null,
      body: IndexedStack(index: _currentIndex, children: _buildPages()),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _HomeFeed extends StatefulWidget {
  const _HomeFeed({
    super.key,
    required this.onProvinceLabelChanged,
    required this.onProvincePickerReady,
  });

  // HomeFeed gui ten tinh hien tai cho app bar o HomeScreen.
  final ValueChanged<String> onProvinceLabelChanged;
  // HomeFeed gui callback de app bar mo bottom sheet chon tinh.
  final ValueChanged<VoidCallback?> onProvincePickerReady;

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
  // Controller rieng cho section "Quan ngon gan ban" tren Home.
  late final NearbyHomeController _nearbyHomeController;
  StreamSubscription<Position>? _gpsSub;
  Position? _gpsPosition;
  bool _gpsEnabled = false;
  bool _gpsResolving = false;
  String? _gpsProvinceName;
  String? _gpsProvinceCode;
  // Tinh user chon tay o app bar (chi ton tai trong session).
  String? _manualProvinceName;
  String? _manualProvinceCode;

  ProvinceModel? _selectedProvince;
  String _query = '';
  bool _selectionInitialized = false;
  String? _preferredProvinceCode;
  String? _preferredProvinceName;
  int _imageCount = 0;
  // Cache danh sach tinh de mo picker tu app bar.
  List<ProvinceModel> _cachedProvinces = const [];

  @override
  void initState() {
    super.initState();
    // Tai san du lieu quan gan day ngay khi vao Home.
    _nearbyHomeController = NearbyHomeController()..load();
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
    // Huy callback o HomeScreen de tranh goi vao state da dispose.
    widget.onProvincePickerReady(null);
    LocationPreferenceService.enabled.removeListener(_onLocationPrefChanged);
    _stopGpsListener();
    _profileSub?.cancel();
    _autoSlideTimer?.cancel();
    _imageIndex.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _nearbyHomeController.dispose();
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
      // Neu chua co GPS va chua chon tay, hien tam ten tinh tu khao sat len app bar.
      if ((_manualProvinceName == null || _manualProvinceName!.isEmpty) &&
          (_gpsProvinceName == null || _gpsProvinceName!.isEmpty) &&
          (nextName != null && nextName.isNotEmpty)) {
        widget.onProvinceLabelChanged(nextName);
      }
    });
  }

  void _setProvince(ProvinceModel province) {
    if (_selectedProvince?.id == province.id) {
      return;
    }
    setState(() {
      _selectedProvince = province;
      _dishesStream = _service.watchDishesByProvinceKeys(
        _provinceQueryKeys(province),
      );
    });
    _imageIndex.value = 0;
  }

  List<String> _provinceQueryKeys(ProvinceModel province) {
    return [province.code, province.name, province.id]
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
    // 0) Neu user chon tay o app bar thi uu tien trong session hien tai.
    final manualCode = _manualProvinceCode?.trim();
    final manualName = _manualProvinceName?.trim();
    if ((manualCode?.isNotEmpty ?? false) ||
        (manualName?.isNotEmpty ?? false)) {
      if (manualCode != null && manualCode.isNotEmpty) {
        final normalizedManual = _normalizeKey(manualCode);
        for (final province in provinces) {
          final codeKey = _normalizeKey(province.code);
          final idKey = _normalizeKey(province.id);
          if (codeKey == normalizedManual || idKey == normalizedManual) {
            return province;
          }
        }
      }
      if (manualName != null && manualName.isNotEmpty) {
        final manualSlug = _slugify(manualName);
        for (final province in provinces) {
          if (province.name == manualName) {
            return province;
          }
          if (manualSlug.isNotEmpty && _slugify(province.name) == manualSlug) {
            return province;
          }
        }
      }
    }

    // Neu co GPS va co vi tri, uu tien chon tinh gan nhat theo centerLat/centerLng.
    if (_gpsEnabled && _gpsPosition != null) {
      final nearest = _findNearestProvinceByGps(provinces, _gpsPosition!);
      if (nearest != null) {
        return nearest;
      }
    }

    // Uu tien GPS neu co du lieu tinh tu vi tri.
    final gpsHasValue =
        _gpsEnabled &&
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
    final rawName = await _geocodeService.reverseProvinceName(
      pos.latitude,
      pos.longitude,
    );
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
    // Co GPS thi uu tien hien ten tinh GPS len app bar.
    widget.onProvinceLabelChanged(cleaned);
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

  Future<void> _openProvincePicker() async {
    if (_cachedProvinces.isEmpty) return;

    String query = '';
    final picked = await showModalBottomSheet<ProvinceModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF10141B) : Colors.white;
        final border =
            isDark ? const Color(0xFF27303B) : const Color(0xFFE5E7EB);
        final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
        final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final q = query.trim().toLowerCase();
            final filtered =
                q.isEmpty
                    ? _cachedProvinces
                    : _cachedProvinces.where((p) {
                      final name = p.name.toLowerCase();
                      final code = p.code.toLowerCase();
                      return name.contains(q) || code.contains(q);
                    }).toList();

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.78,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: textSecondary.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Chon tinh thanh',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // O tim kiem nhanh theo ten hoac ma tinh.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF171D27)
                                : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setSheetState(() => query = value);
                        },
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.search,
                            color: textSecondary,
                            size: 20,
                          ),
                          hintText: 'Tim tinh... (VD: Ha Noi, DN, ...)',
                          hintStyle: TextStyle(color: textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child:
                          filtered.isEmpty
                              ? Center(
                                child: Text(
                                  'Khong tim thay tinh phu hop.',
                                  style: TextStyle(color: textSecondary),
                                ),
                              )
                              : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final p = filtered[i];
                                  final isSelected =
                                      _selectedProvince?.id == p.id;
                                  return InkWell(
                                    onTap: () => Navigator.pop(ctx, p),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color:
                                            isSelected
                                                ? const Color(0xFFFFF3E8)
                                                : (isDark
                                                    ? const Color(0xFF171D27)
                                                    : const Color(0xFFFCFCFD)),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? const Color(0xFFFFC999)
                                                  : border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 18,
                                            color: Color(0xFFFF6A00),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.name,
                                                  style: TextStyle(
                                                    color: textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  p.code,
                                                  style: TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF6A00),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'Dang chon',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          else
                                            Icon(
                                              Icons.chevron_right,
                                              color: textSecondary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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

    if (picked == null || !mounted) return;
    setState(() {
      // Luu lua chon tay cho session hien tai.
      _manualProvinceCode = picked.code.trim();
      _manualProvinceName = picked.name.trim();
      _selectionInitialized = false;
    });
    _setProvince(picked);
    widget.onProvinceLabelChanged(picked.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 720 ? 3 : 2;
    // Tu dong lay thang hien tai de hien thi tieu de theo lich.
    final now = DateTime.now();
    final monthlyDestinationTitle = 'Diem den thang ${now.month}';

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchField(theme),
        ),
        const SizedBox(height: 16),
        if (_selectedProvince != null && _dishesStream != null)
          StreamBuilder<List<DishModel>>(
            stream: _dishesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasError) {
                return _buildEmpty('Khong the tai mon goi y hom nay.');
              }

              final dishes = snapshot.data ?? [];
              final filtered = _filterDishes(dishes);
              if (filtered.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Muc goi y 3 mon dat ngay duoi thanh tim kiem.
                    TodayEatSection(
                      dishes: dishes,
                      provinceSeed: _selectedProvince?.id ?? '',
                      onTapDish: (dish) {
                        Navigator.pushNamed(
                          context,
                          RouteNames.dishDetail,
                          arguments: dish.id,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: NearbyPlacesSection(
            controller: _nearbyHomeController,
            onTapMap: () {
              // Mo Map va truyen san danh sach de hien thi nhanh hon.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MapPage(
                        initialNearbyPlaces: _nearbyHomeController.places,
                        initialNearbyQuery: 'quan an',
                      ),
                ),
              );
            },
            onTapPlace: (place) {
              // Mo Map va focus diem quan nguoi dung vua chon.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MapPage(
                        initialNearbyPlaces: _nearbyHomeController.places,
                        initialPlace: place,
                      ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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
              // Khong co du lieu tinh -> app bar hien placeholder.
              widget.onProvinceLabelChanged('Ban o dau?');
              widget.onProvincePickerReady(null);
              return _buildEmpty('Chua co tinh thanh.');
            }

            // Cache list tinh hien tai de mo picker tu app bar.
            _cachedProvinces = provinces;
            widget.onProvincePickerReady(_openProvincePicker);

            final selected = _selectedProvince;
            final selectedInList =
                selected != null && provinces.any((p) => p.id == selected.id);
            if (!selectedInList) {
              _selectionInitialized = false;
            }

            final preferred = _findPreferredProvince(provinces);
            final selectedProvince = selectedInList ? selected : null;
            final target =
                (!_selectionInitialized && preferred != null)
                    ? preferred
                    : (selectedProvince ?? preferred ?? provinces.first);

            // Luon cap nhat label app bar theo tinh dang su dung.
            widget.onProvinceLabelChanged(target.name);

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

            final images =
                target.imageUrls.isNotEmpty
                    ? target.imageUrls
                    : (target.imageUrl.isNotEmpty
                        ? [target.imageUrl]
                        : const <String>[]);

            if (_lastProvinceId != target.id) {
              _lastProvinceId = target.id;
              // Dong bo ten tinh len app bar.
              widget.onProvinceLabelChanged(target.name);
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      monthlyDestinationTitle,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
        if (_selectedProvince == null) _buildEmpty('Chon tinh de xem mon an.'),
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
              final filtered = _filterDishes(dishes);

              if (filtered.isEmpty) {
                return _buildEmpty('Khong tim thay mon an phu hop.');
              }

              return Consumer<FavoriteController>(
                builder: (context, favoriteController, _) {
                  final favoriteIds = favoriteController.favoriteIds;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Dac san theo tinh',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            // Card nho gon hon de hien thi duoc nhieu item tren man hinh.
                            childAspectRatio: 0.92,
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
                                onToggle:
                                    () => favoriteController.toggleFavorite(
                                      dish.id,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  List<DishModel> _filterDishes(List<DishModel> dishes) {
    final query = _query.toLowerCase();
    if (query.isEmpty) {
      return dishes;
    }
    return dishes.where((dish) {
      final name = dish.name.toLowerCase();
      final tag = dish.tag.toLowerCase();
      return name.contains(query) || tag.contains(query);
    }).toList();
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
            errorBuilder:
                (_, __, ___) => Container(
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
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = dish.imageUrl;

    // Mau vien cam theo yeu cau, nhat hon o light mode de nhin "sach".
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
            color: const Color(0xFFFF6A00).withOpacity(isDark ? 0.16 : 0.12),
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
              // Giam chieu cao anh de card gon lai.
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                        imageUrl.isNotEmpty
                            ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  child: const Icon(Icons.image, size: 24),
                                );
                              },
                            )
                            : Container(
                              color: theme.colorScheme.surfaceVariant,
                              child: const Icon(Icons.image, size: 24),
                            ),
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
                dish.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            if (dish.tag.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  dish.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subColor,
                    fontSize: 11,
                  ),
                ),
              ),
            const Spacer(),
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
      child: Text(text, style: TextStyle(color: Theme.of(context).hintColor)),
    );
  }
}
