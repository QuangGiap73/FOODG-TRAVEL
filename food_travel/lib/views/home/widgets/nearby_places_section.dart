import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:food_travel/l10n/app_localizations.dart';

import '../../../controller/home/nearby_home_controlled.dart';
import '../../../controller/restaurants/place_favorite_controller.dart';
import '../../../models/places_model.dart';

class NearbyPlacesSection extends StatelessWidget {
  const NearbyPlacesSection({
    super.key,
    required this.controller,
    required this.onTapMap,
    required this.onTapPlace,
  });

  final NearbyHomeController controller;
  final VoidCallback onTapMap;
  final ValueChanged<GoongNearbyPlace> onTapPlace;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      // Rebuild UI khi controller thay đổi state.
      animation: controller,
      builder: (context, _) {
        final status = controller.status;
        // Giới hạn số card để Home gọn và nhanh.
        final places = controller.places.take(12).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  t.homeNearbyTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: places.isEmpty ? null : onTapMap,
                  child: Text(t.homeNearbyViewMap),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (status == NearbyHomeStatus.loading) _buildLoading(),
            if (status == NearbyHomeStatus.locationDisabled)
              _buildMessage(t.homeNearbyEnableLocation),
            if (status == NearbyHomeStatus.error)
              _buildMessage(t.homeNearbyLoadError),
            if (status == NearbyHomeStatus.empty)
              _buildMessage(t.homeNearbyEmpty),
            if (status == NearbyHomeStatus.success && places.isNotEmpty)
              SizedBox(
                height: 236,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return SizedBox(
                      width: 250,
                      child: _PlaceCard(
                        place: place,
                        userLocation: controller.userLatLng,
                        onTap: () => onTapPlace(place),
                        onDirections: onTapMap,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 140,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMessage(String text) {
    return SizedBox(height: 90, child: Center(child: Text(text)));
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.userLocation,
    required this.onTap,
    required this.onDirections,
  });

  final GoongNearbyPlace place;
  final LatLng? userLocation;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final distance = _distanceText(place, userLocation);
    final priceText = _priceText(place.price);
    final cardBg = isDark ? const Color(0xFF08122A) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final infoColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    const accent = Color(0xFFFF5A1F);
    final borderColor =
        isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000);
    final shadowColor =
        isDark
            ? Colors.black.withValues(alpha: 0.30)
            : Colors.black.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cardBg,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 118,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (place.photoUrl.trim().isNotEmpty)
                        Image.network(
                          place.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color:
                                  isDark
                                      ? const Color(0xFF1A2233)
                                      : const Color(0xFFE5E7EB),
                            );
                          },
                        )
                      else
                        Container(
                          color:
                              isDark
                                  ? const Color(0xFF1A2233)
                                  : const Color(0xFFE5E7EB),
                        ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _OpenBadge(isOpen: place.isOpen),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _FavoriteHeart(place: place),
                      ),
                      if (place.rating != null)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF233B6B),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  place.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 3),
                child: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _InfoRow(
                icon: Icons.location_on_outlined,
                text: AppLocalizations.of(context)!.placeDistanceAway(distance),
                color: infoColor,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _InfoRow(
                icon: Icons.restaurant_outlined,
                text: '${_categoryText(place.category)}  ·  $priceText',
                color: infoColor,
              ),
            ),
            const Spacer(),
            Divider(height: 1, indent: 12, endIndent: 12, color: borderColor),
            SizedBox(
              height: 43,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.commonViewDetail,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 15),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.icon(
                      onPressed: onDirections,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 15),
                      label: Text(
                        AppLocalizations.of(context)!.mapDirections,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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

  String _distanceText(GoongNearbyPlace place, LatLng? user) {
    if (user == null) return '--';
    final meters = Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      place.lat,
      place.lng,
    );
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _priceText(String? value) {
    if (value == null || value.trim().isEmpty) return r'$$';
    final trimmed = value.trim();
    if (trimmed.contains('\$')) return trimmed;
    final numeric = int.tryParse(trimmed);
    if (numeric == null) return r'$$';
    if (numeric <= 1) return r'$';
    if (numeric == 2) return r'$$';
    if (numeric == 3) return r'$$$';
    return r'$$$$';
  }

  String _categoryText(String? value) {
    final category = value?.trim();
    return category == null || category.isEmpty ? 'Ẩm thực' : category;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFF5A1F)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool? isOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final open = isOpen == true;
    final unknown = isOpen == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color:
            open
                ? const Color(0xFF2DBE60)
                : unknown
                ? const Color(0xFF64748B)
                : const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            open
                ? t.homeOpenNow
                : unknown
                ? t.placeOpenHoursUpdating
                : t.homeClosed,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({required this.place});

  final GoongNearbyPlace place;

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<PlaceFavoriteController>();
    final isFavorite = fav.isFavorite(place);
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          context.read<PlaceFavoriteController>().toggle(place);
        },
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 17,
            color: const Color(0xFFFF5A1F),
          ),
        ),
      ),
    );
  }
}
