import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../controller/home/nearby_home_controlled.dart';
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
    return AnimatedBuilder(
      // Rebuild UI khi controller thay doi state.
      animation: controller,
      builder: (context, _) {
        final status = controller.status;
        // Gioi han so card de Home gon va nhanh.
        final places = controller.places.take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Quan ngon gan ban',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: places.isEmpty ? null : onTapMap,
                  child: const Text('Xem ban do >>'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (status == NearbyHomeStatus.loading) _buildLoading(),
            if (status == NearbyHomeStatus.locationDisabled)
              _buildMessage('Hay bat vi tri de xem quan gan ban.'),
            if (status == NearbyHomeStatus.error)
              _buildMessage(controller.errorMessage ?? 'Khong tai du lieu.'),
            if (status == NearbyHomeStatus.empty)
              _buildMessage('Chua tim thay quan phu hop.'),
            if (status == NearbyHomeStatus.success && places.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.separated(
                  // Danh sach card ngang theo mock Home.
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
    // Distance + price duoc tinh san cho dong thong tin ben duoi.
    final distance = _distanceText(place, userLocation);
    final priceText = _priceText(place.price);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF08122A),
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
                          return Container(color: const Color(0xFF1A2233));
                        },
                      )
                    else
                      Container(color: const Color(0xFF1A2233)),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _OpenBadge(isOpen: place.isOpen),
                    ),
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0x66000000),
                        child: Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Colors.white,
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
                style: const TextStyle(
                  color: Colors.white,
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
                    style: const TextStyle(
                      color: Color(0xFF8AB4F8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 6),
                  Text(
                    priceText,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const Spacer(),
                  if (place.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF233B6B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '* ${place.rating!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool? isOpen;

  @override
  Widget build(BuildContext context) {
    final open = isOpen == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: open ? const Color(0xFF2DBE60) : const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        open ? 'Dang mo' : 'Dang dong',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
