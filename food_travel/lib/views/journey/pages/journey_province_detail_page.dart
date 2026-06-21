import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/dish_model.dart';
import '../../../models/journey/checkin_model.dart';
import '../../../models/journey/journey_province_progress.dart';
import '../../../models/places_model.dart';
import '../../../services/food_service.dart';
import '../../dishes/dish_detail_page.dart';
import '../../favorites/place_detail_page.dart';
import '../data/province_journey_media.dart';
import 'journey_checkin_history_page.dart';

class JourneyProvinceDetailPage extends StatelessWidget {
  const JourneyProvinceDetailPage({
    super.key,
    required this.userId,
    required this.provinceCode,
    required this.provinceName,
  });

  final String userId;
  final String provinceCode;
  final String provinceName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF6),
      body: StreamBuilder<JourneyProvinceProgress?>(
        stream: _watchProvinceProgress(),
        builder: (context, progressSnapshot) {
          final progress =
              progressSnapshot.data ??
              JourneyProvinceProgress(
                provinceCode: provinceCode,
                provinceName: provinceName,
              );

          return StreamBuilder<List<JourneyCheckin>>(
            stream: _watchProvinceCheckins(),
            builder: (context, checkinSnapshot) {
              final checkins = checkinSnapshot.data ?? const <JourneyCheckin>[];
              final visitedPlaces = _buildVisitedPlaces(checkins);
              final visitedDistrictCount = _countVisitedDistricts(checkins);

              return StreamBuilder<List<DishModel>>(
                stream: FoodService().watchDishesByProvinceKeys([
                  provinceCode,
                  provinceName,
                ]),
                builder: (context, dishSnapshot) {
                  final dishes = dishSnapshot.data ?? const <DishModel>[];
                  final featuredDishes = dishes.take(6).toList();

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _ProvinceHeroSection(
                          provinceCode: provinceCode,
                          provinceName: provinceName,
                          progress: progress,
                          visitedPlaceCount: visitedPlaces.length,
                          visitedDistrictCount: visitedDistrictCount,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFBF6),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  _SectionTitle(
                                    title: 'Món nổi bật',
                                    trailing: featuredDishes.isEmpty
                                        ? null
                                        : _CountBadge(
                                            value: featuredDishes.length,
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  _FeaturedDishCards(dishes: featuredDishes),
                                  const SizedBox(height: 20),
                                  _SectionTitle(
                                    title: 'Quán đã ăn',
                                    trailing: TextButton(
                                      onPressed: () {},
                                      child: const Text('Xem tất cả'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (visitedPlaces.isEmpty)
                                    _EmptyVisitedPlacesCard(
                                      provinceName: provinceName,
                                    )
                                  else
                                    SizedBox(
                                      height: 212,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: visitedPlaces.length > 8
                                            ? 8
                                            : visitedPlaces.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          return _VisitedPlaceCard(
                                            item: visitedPlaces[index],
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.location_on_outlined,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'Tìm quán mới tại $provinceName',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFFFF7A00,
                                            ),
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Color(0xFFFFC78B),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    JourneyCheckinHistoryPage(
                                                  userId: userId,
                                                  provinceCode: provinceCode,
                                                  provinceName: provinceName,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.history_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Xem lịch sử check-in',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: const Color(
                                              0xFFFF7A00,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Stream<JourneyProvinceProgress?> _watchProvinceProgress() {
    final root = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journey')
        .doc('summary');

    final canonicalRef = root.collection('provinces_v2').doc(provinceCode);
    final legacyRef = root.collection('provinces').doc(provinceCode);

    return canonicalRef.snapshots().asyncMap((doc) async {
      if (doc.exists) {
        return JourneyProvinceProgress.fromDoc(doc);
      }
      final legacyDoc = await legacyRef.get();
      if (legacyDoc.exists) {
        return JourneyProvinceProgress.fromDoc(legacyDoc);
      }
      return null;
    });
  }

  Stream<List<JourneyCheckin>> _watchProvinceCheckins() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journey')
        .doc('summary')
        .collection('checkins')
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(JourneyCheckin.fromDoc)
              .where(
                (item) =>
                    item.provinceCode.trim().toLowerCase() ==
                    provinceCode.trim().toLowerCase(),
              )
              .toList();
        });
  }

  List<_VisitedPlaceSummary> _buildVisitedPlaces(List<JourneyCheckin> checkins) {
    final grouped = <String, _VisitedPlaceSummary>{};

    for (final item in checkins) {
      final key = item.placeId.trim().isNotEmpty ? item.placeId : item.placeName;
      final existing = grouped[key];

      if (existing == null) {
        grouped[key] = _VisitedPlaceSummary(
          placeId: item.placeId,
          placeName: item.placeName,
          placeAddress: item.placeAddress,
          placeLat: item.placeLat,
          placeLng: item.placeLng,
          districtName: item.districtName ?? '',
          imageUrl: item.placeImageUrl ?? '',
          lastDistanceMeters: item.distanceMeters,
          checkinCount: 1,
          latestCheckinAt: item.createdAt,
        );
        continue;
      }

      grouped[key] = existing.copyWith(
        checkinCount: existing.checkinCount + 1,
        latestCheckinAt: item.createdAt ?? existing.latestCheckinAt,
        placeAddress: existing.placeAddress.isEmpty
            ? item.placeAddress
            : existing.placeAddress,
        placeLat: existing.placeLat == 0 ? item.placeLat : existing.placeLat,
        placeLng: existing.placeLng == 0 ? item.placeLng : existing.placeLng,
        districtName: existing.districtName.isEmpty
            ? (item.districtName ?? '')
            : existing.districtName,
        imageUrl: existing.imageUrl.isEmpty
            ? (item.placeImageUrl ?? '')
            : existing.imageUrl,
        lastDistanceMeters: item.distanceMeters > 0
            ? item.distanceMeters
            : existing.lastDistanceMeters,
      );
    }

    final list = grouped.values.toList()
      ..sort((a, b) {
        final aMillis = a.latestCheckinAt?.millisecondsSinceEpoch ?? 0;
        final bMillis = b.latestCheckinAt?.millisecondsSinceEpoch ?? 0;
        return bMillis.compareTo(aMillis);
      });

    return list;
  }

  int _countVisitedDistricts(List<JourneyCheckin> checkins) {
    return checkins
        .map((item) => item.districtName ?? '')
        .map((name) => name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;
  }
}

class _ProvinceHeroSection extends StatelessWidget {
  const _ProvinceHeroSection({
    required this.provinceCode,
    required this.provinceName,
    required this.progress,
    required this.visitedPlaceCount,
    required this.visitedDistrictCount,
  });

  final String provinceCode;
  final String provinceName;
  final JourneyProvinceProgress progress;
  final int visitedPlaceCount;
  final int visitedDistrictCount;

  @override
  Widget build(BuildContext context) {
    final bannerAsset = provinceJourneyBannerAssetFor(
      provinceCode: provinceCode,
      provinceName: provinceName,
    );
    final avatarAsset = provinceJourneyAvatarAssetFor(
      provinceCode: provinceCode,
      provinceName: provinceName,
    );

    return SizedBox(
      height: 340,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(
              height: 250,
              child: Stack(
            fit: StackFit.expand,
            children: [
              if (bannerAsset != null)
                Image.asset(bannerAsset, fit: BoxFit.cover)
              else
                Container(color: const Color(0xFFFFE8CC)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.42),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _HeroIconButton(
                        icon: Icons.share_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 58,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                    children: [
                      Text(
                        provinceName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E2430),
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _buildSubtitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5E6470),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _StatsCard(
              progress: progress,
              visitedPlaceCount: visitedPlaceCount,
              visitedDistrictCount: visitedDistrictCount,
            ),
          ),
          Positioned(
            left: 28,
            bottom: 126,
            child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarAsset != null
                  ? Image.asset(avatarAsset, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFFFF0DB),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.location_city_rounded,
                        color: Color(0xFFFF7A00),
                        size: 30,
                      ),
                    ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  String _buildSubtitle() {
    if (progress.checkinCount > 0) {
      return 'Bạn đã có ${progress.checkinCount} lượt check-in tại tỉnh thành này';
    }
    return 'Khám phá hành trình ẩm thực và những quán bạn đã ghé qua';
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.progress,
    required this.visitedPlaceCount,
    required this.visitedDistrictCount,
  });

  final JourneyProvinceProgress progress;
  final int visitedPlaceCount;
  final int visitedDistrictCount;

  @override
  Widget build(BuildContext context) {
    final effectiveVisitedPlaceCount = visitedPlaceCount > 0
        ? visitedPlaceCount
        : progress.uniquePlacesCount;
    final effectiveVisitedDistrictCount = visitedDistrictCount > 0
        ? visitedDistrictCount
        : progress.districtsCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.verified_outlined,
              color: const Color(0xFF5CA8FF),
              value: progress.checkinCount,
              label: 'lượt check-in',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.storefront_rounded,
              color: const Color(0xFFFF7A00),
              value: effectiveVisitedPlaceCount,
              label: 'quán đã ăn',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.map_outlined,
              color: const Color(0xFF78B942),
              value: effectiveVisitedDistrictCount,
              label: 'quận đã đi qua',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF202531),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D7280),
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 64,
      color: const Color(0xFFF0E8DE),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF202531),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFF7A00),
        ),
      ),
    );
  }
}

class _FeaturedDishCards extends StatelessWidget {
  const _FeaturedDishCards({required this.dishes});

  final List<DishModel> dishes;

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF2E5D6)),
        ),
        child: const Text(
          'Chưa có dữ liệu món nổi bật cho tỉnh thành này.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF707680),
          ),
        ),
      );
    }

    return SizedBox(
      height: 182,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dishes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final dish = dishes[index];
          return _FeaturedDishCard(dish: dish);
        },
      ),
    );
  }
}

