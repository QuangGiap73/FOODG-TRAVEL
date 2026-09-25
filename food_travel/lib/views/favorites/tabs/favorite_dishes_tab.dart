import 'package:flutter/material.dart';
import 'package:food_travel/l10n/app_localizations.dart';
import 'package:food_travel/widgets/network_image_fallback.dart';

import '../../../models/dish_model.dart';
import '../../../router/route_names.dart';
import '../../../services/favorite_service.dart';

// Tab mon an: hien thi danh sach mon yeu thich
class FavoriteDishesTab extends StatelessWidget {
  const FavoriteDishesTab({
    super.key,
    required this.uid,
    this.query = '',
  });

  final String uid;
  final String query;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return StreamBuilder<List<DishModel>>(
      stream: FavoriteService().watchFavoriteDishes(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Center(child: Text(t.favoriteDishesLoadError));
        }

        final dishes = snapshot.data ?? [];
        final q = query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? dishes
            : dishes.where((d) {
                final nameVi = d.getName('vi').toLowerCase();
                final nameEn = d.getName('en').toLowerCase();
                final catVi = d.getCategory('vi').toLowerCase();
                final catEn = d.getCategory('en').toLowerCase();
                final provinceVi = d.getProvince('vi').toLowerCase();
                final provinceEn = d.getProvince('en').toLowerCase();
                final slug = d.slug.toLowerCase();
                return nameVi.contains(q) ||
                    nameEn.contains(q) ||
                    catVi.contains(q) ||
                    catEn.contains(q) ||
                    provinceVi.contains(q) ||
                    provinceEn.contains(q) ||
                    slug.contains(q);
              }).toList();

        if (filtered.isEmpty) {
          return Center(child: Text(t.favoriteDishesEmpty));
        }

        return GridView.builder(
          itemCount: filtered.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.66,
          ),
          itemBuilder: (context, index) {
            final dish = filtered[index];
            return _DishCard(
              dish: dish,
              onRemove: () => FavoriteService().toggleFavorite(uid, dish.id),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.dishDetail,
                  arguments: dish.id,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.dish,
    required this.onRemove,
    required this.onTap,
  });

  final DishModel dish;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF262B33) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final imageUrl = dish.imageUrl.trim();
    // Du lieu hien tai: province_code dang chua TEN TINH
    final province = dish.getProvince(lang).trim();
    final region = _formatRegion(dish.getRegion(lang), t);
    final provinceRegion = _formatProvinceRegion(province, region, t);
    final dishName = dish.getName(lang);
    final spicy = dish.spicyLevel;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Anh mon an
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: networkImageErrorBuilder,
                      )
                    else
                      Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.image, size: 32),
                      ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x99000000), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // Nut bo yeu thich
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _GlassIconButton(
                        icon: Icons.bookmark,
                        onTap: onRemove,
                      ),
                    ),
                  ],
                ),
              ),
              // Noi dung
              SizedBox(
                height: 112,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 38,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            dishName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.place, size: 12, color: textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              provinceRegion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            size: 12,
                            color: Color(0xFFF97316),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            spicy == 0
                                ? t.favoriteSpicyNone
                                : t.favoriteSpicyLevel(spicy),
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

// Format hien thi: "Ten tinh - Mien"
String _formatProvinceRegion(
  String province,
  String region,
  AppLocalizations t,
) {
  if (province.isEmpty && region.isEmpty) return t.favoriteProvinceUpdating;
  if (province.isEmpty) return region;
  if (region.isEmpty) return province;
  return '$province - $region';
}

// Chuyen regionCode ve ten mien de doc
String _formatRegion(String raw, AppLocalizations t) {
  final code = raw.trim().toLowerCase();
  if (code.isEmpty) return '';

  switch (code) {
    case 'north':
    case 'mien_bac':
    case 'mien bac':
    case 'bac':
    case 'mb':
      return t.regionNorth;
    case 'central':
    case 'mien_trung':
    case 'mien trung':
    case 'trung':
    case 'trung bo':
    case 'mt':
      return t.regionCentral;
    case 'south':
    case 'mien_nam':
    case 'mien nam':
    case 'nam':
    case 'nam bo':
    case 'mn':
      return t.regionSouth;
    default:
      return raw;
  }
}
