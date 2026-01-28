import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/dish_model.dart';
import '../../models/places_model.dart';
import '../../services/favorite_service.dart';
import '../../services/restaurants/favorite_place_service.dart';

// Trang yeu thich moi: gom 2 tab Mon an va Quan an
class FavoritesTabsPage extends StatelessWidget {
  const FavoritesTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui long dang nhap')),
      );
    }

    // DefaultTabController giup quan ly TabBar + TabBarView
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yeu thich'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mon an'),
              Tab(text: 'Quan an'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FavoriteDishesTab(uid: user.uid),
            _FavoritePlacesTab(uid: user.uid),
          ],
        ),
      ),
    );
  }
}

class _FavoriteDishesTab extends StatelessWidget {
  const _FavoriteDishesTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DishModel>>(
      stream: FavoriteService().watchFavoriteDishes(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Khong the tai mon yeu thich.'));
        }

        final dishes = snapshot.data ?? [];
        if (dishes.isEmpty) {
          return const Center(child: Text('Chua co mon yeu thich.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dishes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final dish = dishes[index];
            return _FavoriteDishCard(
              dish: dish,
              onRemove: () {
                // Toggle lai de bo yeu thich mon
                FavoriteService().toggleFavorite(uid, dish.id);
              },
            );
          },
        );
      },
    );
  }
}

class _FavoritePlacesTab extends StatelessWidget {
  const _FavoritePlacesTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GoongNearbyPlace>>(
      // Lay danh sach quan yeu thich tu Firestore
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
          padding: const EdgeInsets.all(16),
          itemCount: places.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final place = places[index];
            return _FavoritePlaceCard(
              place: place,
              onRemove: () {
                // Tinh placeKey dung y nhu luc luu de xoa dung document
                final placeKey = buildPlacekey(place);
                FavoritePlaceService().toggleFavorite(
                  uid,
                  place,
                  placeKey: placeKey,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FavoriteDishCard extends StatelessWidget {
  const _FavoriteDishCard({
    required this.dish,
    required this.onRemove,
  });

  final DishModel dish;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: const Icon(Icons.image, size: 32),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withOpacity(0.35),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onRemove,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
          ],
        ),
      ),
    );
  }
}

class _FavoritePlaceCard extends StatelessWidget {
  const _FavoritePlaceCard({
    required this.place,
    required this.onRemove,
  });

  final GoongNearbyPlace place;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = place.address.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: place.photoUrl.isNotEmpty
                ? Image.network(
                    place.photoUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.storefront_outlined),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address.isEmpty ? 'Dang cap nhat dia chi' : address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            // Bam nut nay de bo yeu thich quan
            onPressed: onRemove,
            icon: const Icon(Icons.favorite),
            color: Colors.redAccent,
            tooltip: 'Bo yeu thich',
          ),
        ],
      ),
    );
  }
}