class _FeaturedDishCard extends StatelessWidget {
  const _FeaturedDishCard({required this.dish});

  final DishModel dish;

  @override
  Widget build(BuildContext context) {
    final dishName = dish.getName('vi').trim().isNotEmpty
        ? dish.getName('vi').trim()
        : dish.name;

    return SizedBox(
      width: 148,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DishDetailPage(dishId: dish.id),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: _DishImage(imageUrl: dish.imageUrl),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dishName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF212632),
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0DF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF7A00),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _DishImage extends StatelessWidget {
  const _DishImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        height: 92,
        color: const Color(0xFFFFF1E2),
        alignment: Alignment.center,
        child: const Icon(
          Icons.restaurant_menu_rounded,
          size: 34,
          color: Color(0xFFFF7A00),
        ),
      );
    }

    return Image.network(
      imageUrl,
      height: 92,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          height: 92,
          color: const Color(0xFFFFF1E2),
          alignment: Alignment.center,
          child: const Icon(
            Icons.restaurant_menu_rounded,
            size: 34,
            color: Color(0xFFFF7A00),
          ),
        );
      },
    );
  }
}

class _VisitedPlaceCard extends StatelessWidget {
  const _VisitedPlaceCard({required this.item});

  final _VisitedPlaceSummary item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openPlaceDetail(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: _PlaceImage(imageUrl: item.imageUrl),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${item.checkinCount} lần',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.placeName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF212632),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (item.districtName.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Color(0xFFFF7A00),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.districtName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF757B86),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        _VisitedPlaceMetaRow(item: item),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPlaceDetail(BuildContext context) {
    final seed = GoongNearbyPlace(
      id: item.placeId,
      name: item.placeName,
      address: item.placeAddress,
      district: item.districtName,
      lat: item.placeLat,
      lng: item.placeLng,
      photoUrl: item.imageUrl,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FavoritePlaceDetailPage(place: seed),
      ),
    );
  }
}

