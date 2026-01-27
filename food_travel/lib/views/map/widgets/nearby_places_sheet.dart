import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/places_model.dart';

class NearbyPlacesSheet extends StatelessWidget {
  const NearbyPlacesSheet({
    super.key,
    required this.places,
    required this.onOpenDetail,
    this.onDirections,
    this.userLocation,
  });

  final List<GoongNearbyPlace> places;
  final ValueChanged<GoongNearbyPlace> onOpenDetail;
  final ValueChanged<GoongNearbyPlace>? onDirections;
  final LatLng? userLocation;

  // Tinh khoang cach tu vi tri hien tai den quan.
  double? _distanceMeters(GoongNearbyPlace place) {
    if (userLocation == null) return null;
    return Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      place.lat,
      place.lng,
    );
  }

  String? _formatDistance(double? meters) {
    if (meters == null) return null;
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String? _formatEta(double? meters) {
    if (meters == null) return null;
    const metersPerMinute = 150.0;
    final minutes = (meters / metersPerMinute).round().clamp(1, 999);
    return '~$minutes phut';
  }

  Widget _buildThumbnail(GoongNearbyPlace place, ThemeData theme) {
    final url = place.photoUrl.trim();
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.restaurant_outlined),
    );
    if (url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Mo cua',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFavoriteChip(ThemeData theme) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(
          Icons.favorite_border,
          size: 18,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildDirectionsButton(GoongNearbyPlace place, VoidCallback? onTap) {
    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.navigation_outlined, size: 16),
        label: const Text(
          'Chi duong',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildPlaceCard(
    BuildContext context,
    GoongNearbyPlace place, {
    required bool highlight,
  }) {
    final theme = Theme.of(context);
    final meters = _distanceMeters(place);
    final distance = _formatDistance(meters);
    final eta = _formatEta(meters);
    final address =
        place.address.trim().isEmpty ? 'Dang cap nhat dia chi' : place.address;
    final borderColor =
        highlight ? Colors.orange.shade400 : theme.dividerColor.withOpacity(0.3);
    final onDirectionsTap =
        onDirections == null ? null : () => onDirections!(place);

    return InkWell(
      onTap: () => onOpenDetail(place),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: highlight ? 1.2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(place, theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Chua co danh gia',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance ?? 'Dang cap nhat',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          if (eta != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '- $eta',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.25)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
                _buildFavoriteChip(theme),
                const SizedBox(width: 8),
                _buildDirectionsButton(place, onDirectionsTap),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    // Sheet truot len de hien thi danh sach quan.
    return DraggableScrollableSheet(
      initialChildSize: 0.26,
      minChildSize: 0.16,
      maxChildSize: 0.62,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Quan gan day (${places.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Khoang cach',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.swap_vert, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: places.length,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _buildPlaceCard(
                      context,
                      place,
                      highlight: index == 0,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

