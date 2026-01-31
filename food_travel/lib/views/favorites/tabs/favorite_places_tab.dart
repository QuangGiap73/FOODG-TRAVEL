import 'package:flutter/material.dart';

import '../../../models/places_model.dart';
import '../../../services/restaurants/favorite_place_service.dart';
import '../place_detail_page.dart';

// Tab Quan an: hien thi danh sach quan yeu thich
class FavoritePlacesTab extends StatelessWidget {
  const FavoritePlacesTab({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GoongNearbyPlace>>(
      stream: FavoritePlaceService().watchFavoritePlaces(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Khong the tai quan yeu thich.'));
        }

        final places = snapshot.data ?? [];
        if (places.isEmpty) {
          return const Center(child: Text('Chua co quan yeu thich.'));
        }

        return ListView.separated(
          itemCount: places.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final place = places[index];
            return _RestaurantCard(
              place: place,
              onRemove: () {
                // Xoa dung doc theo placeKey
                final placeKey = buildPlacekey(place);
                FavoritePlaceService().toggleFavorite(
                  uid,
                  place,
                  placeKey: placeKey,
                );
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FavoritePlaceDetailPage(place: place),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.place,
    required this.onRemove,
    required this.onTap,
  });

  final GoongNearbyPlace place;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262B33) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final address = place.address.trim();
    final price = place.price?.trim() ?? '';
    final rating = place.rating?.toStringAsFixed(1) ?? '';
    final isOpen = place.isOpen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Anh quan
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: place.photoUrl.isNotEmpty
                      ? Image.network(
                          place.photoUrl,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 92,
                          height: 92,
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.storefront_outlined),
                        ),
                ),
                if (isOpen != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isOpen ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOpen ? 'OPEN' : 'CLOSED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.bookmark,
                          color: Color(0xFFF97316),
                        ),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  Text(
                    price.isEmpty ? 'Quan an' : price,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFF97316)),
                      const SizedBox(width: 4),
                      Text(
                        rating.isEmpty ? 'No rating' : rating,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place, size: 12, color: textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address.isEmpty ? 'Dang cap nhat dia chi' : address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
