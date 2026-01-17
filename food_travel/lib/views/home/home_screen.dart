import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../../models/dish_model.dart';
import '../../models/province_model.dart';
import '../../services/auth_service.dart';
import '../../services/food_service.dart';
import '../../services/user_service.dart';
import '../../router/route_names.dart';
import '../onboarding/survey_sheet.dart';
import '../personal/personal.dart';

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
    Center(child: Text('Cong thuc')),
    Center(child: Text('Luu')),
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
            label: 'Cong thuc',
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
  final _pageController = PageController(viewportFraction: 0.88);
  final _searchController = TextEditingController();
  final _userService = UserService();
  StreamSubscription? _profileSub;

  ProvinceModel? _selectedProvince;
  int _selectedProvinceIndex = 0;
  String _query = '';
  bool _selectionInitialized = false;
  String? _preferredProvinceCode;
  String? _preferredProvinceName;

  @override
  void initState() {
    super.initState();
    _startProfileListener();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
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

  void _setProvince(ProvinceModel province, int index) {
    if (_selectedProvince?.code == province.code &&
        _selectedProvinceIndex == index) {
      return;
    }
    setState(() {
      _selectedProvince = province;
      _selectedProvinceIndex = index;
    });
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

  ProvinceModel? _findPreferredProvince(List<ProvinceModel> provinces) {
    final prefCode = _preferredProvinceCode;
    if (prefCode != null && prefCode.isNotEmpty) {
      for (final province in provinces) {
        if (province.code == prefCode || province.id == prefCode) {
          return province;
        }
      }
    }
    final prefName = _preferredProvinceName;
    if (prefName != null && prefName.isNotEmpty) {
      final prefSlug = _slugify(prefName);
      for (final province in provinces) {
        if (province.name == prefName) {
          return province;
        }
        if (prefSlug.isNotEmpty &&
            (province.code == prefSlug || province.id == prefSlug)) {
          return province;
        }
      }
    }
    return null;
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
                _setProvince(target, 0);
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
            }

            final visibleProvinces = <ProvinceModel>[target];

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
                SizedBox(
                  height: 190,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        _setProvince(visibleProvinces[index], index),
                    itemCount: visibleProvinces.length,
                    itemBuilder: (context, index) {
                      final province = visibleProvinces[index];
                      final isActive = index == _selectedProvinceIndex;
                      return _buildProvinceCard(province, isActive, index);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if (visibleProvinces.length > 1)
                  Center(child: _buildDots(visibleProvinces.length)),
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
        if (_selectedProvince != null)
          StreamBuilder<List<DishModel>>(
            stream: _service.watchDishesByProvinceKeys(
              _provinceQueryKeys(_selectedProvince!),
            ),
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
                    return _buildDishCard(filtered[index]);
                  },
                ),
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

  Widget _buildProvinceCard(
    ProvinceModel province,
    bool isActive,
    int index,
  ) {
    final theme = Theme.of(context);
    final imageUrl = province.imageUrl;

    return GestureDetector(
      onTap: () => _setProvince(province, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          gradient: imageUrl.isEmpty
              ? const LinearGradient(
                  colors: [Color(0xFFFAE1B7), Color(0xFFF4B183)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent
                    ],
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
                province.name,
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
      ),
    );
  }

  Widget _buildDishCard(DishModel dish) {
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

  Widget _buildDots(int count) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == _selectedProvinceIndex;
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