class _EmptyVisitedPlacesCard extends StatelessWidget {
  const _EmptyVisitedPlacesCard({required this.provinceName});

  final String provinceName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2E6D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.coffee_outlined,
                color: Color(0xFFFF7A00),
              ),
              SizedBox(width: 8),
              Text(
                'Chưa có quán đã ăn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF202531),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Khi bạn check-in tại $provinceName, các quán đã ghé sẽ hiển thị ở đây.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF737884),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitedPlaceMetaRow extends StatelessWidget {
  const _VisitedPlaceMetaRow({required this.item});

  final _VisitedPlaceSummary item;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VisitedPlaceMeta>(
      future: _loadMeta(),
      builder: (context, snapshot) {
        final meta = snapshot.data ?? _VisitedPlaceMeta.empty(item.lastDistanceMeters);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFFB300),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meta.ratingText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      size: 13,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meta.distanceText,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<_VisitedPlaceMeta> _loadMeta() async {
    double? rating;
    try {
      if (item.placeId.trim().isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('places')
            .doc(item.placeId)
            .get();
        final data = doc.data();
        final value = data?['avg_rating'];
        if (value is num) {
          rating = value.toDouble();
        } else if (value is String) {
          rating = double.tryParse(value);
        }
      }
    } catch (_) {}

    double distanceMeters = item.lastDistanceMeters;
    try {
      final position = await Geolocator.getCurrentPosition();
      if (item.placeLat != 0 && item.placeLng != 0) {
        distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          item.placeLat,
          item.placeLng,
        );
      }
    } catch (_) {}

    return _VisitedPlaceMeta(
      rating: rating,
      distanceMeters: distanceMeters,
    );
  }
}

