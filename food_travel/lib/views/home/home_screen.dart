import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../models/dish_model.dart';
import '../../models/province_model.dart';
import '../../models/user_model.dart';
import '../../models/user_preferences.dart';
import '../../services/dish_recommendation_service.dart';
import '../../services/food_service.dart';
import '../../services/user_service.dart';
import '../../router/route_names.dart';
import '../../controller/home/nearby_home_controlled.dart';
import '../onboarding/survey_page.dart';
import '../community/community_feed_page.dart';
import '../favorites/favorites_tabs_page.dart';
import '../journey/pages/food_journey_page.dart';
import '../personal/personal.dart';
import '../map/map_page.dart';
import '../../services/location_preference_service.dart';
import '../../services/location_service.dart';
import '../../services/location_repository.dart';
import '../../services/map/geocode_service.dart';
import '../../services/notifications/notification_service.dart';
import '../favorites/place_detail_page.dart';
import 'search/search_result_page.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_dish_section.dart';
import 'widgets/home_journey_section.dart';
import 'widgets/nearby_places_section.dart';
import 'widgets/today_eat_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.allowInitialSurvey = true,
    this.onStartupReady,
  });

  final bool allowInitialSurvey;
  final VoidCallback? onStartupReady;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _checkedSurvey = false;
  late final List<Widget?> _pages;
  final ValueNotifier<bool> _homeTabActive = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _mapTabActive = ValueNotifier<bool>(false);
  // Ten tinh dang hien thi tren app bar (duoc HomeFeed cap nhat theo GPS/khao sat).
  String _appBarProvinceText = '';
  // Callback de app bar goi mo danh sach tinh trong HomeFeed.
  VoidCallback? _openProvincePickerFromHome;

  Widget _createPage(int index) {
    switch (index) {
      case 0:
        return _HomeFeed(
          isActive: _homeTabActive,
          onStartupReady: widget.onStartupReady,
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
        );
      case 1:
        return const CommunityFeedPage();
      case 2:
        return MapPage(isActive: _mapTabActive);
      case 3:
        return const FoodJourneyPage(showBackButton: false);
      case 4:
        return const PersonalPage();
      default:
        return const SizedBox.shrink();
    }
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    // Notify Home before IndexedStack makes it offstage so active PageView
    // animations can be stopped while their Material ancestor is still active.
    _homeTabActive.value = index == 0;
    _mapTabActive.value = index == 2;
    setState(() {
      _pages[index] ??= _createPage(index);
      _currentIndex = index;
    });
  }

  Widget _buildNotificationBell(AppLocalizations t) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_none_rounded),
        onPressed: () {
          Navigator.pushNamed(context, RouteNames.notifications);
        },
        tooltip: t.notificationsTitle,
        visualDensity: VisualDensity.compact,
      );
    }

    return StreamBuilder<int>(
      stream: NotificationService().watchUnreadCount(uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.notifications);
              },
              tooltip: count > 0
                  ? '${t.notificationsTitle} ($count)'
                  : t.notificationsTitle,
              visualDensity: VisualDensity.compact,
            ),
            if (count > 0)
              Positioned(
                right: 1,
                top: 1,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(5, null);
    _pages[0] = _createPage(0);
    if (widget.allowInitialSurvey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowSurvey();
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.allowInitialSurvey && widget.allowInitialSurvey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowSurvey();
      });
    }
  }

  Future<void> _maybeShowSurvey() async {
    if (_checkedSurvey) return;
    _checkedSurvey = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    UserModel? profile;
    try {
      profile = await UserService().getUserById(user.uid);
    } catch (error) {
      debugPrint('Không kiểm tra được trạng thái khảo sát: $error');
    }
    if (!mounted) return;

    if (profile?.onboardingCompleted == true) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const SurveyPage(requiredCompletion: true),
      ),
    );
  }

  @override
  void dispose() {
    _homeTabActive.dispose();
    _mapTabActive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Neu da xac dinh duoc tinh thi dong tren doi thanh 'Dang o'.
    final hasProvince = _appBarProvinceText.trim().isNotEmpty;
    final topLocationText =
        hasProvince ? t.homeLocationLabel : t.homeLocationPrompt;
    final provinceText =
        hasProvince ? _appBarProvinceText : t.homeProvinceUnknown;

    // An AppBar o tab "Luu" va "Toi"
    final showAppBar =
        _currentIndex != 4 && _currentIndex != 3 && _currentIndex != 1;
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
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _selectTab(4),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child:
                            photoUrl == null ? const Icon(Icons.person) : null,
                      ),
                    ),
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
                        _selectTab(0);
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            topLocationText,
                            textAlign: TextAlign.center,
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
                                provinceText,
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
                  _buildNotificationBell(t),
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
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(
          _pages.length,
          (index) => _pages[index] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentIndex,
        onChanged: _selectTab,
      ),
    );
  }
}

