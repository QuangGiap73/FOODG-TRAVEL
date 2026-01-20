import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controller/dish/dish_detail_controller.dart';
import '../../controller/favorite/favorite_controller.dart';
import '../../models/dish_model.dart';
import '../../services/food_service.dart';
import '../../widgets/favorite_button.dart';

class DishDetailPage extends StatefulWidget {
  const DishDetailPage({super.key, required this.dishId});
  final String dishId;

  @override
  State<DishDetailPage> createState() => _DishDetailPageState();
}

class _DishDetailPageState extends State<DishDetailPage> {
  final _controller = DishDetailController();
  final _favoriteController = FavoriteController();

  @override
  void initState() {
    super.initState();
    _controller.bind(widget.dishId);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _favoriteController.bindUser(uid);
  }

  @override
  void dispose() {
    _controller.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _favoriteController]),
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_controller.error != null || _controller.dish == null) {
          return const Scaffold(
            body: Center(child: Text('Khong tim thay mon an')),
          );
        }

        final dish = _controller.dish!;
        final isFavorite = _favoriteController.isFavorite(dish.id);
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(title: Text(dish.name)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _HeroImage(
                imageUrl: dish.imageUrl,
                name: dish.name,
                isFavorite: isFavorite,
                onToggle: () => _favoriteController.toggleFavorite(dish.id),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  dish.tag,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(text: 'Cay: ${dish.spicyLevel}/5'),
                    _Chip(text: 'No: ${dish.satietyLevel}/5'),
                    if (dish.bestTime.isNotEmpty) _Chip(text: dish.bestTime),
                    if (dish.bestSeason.isNotEmpty) _Chip(text: dish.bestSeason),
                    if (dish.priceRange.isNotEmpty) _Chip(text: dish.priceRange),
                    if (dish.provinceName.isNotEmpty)
                      _Chip(text: dish.provinceName),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(title: 'Mo ta', text: dish.description),
              _SectionList(title: 'Nguyen lieu', text: dish.ingredients),
              _SectionList(title: 'Huong dan', text: dish.instructions),
              if (dish.originStory.isNotEmpty)
                _Section(title: 'Cau chuyen', text: dish.originStory),
              const SizedBox(height: 8),
              _RelatedDishes(dish: dish),
            ],
          ),
        );
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.imageUrl,
    required this.name,
    required this.isFavorite,
    required this.onToggle,
  });

  final String imageUrl;
  final String name;
  final bool isFavorite;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Icon(Icons.image, size: 40),
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
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: FavoriteButton(
              isFavorite: isFavorite,
              onTap: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({required this.title, required this.text});
  final String title;
  final String text;

  List<String> _split(String raw) {
    return raw
        .split(RegExp(r',|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _split(text);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('- $e', style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedDishes extends StatelessWidget {
  const _RelatedDishes({required this.dish});
  final DishModel dish;

  List<String> _keys(DishModel d) {
    return [
      d.provinceCode,
      d.provinceName,
    ].where((e) => e.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final keys = _keys(dish);
    if (keys.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<List<DishModel>>(
      stream: FoodService().watchDishesByProvinceKeys(keys),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        if (!snapshot.hasData) return const SizedBox.shrink();

        final items = snapshot.data!
            .where((e) => e.id != dish.id)
            .toList();

        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mon lien quan',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final d = items[index];
                    return SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: d.imageUrl.isNotEmpty
                                ? Image.network(d.imageUrl, fit: BoxFit.cover)
                                : Container(
                                    color: theme.colorScheme.surfaceVariant,
                                    child: const Icon(Icons.image),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            d.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