class _PlaceImage extends StatelessWidget {
  const _PlaceImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        height: 104,
        color: const Color(0xFFFFF1E2),
        alignment: Alignment.center,
        child: const Icon(
          Icons.restaurant_rounded,
          size: 34,
          color: Color(0xFFFF7A00),
        ),
      );
    }

    return Image.network(
      imageUrl,
      height: 104,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          height: 104,
          color: const Color(0xFFFFF1E2),
          alignment: Alignment.center,
          child: const Icon(
            Icons.restaurant_rounded,
            size: 34,
            color: Color(0xFFFF7A00),
          ),
        );
      },
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: const Color(0xFF262B34)),
        ),
      ),
    );
  }
}

class _VisitedPlaceSummary {
  const _VisitedPlaceSummary({
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    required this.placeLat,
    required this.placeLng,
    required this.districtName,
    required this.imageUrl,
    required this.lastDistanceMeters,
    required this.checkinCount,
    required this.latestCheckinAt,
  });

  final String placeId;
  final String placeName;
  final String placeAddress;
  final double placeLat;
  final double placeLng;
  final String districtName;
  final String imageUrl;
  final double lastDistanceMeters;
  final int checkinCount;
  final Timestamp? latestCheckinAt;

  _VisitedPlaceSummary copyWith({
    String? placeId,
    String? placeName,
    String? placeAddress,
    double? placeLat,
    double? placeLng,
    String? districtName,
    String? imageUrl,
    double? lastDistanceMeters,
    int? checkinCount,
    Timestamp? latestCheckinAt,
  }) {
    return _VisitedPlaceSummary(
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      placeLat: placeLat ?? this.placeLat,
      placeLng: placeLng ?? this.placeLng,
      districtName: districtName ?? this.districtName,
      imageUrl: imageUrl ?? this.imageUrl,
      lastDistanceMeters: lastDistanceMeters ?? this.lastDistanceMeters,
      checkinCount: checkinCount ?? this.checkinCount,
      latestCheckinAt: latestCheckinAt ?? this.latestCheckinAt,
    );
  }
}

class _VisitedPlaceMeta {
  const _VisitedPlaceMeta({
    required this.rating,
    required this.distanceMeters,
  });

  final double? rating;
  final double distanceMeters;

  factory _VisitedPlaceMeta.empty(double distanceMeters) {
    return _VisitedPlaceMeta(rating: null, distanceMeters: distanceMeters);
  }

  String get ratingText {
    if (rating == null || rating! <= 0) return 'Chưa có đánh giá';
    return rating!.toStringAsFixed(1);
  }

  String get distanceText {
    if (distanceMeters <= 0) return 'Chưa xác định khoảng cách';
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}