class _HomeFeed extends StatefulWidget {
  const _HomeFeed({
    super.key,
    required this.isActive,
    this.onStartupReady,
    required this.onProvinceLabelChanged,
    required this.onProvincePickerReady,
  });

  final ValueListenable<bool> isActive;
  final VoidCallback? onStartupReady;
  // HomeFeed gui ten tinh hien tai cho app bar o HomeScreen.
  final ValueChanged<String> onProvinceLabelChanged;
  // HomeFeed gui callback de app bar mo bottom sheet chon tinh.
  final ValueChanged<VoidCallback?> onProvincePickerReady;

  @override
  State<_HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<_HomeFeed> {
  final _service = FoodService();
  final _recommendationService = const DishRecommendationService();
  final _pageController = PageController();
  final _promoBannerController = PageController(viewportFraction: 1);
  final _searchController = TextEditingController();
  final _userService = UserService();
  StreamSubscription? _profileSub;
  StreamSubscription<List<ProvinceModel>>? _provincesSub;
  StreamSubscription<List<DishModel>>? _dishesSub;
  Timer? _autoSlideTimer;
  Timer? _promoBannerTimer;
  Timer? _provinceLoadTimer;
  final ValueNotifier<int> _imageIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> _promoBannerIndex = ValueNotifier<int>(0);
  String? _lastProvinceId;
  List<DishModel> _dishesCache = const [];
  String? _dishesCacheProvinceId;
  List<DishModel> _provinceDishes = const [];
  Stream<List<DishModel>>? _dishesStream;
  Object? _dishesError;
  String? _activeDishQueryKey;
  List<ProvinceModel> _provinces = const [];
  bool _provincesLoading = true;
  Object? _provincesError;

  final _locationPrefs = LocationPreferenceService();
  final _locationService = LocationService();
  final _locationRepository = LocationRepository.instance;
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
  List<DishModel> _todayDishesCache = const <DishModel>[];
  List<RecommendedDish> _recommendationCache = const <RecommendedDish>[];
  List<DishModel>? _recommendationCacheSource;
  String? _recommendationCachePreferencesKey;
  String? _recommendationCacheProvinceId;
  String? _recommendationCacheLanguage;
  String? _recommendationCacheTimeBucket;
  bool _bootResolved = false;
  String? _bootTargetProvinceId;
  Timer? _bootTimer;
  bool _startupReported = false;
  bool _receivedDishResult = false;
  bool _selectionInitialized = false;
  String? _preferredProvinceCode;
  String? _preferredProvinceName;
  UserPreferences? _userPreferences;
  int _imageCount = 0;
  // Cache danh sach tinh de mo picker tu app bar.
  List<ProvinceModel> _cachedProvinces = const [];
  static const List<String> _promoBanners = [
    'assets/home/banner_1.png',
    'assets/home/banner_2.png',
    'assets/home/banner_3.png',
    'assets/home/banner_4.png',
    'assets/home/banner_5.png',
    'assets/home/banner_6.png',
  ];

  @override
  void initState() {
    super.initState();
    widget.isActive.addListener(_onHomeTabVisibilityChanged);
    // Tai san du lieu quan gan day ngay khi vao Home.
    _nearbyHomeController =
        NearbyHomeController()
          ..addListener(_checkStartupReady)
          ..load();
    _startProvinceListener();
    _startProfileListener();
    _bootTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _bootResolved = true;
      });
      _checkStartupReady();
    });
    // Không để splash bị kẹt nếu GPS hoặc một nguồn mạng gặp sự cố.
    Timer(const Duration(seconds: 10), _reportStartupReady);

    // Doc trang thai GPS da luu (bat/tat).
    _locationPrefs.load();
    _gpsEnabled = LocationPreferenceService.enabled.value;
    LocationPreferenceService.enabled.addListener(_onLocationPrefChanged);
    _locationRepository.addListener(_onSharedLocationChanged);

    if (_gpsEnabled) {
      _resolveGpsProvince();
    }

    _startPromoBannerAutoSlide();
  }

  @override
  void dispose() {
    // Huy callback o HomeScreen de tranh goi vao state da dispose.
    widget.isActive.removeListener(_onHomeTabVisibilityChanged);
    widget.onProvincePickerReady(null);
    LocationPreferenceService.enabled.removeListener(_onLocationPrefChanged);
    _locationRepository.removeListener(_onSharedLocationChanged);
    _stopGpsListener();
    _profileSub?.cancel();
    _provincesSub?.cancel();
    _dishesSub?.cancel();
    _autoSlideTimer?.cancel();
    _promoBannerTimer?.cancel();
    _provinceLoadTimer?.cancel();
    _bootTimer?.cancel();
    _imageIndex.dispose();
    _promoBannerIndex.dispose();
    _pageController.dispose();
    _promoBannerController.dispose();
    _searchController.dispose();
    _nearbyHomeController
      ..removeListener(_checkStartupReady)
      ..dispose();
    super.dispose();
  }

  void _onHomeTabVisibilityChanged() {
    if (widget.isActive.value) {
      _applySharedLocation(refreshNearby: true);
      return;
    }
    _stopPageAnimation(_pageController, _imageIndex.value);
    _stopPageAnimation(_promoBannerController, _promoBannerIndex.value);
  }

  void _onSharedLocationChanged() {
    if (!mounted || !widget.isActive.value) return;
    _applySharedLocation(refreshNearby: true);
  }

  void _applySharedLocation({required bool refreshNearby}) {
    final position = _locationRepository.position;
    if (position == null) return;

    final previous = _gpsPosition;
    final changed =
        previous == null ||
        previous.latitude != position.latitude ||
        previous.longitude != position.longitude;
    if (!changed) return;

    _updateGpsProvinceFromPosition(position);
    if (refreshNearby) {
      _nearbyHomeController.load(force: true);
    }
  }

  void _stopPageAnimation(PageController controller, int fallbackPage) {
    if (!controller.hasClients ||
        !controller.position.isScrollingNotifier.value) {
      return;
    }
    final currentPage = (controller.page ?? fallbackPage.toDouble()).round();
    controller.jumpToPage(currentPage);
  }

  void _startPromoBannerAutoSlide() {
    _promoBannerTimer?.cancel();
    if (_promoBanners.length < 2) return;

    _promoBannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted ||
          !widget.isActive.value ||
          ModalRoute.of(context)?.isCurrent != true ||
          !_promoBannerController.hasClients ||
          _promoBannerController.position.isScrollingNotifier.value) {
        return;
      }
      final current =
          _promoBannerController.page?.round() ?? _promoBannerIndex.value;
      final next = (current + 1) % _promoBanners.length;
      _promoBannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _startProvinceListener() {
    _provincesSub?.cancel();
    _provinceLoadTimer?.cancel();
    _provincesLoading = true;
    _provincesError = null;
    _provinceLoadTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _provinces.isNotEmpty || !_provincesLoading) return;
      debugPrint('[Home] provinces load timeout');
      setState(() {
        _provincesLoading = false;
        _provincesError = TimeoutException('Province load timeout');
      });
    });
    _provincesSub = _service.watchProvinces().listen(
      (provinces) {
        if (!mounted) return;
        _provinceLoadTimer?.cancel();
        setState(() {
          _provinces = provinces;
          _cachedProvinces = provinces;
          _provincesLoading = false;
          _provincesError = null;
        });
        _checkStartupReady();
      },
      onError: (error) {
        _provinceLoadTimer?.cancel();
        debugPrint('[Home] provinces load failed: $error');
        if (!mounted) return;
        setState(() {
          _provincesLoading = false;
          _provincesError = error;
        });
        _checkStartupReady();
      },
    );
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
      if (!mounted) return;
      final provinceChanged =
          nextCode != _preferredProvinceCode ||
          nextName != _preferredProvinceName;
      setState(() {
        _preferredProvinceCode = nextCode;
        _preferredProvinceName = nextName;
        _userPreferences = prefs;
        if (provinceChanged) {
          _selectionInitialized = false;
        }
      });
    });
  }

  void _setProvince(ProvinceModel province) {
    final keys = _provinceQueryKeys(province);
    final normalizedKeys = keys.map(_normalizeKey).toSet().toList()..sort();
    final queryKey = normalizedKeys.join('|');
    if (_activeDishQueryKey == queryKey) {
      if (_selectedProvince?.id != province.id) {
        setState(() => _selectedProvince = province);
      }
      return;
    }
    _activeDishQueryKey = queryKey;
    debugPrint(
      '[Home] setProvince: name=${province.name} code=${province.code} id=${province.id} keys=$keys',
    );
    final stream = _service.watchDishesByProvinceKeys(keys).asBroadcastStream();
    setState(() {
      _selectedProvince = province;
      _dishesStream = stream;
      _provinceDishes = const [];
      _dishesError = null;
    });
    _dishesSub?.cancel();
    _dishesSub = stream.listen(
      (dishes) {
        if (!mounted) return;
        _receivedDishResult = true;
        setState(() {
          _provinceDishes = dishes;
          _dishesError = null;
          if (dishes.isNotEmpty) {
            _dishesCache = dishes;
            _dishesCacheProvinceId = province.id;
            _todayDishesCache = dishes;
          }
        });
        _checkStartupReady();
      },
      onError: (error) {
        if (!mounted) return;
        _receivedDishResult = true;
        setState(() {
          _dishesError = error;
        });
        _checkStartupReady();
      },
    );
    _imageIndex.value = 0;
  }

  void _checkStartupReady() {
    if (!mounted || _startupReported) return;
    final nearbySettled =
        _nearbyHomeController.status != NearbyHomeStatus.idle &&
        _nearbyHomeController.status != NearbyHomeStatus.loading;
    final provinceSettled = !_provincesLoading;
    if (provinceSettled && _receivedDishResult && nearbySettled) {
      _reportStartupReady();
    }
  }

  void _reportStartupReady() {
    if (!mounted || _startupReported) return;
    _startupReported = true;
    widget.onStartupReady?.call();
  }

  List<String> _provinceQueryKeys(ProvinceModel province) {
    // Trả về nhiều biến thể để khớp với field province_code trong collection dishes:
    // - code
    // - id (doc id)
    // - name (đủ dấu)
    // - slug của name
    // - slug/code/id đã normalize
    // - slug trong province (nếu có)
    final code = province.code.trim();
    final id = province.id.trim();
    final name = province.name.trim();
    final slug = (province.slug ?? '').trim();
    final nameSlug = _slugify(name);
    final normCode = _normalizeKey(code);
    final normId = _normalizeKey(id);
    final normName = _normalizeKey(name);
    final normSlug = _normalizeKey(slug);
    final noAccentName = _removeDiacritics(name);
    return [
      code,
      id,
      name,
      slug,
      ...province.mergedFrom,
      nameSlug,
      normCode,
      normId,
      normName,
      normSlug,
      noAccentName,
    ].where((v) => v.isNotEmpty).toSet().toList();
  }

  String _removeDiacritics(String input) {
    const source =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const target =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final lower = input.toLowerCase();
    final codeUnits = lower.split('');
    final mapped =
        codeUnits.map((ch) {
          final index = source.indexOf(ch);
          return index == -1 ? ch : target[index];
        }).join();
    return mapped.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _slugify(String raw) {
    final normalized = _removeDiacritics(raw).trim();
    if (normalized.isEmpty) return '';
    final cleaned = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    return cleaned.split(RegExp(r'\s+')).join('_');
  }

  String _normalizeKey(String raw) {
    final normalized = _removeDiacritics(raw).trim().toLowerCase();
    return normalized.replaceAll('-', '_');
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
      if (!mounted ||
          !widget.isActive.value ||
          ModalRoute.of(context)?.isCurrent != true ||
          !_pageController.hasClients ||
          _pageController.position.isScrollingNotifier.value) {
        return;
      }
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
    _locationRepository.update(pos);
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
    return true;
  }

  Future<void> _resolveGpsProvince() async {
    if (_gpsResolving) return;
    _gpsResolving = true;
    try {
      // Province selection must use a fresh fix. Reusing last-known here can
      // keep the previous city after the emulator/device location has moved.
      final result = await _locationService.getCurrentLocation(
        accuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
        useLastKnown: false,
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
    final t = AppLocalizations.of(context)!;

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
                      t.homeProvincePickerTitle,
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
                          hintText: t.homeProvincePickerSearchHint,
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
                                  t.homeProvinceNotFound,
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
                                            child: Text(
                                              p.name,
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
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
                                              child: Text(
                                                t.homeProvinceSelected,
                                                style: const TextStyle(
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
      _bootResolved = true;
      _bootTargetProvinceId = picked.id;
      _selectionInitialized = false;
    });
    _setProvince(picked);
    widget.onProvinceLabelChanged(picked.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    // Tu dong lay thang hien tai de hien thi tieu de theo lich.
    final now = DateTime.now();
    final monthlyDestinationTitle = t.homeMonthlyDestinationTitle(now.month);

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchField(theme, t),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildPromoJourneyCard(theme),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HomeJourneySection(
            userId: FirebaseAuth.instance.currentUser?.uid,
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedProvince != null) _buildTodaySuggestionBlock(),
        _buildMonthlyDestinationBlock(theme, t, monthlyDestinationTitle),
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
                        initialNearbyQuery: t.homeNearbyQuery,
                      ),
                ),
              );
            },
            onTapPlace: (place) {
              // Mo chi tiet quan an khi bam vao card.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritePlaceDetailPage(place: place),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedProvince == null)
          _buildEmpty(t.homeSelectProvinceToSeeDishes),
        if (_selectedProvince != null && _dishesStream != null)
          StreamBuilder<List<DishModel>>(
            stream: _dishesStream,
            builder: (context, snapshot) {
              final provinceId = _selectedProvince?.id;

              if (snapshot.connectionState == ConnectionState.waiting) {
                // Reuse cache while chờ stream để tránh UI kẹt trạng thái loading.
                if (provinceId != null &&
                    _dishesCacheProvinceId == provinceId &&
                    _dishesCache.isNotEmpty) {
                  final cached = _filterDishes(_dishesCache);
                  if (cached.isNotEmpty) {
                    return _buildDishList(context, theme, t, cached);
                  }
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return _buildEmpty(t.homeDishListLoadError);
              }

              var dishes = snapshot.data ?? const <DishModel>[];
              if (provinceId != null && dishes.isNotEmpty) {
                // Lưu cache cho tỉnh hiện tại để dùng lại khi GPS hoặc stream tạm ngắt.
                _dishesCache = dishes;
                _dishesCacheProvinceId = provinceId;
              }

              // Khi stream trả về rỗng (ví dụ GPS thay đổi liên tục) dùng cache nếu khớp tỉnh.
              if (dishes.isEmpty &&
                  provinceId != null &&
                  _dishesCacheProvinceId == provinceId) {
                dishes = _dishesCache;
              }

              final filtered = _filterDishes(dishes);

              if (filtered.isEmpty) {
                return _buildEmpty(t.homeDishNotFound);
              }

              return _buildDishList(context, theme, t, filtered);
            },
          ),
      ],
    );
  }

  Widget _buildMonthlyDestinationBlock(
    ThemeData theme,
    AppLocalizations t,
    String monthlyDestinationTitle,
  ) {
    if (_provincesSub == null && _provincesLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _provincesSub == null) {
          _startProvinceListener();
        }
      });
    }

    if (_provincesLoading && _provinces.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: LinearProgressIndicator(),
      );
    }
    if (_provincesError != null) {
      return _buildEmpty(t.homeProvinceLoadError);
    }

    final provinces = _provinces;
    if (provinces.isEmpty) {
      widget.onProvinceLabelChanged('');
      widget.onProvincePickerReady(null);
      return _buildEmpty(t.homeProvinceEmpty);
    }

    widget.onProvincePickerReady(_openProvincePicker);

    final selected = _selectedProvince;
    final selectedInList =
        selected != null && provinces.any((p) => p.id == selected.id);
    if (!selectedInList) {
      _selectionInitialized = false;
    }

    final preferred = _findPreferredProvince(provinces);
    final selectedProvince = selectedInList ? selected : null;
    late final ProvinceModel target;
    if (!_bootResolved) {
      final bootCandidate = selectedProvince ?? preferred ?? provinces.first;
      _bootTargetProvinceId ??= bootCandidate.id;
      target = provinces.firstWhere(
        (p) => p.id == _bootTargetProvinceId,
        orElse: () => bootCandidate,
      );
    } else {
      target =
          (!_selectionInitialized && preferred != null)
              ? preferred
              : (selectedProvince ?? preferred ?? provinces.first);
    }

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
          _buildEmpty(t.homeProvinceNoImage)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 190,
              child: NotificationListener<ScrollNotification>(
                // PageController animations can finish during a route/tree
                // transition. Do not let their late ScrollEndNotification
                // reach an inactive Material ancestor.
                onNotification: (_) => true,
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
                          arguments:
                              target.code.trim().isNotEmpty
                                  ? target.code
                                  : target.id,
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
  }

  Widget _buildTodaySuggestionBlock() {
    final t = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_dishesError != null) {
      return _buildEmpty(t.homeTodaySuggestionError);
    }

    final dishes =
        _provinceDishes.isNotEmpty ? _provinceDishes : _todayDishesCache;
    if (dishes.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final timeBucket = _recommendationTimeBucket(now);
    final provinceId = _selectedProvince?.id;
    final preferencesKey = _recommendationPreferencesKey(_userPreferences);
    final canReuseCache =
        identical(_recommendationCacheSource, dishes) &&
        _recommendationCachePreferencesKey == preferencesKey &&
        _recommendationCacheProvinceId == provinceId &&
        _recommendationCacheLanguage == languageCode &&
        _recommendationCacheTimeBucket == timeBucket;

    late final List<RecommendedDish> recommendedDishes;
    if (canReuseCache) {
      recommendedDishes = _recommendationCache;
    } else {
      try {
        recommendedDishes = _recommendationService.recommendTodayWithReasons(
          dishes: dishes,
          preferences: _userPreferences,
          now: now,
          languageCode: languageCode,
        );
      } catch (error) {
        debugPrint('[Home] recommendation failed: $error');
        recommendedDishes =
            dishes
                .take(21)
                .map(
                  (dish) => RecommendedDish(
                    dish: dish,
                    score: 0,
                    explanation:
                        languageCode == 'en'
                            ? 'A discovery pick for you today.'
                            : 'Gợi ý khám phá dành cho bạn hôm nay.',
                  ),
                )
                .toList();
      }
      _recommendationCache = recommendedDishes;
      _recommendationCacheSource = dishes;
      _recommendationCachePreferencesKey = preferencesKey;
      _recommendationCacheProvinceId = provinceId;
      _recommendationCacheLanguage = languageCode;
      _recommendationCacheTimeBucket = timeBucket;
    }
    if (recommendedDishes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TodayEatSection(
            recommendations: recommendedDishes,
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
  }

  String _recommendationPreferencesKey(UserPreferences? preferences) {
    if (preferences == null) return 'none';
    final map = preferences.toMap();
    final keys = map.keys.toList()..sort();
    return keys.map((key) => '$key=${map[key]}').join('|');
  }

  /// Cache thay đổi theo đúng các mốc bữa ăn mà RecommendationContext sử dụng.
  String _recommendationTimeBucket(DateTime now) {
    final mealTime = switch (now.hour) {
      >= 5 && < 10 => 'breakfast',
      >= 10 && < 14 => 'lunch',
      >= 14 && < 17 => 'snack',
      >= 17 && < 21 => 'dinner',
      _ => 'late_night',
    };
    return '${now.year}-${now.month}-${now.day}:$mealTime';
  }

  List<DishModel> _filterDishes(List<DishModel> dishes) {
    final query = _query.toLowerCase();
    final lang = Localizations.localeOf(context).languageCode;
    if (query.isEmpty) {
      return dishes;
    }
    return dishes.where((dish) {
      final name = dish.getName(lang).toLowerCase();
      final tag = dish.getCategory(lang).toLowerCase();
      final nameEn = dish.getName('en').toLowerCase();
      final tagEn = dish.getCategory('en').toLowerCase();
      return name.contains(query) ||
          tag.contains(query) ||
          nameEn.contains(query) ||
          tagEn.contains(query);
    }).toList();
  }

  Widget _buildDishList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations t,
    List<DishModel> filtered,
  ) {
    return HomeDishSection(
      dishes: filtered,
      userLat: _nearbyHomeController.userLatLng?.latitude,
      userLng: _nearbyHomeController.userLatLng?.longitude,
    );
  }

  Widget _buildSearchField(ThemeData theme, AppLocalizations t) {
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
        onSubmitted: (_) => _openSearchPage(),
        decoration: InputDecoration(
          icon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _openSearchPage,
          ),
          hintText: t.homeSearchHint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPromoJourneyCard(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final quickActions = <_HomeQuickAction>[
      _HomeQuickAction(
        label: t.homeQuickNearby,
        icon: Icons.location_on_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => MapPage(
                    initialNearbyPlaces: _nearbyHomeController.places,
                    initialNearbyQuery: t.homeNearbyMapQuery,
                  ),
            ),
          );
        },
      ),
      _HomeQuickAction(
        label: t.homeQuickCheckIn,
        icon: Icons.verified_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FoodJourneyPage()),
          );
        },
      ),
      _HomeQuickAction(
        label: t.homeQuickSavedPlaces,
        icon: Icons.bookmark_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesTabsPage()),
          );
        },
      ),
      _HomeQuickAction(
        label: t.homeQuickMap,
        icon: Icons.map_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapPage()),
          );
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131821) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF242B36) : const Color(0xFFFFE4CB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 134,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (_) => true,
                      child: PageView.builder(
                        controller: _promoBannerController,
                        itemCount: _promoBanners.length,
                        onPageChanged:
                            (index) => _promoBannerIndex.value = index,
                        itemBuilder: (context, index) {
                          return Image.asset(
                            _promoBanners[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _promoBannerIndex,
                        builder: (context, value, _) {
                          return _buildPromoDots(_promoBanners.length, value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(quickActions.length, (index) {
                final item = quickActions[index];
                return Expanded(
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF1A2230)
                                      : const Color(0xFFFFF4EA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              item.icon,
                              color: const Color(0xFFFF7A1A),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 20,
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                item.label,
                                maxLines: 1,
                                softWrap: false,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark
                                          ? Colors.white70
                                          : const Color(0xFF5F5B57),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoDots(int count, int activeIndex) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (index) {
            final isActive = index == activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(
                color:
                    isActive
                        ? const Color(0xFFFFA144)
                        : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _openSearchPage() {
    final args = SearchPageArgs(
      initialQuery: _searchController.text.trim(),
      provinceCode: _selectedProvince?.code,
      provinceName: _selectedProvince?.name,
      userLat: _nearbyHomeController.userLatLng?.latitude,
      userLng: _nearbyHomeController.userLatLng?.longitude,
    );
    Navigator.pushNamed(context, RouteNames.search, arguments: args);
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

class _HomeQuickAction {
  const _HomeQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}
