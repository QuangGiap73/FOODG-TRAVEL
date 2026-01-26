import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/places_model.dart';

class NearbyPlacesSheet extends StatelessWidget {
  const NearbyPlacesSheet({
    super.key,
    required this.places,
    required this.onSelect,
    this.userLocation,
  });
  final List<GoongNearbyPlace> places;
  final ValueChanged<GoongNearbyPlace> onSelect;
  final LatLng? userLocation;

  // Tinh khoang cach tu vi tri hien tai den quan.
  String? _formatDistance(GoongNearbyPlace place){
    if(userLocation == null ) return null;
    final meters = Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      place.lat,
      place.lng,
    );
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildLeading(GoongNearbyPlace place) {
    final url = place.photoUrl;
    if (url.isEmpty) {
      return const Icon(Icons.restaurant_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 44,
          height: 44,
          color: Colors.black12,
          child: const Icon(Icons.restaurant_outlined),
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
      initialChildSize: 0.22,
      minChildSize: 0.14,
      maxChildSize: 0.55,
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
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: places.length,
                  padding: const EdgeInsets.only(bottom: 12),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    final distance = _formatDistance(place);
                    return ListTile(
                      onTap: () => onSelect(place),
                      leading: _buildLeading(place),
                      title: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: distance == null
                          ? null
                          : Text(distance, style: theme.textTheme.bodySmall),
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
