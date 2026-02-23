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
        final places = controller.places.take(8).toList();

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
              _buildMessage(
                controller.errorMessage ?? t.homeNearbyLoadError,
              ),
            if (status == NearbyHomeStatus.empty)
              _buildMessage(t.homeNearbyEmpty),
            if (status == NearbyHomeStatus.success && places.isNotEmpty)
              SizedBox(
                height: 220,
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
  });

  final GoongNearbyPlace place;
  final LatLng? userLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final distance = _distanceText(place, userLocation);
    final priceText = _priceText(place.price);
    final cardBg = isDark ? const Color(0xFF08122A) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final infoColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final distanceColor =
        isDark ? const Color(0xFF8AB4F8) : const Color(0xFF2563EB);
    final borderColor =
        isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000);
    final shadowColor =
        isDark
            ? Colors.black.withValues(alpha: 0.30)
            : Colors.black.withValues(alpha: 0.08);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 132,
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
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF233B6B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: Row(
                children: [
                  Text(
                    distance,
                    style: TextStyle(color: distanceColor, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.circle, size: 4, color: infoColor),
                  const SizedBox(width: 6),
                  Text(
                    priceText,
                    style: TextStyle(color: infoColor, fontSize: 16),
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
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool? isOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final open = isOpen == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: open ? const Color(0xFF2DBE60) : const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        open ? t.homeOpenNow : t.homeClosed,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
      color: const Color(0x66000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          context.read<PlaceFavoriteController>().toggle(place);
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: isFavorite ? Colors.red : Colors.white,
          ),
        ),
      ),
    );
  }
}
