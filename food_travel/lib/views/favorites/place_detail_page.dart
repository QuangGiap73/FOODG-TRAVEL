import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';

import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/places_model.dart';
import '../../services/map/serpapi_places_service.dart';
import '../../config/goong_secrets.dart';

class FavoritePlaceDetailPage extends StatelessWidget {
  const FavoritePlaceDetailPage({super.key, required this.place});

  final GoongNearbyPlace place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F131A) : const Color(0xFFFAFAF9);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        top: false,
        child: FutureBuilder<GoongNearbyPlace?>(
          future: SerpApiPlacesService().fetchPlaceDetail(place),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator(minHeight: 2);
            }
            final detail = snapshot.data ?? place;
            return FutureBuilder<List<SerpApiReview>>(
              future: SerpApiPlacesService().fetchReviews(
                dataId: detail.serpDataId,
                limit: 8,
              ),
              builder: (context, reviewSnap) {
                final reviews = reviewSnap.data ?? const <SerpApiReview>[];
                return _DetailBody(place: detail, reviews: reviews);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const _StickyActionBar(),
    );
  }
}

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.place, required this.reviews});

  final GoongNearbyPlace place;
  final List<SerpApiReview> reviews;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  late final PageController _pageController;
  int _pageIndex = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Tu dong chuyen anh tren cung
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final photos = widget.place.photoUrls.isNotEmpty
          ? widget.place.photoUrls
          : (widget.place.photoUrl.isNotEmpty
              ? [widget.place.photoUrl]
              : const <String>[]);
      if (photos.length <= 1 || !_pageController.hasClients) return;
      final next = (_pageIndex + 1) % photos.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openGallery(BuildContext context, List<String> photos, int startIndex) {
    if (photos.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) {
        final controller = PageController(initialPage: startIndex);
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final url = photos[index];
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 3.2,
                    child: url.isEmpty
                        ? Container(color: Colors.black)
                        : Image.network(url, fit: BoxFit.contain),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262B33) : const Color(0xFFE2E8F0);

    final place = widget.place;
    final reviews = widget.reviews;

    final name = place.name.trim().isEmpty ? 'Quan an' : place.name.trim();
    final category = place.category?.trim() ?? '';
    final address = place.address.trim().isEmpty
        ? 'Dang cap nhat dia chi'
        : place.address.trim();
    final district = place.district.trim();
    final rating = place.rating?.toStringAsFixed(1) ?? '';
    final reviewCount = place.reviewCount;
    final price = place.price?.trim() ?? '';
    final phone = place.phone?.trim() ?? '';
    final isOpen = place.isOpen;
    final closingTime = place.closingTime?.trim() ?? '';
    final photos = place.photoUrls.isNotEmpty
        ? place.photoUrls
        : (place.photoUrl.isNotEmpty ? [place.photoUrl] : const <String>[]);
    final hours = place.openingHours;
    final amenities = place.amenities;
    final mustTry = place.mustTryItems;
    final placeKey = place.id.trim().isNotEmpty
        ? place.id.trim()
        : place.serpDataId.trim();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _HeroHeader(
          photoUrls: photos,
          isOpen: isOpen,
          closingTime: closingTime,
          controller: _pageController,
          onIndexChanged: (idx) => setState(() => _pageIndex = idx),
          onTapImage: (idx) => _openGallery(context, photos, idx),
        ),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SummaryCard(
              name: name,
              category: category,
              price: price,
              rating: rating,
              reviewCount: reviewCount,
              district: district,
              address: address,
              phone: phone,
            ),
          ),
        ),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _PhotoThumbList(
              photoUrls: photos,
              currentIndex: _pageIndex,
              onTap: (idx) {
                _pageController.animateToPage(
                  idx,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
                _openGallery(context, photos, idx);
              },
            ),
          ),
        const SizedBox(height: 6),
        if (mustTry.isNotEmpty)
          _MustTrySection(items: mustTry)
        else
          _MenuHighlightsSection(
            placeKey: placeKey,
            textSecondary: textSecondary,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _InfoSection(
            hours: hours,
            amenities: amenities,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _MiniMapCard(
            cardBg: cardBg,
            borderColor: borderColor,
            lat: place.lat,
            lng: place.lng,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _ReviewsSection(
            reviews: reviews,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(height: 110),
      ],
    );
  }
}


class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.photoUrls,
    required this.isOpen,
    required this.closingTime,
    required this.controller,
    required this.onIndexChanged,
    required this.onTapImage,
  });

  final List<String> photoUrls;
  final bool? isOpen;
  final String closingTime;
  final PageController controller;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<int> onTapImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoUrls.isEmpty)
            Container(color: const Color(0xFF2A2E33))
          else
            PageView.builder(
              controller: controller,
              itemCount: photoUrls.length,
              onPageChanged: onIndexChanged,
              itemBuilder: (context, index) {
                final url = photoUrls[index];
                return GestureDetector(
                  onTap: () => onTapImage(index),
                  child: url.isEmpty
                      ? Container(color: const Color(0xFF2A2E33))
                      : Image.network(url, fit: BoxFit.cover),
                );
              },
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x66000000), Colors.transparent, Color(0x99000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // top buttons + status gi? nguyên nhu cu...

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIcon(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    _CircleIcon(icon: Icons.share_outlined, onTap: () {}),
                    const SizedBox(width: 10),
                    _CircleIcon(icon: Icons.favorite_border, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: _StatusChip(isOpen: isOpen, closingTime: closingTime),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isOpen, required this.closingTime});

  final bool? isOpen;
  final String closingTime;

  @override
  Widget build(BuildContext context) {
    final openText = isOpen == null
        ? 'DANG CAP NHAT'
        : (isOpen! ? 'MO CUA' : 'DONG CUA');
    final extra = closingTime.isNotEmpty ? ' - Dong luc $closingTime' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6A00).withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$openText$extra',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.district,
    required this.address,
    required this.phone,
  });

  final String name;
  final String category;
  final String price;
  final String rating;
  final int? reviewCount;
  final String district;
  final String address;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF15181E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262B33) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if (category.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          category,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE0C2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFFF6A00)),
                        const SizedBox(width: 4),
                        Text(
                          rating.isEmpty ? 'N/A' : rating,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6A00),
                          ),
                        ),
                      ],
                    ),
                    if (reviewCount != null)
                      Text(
                        '(${reviewCount!})',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (price.isNotEmpty)
                Text(price, style: TextStyle(color: textPrimary, fontSize: 13)),
              if (price.isNotEmpty) _Dot(textSecondary: textSecondary),
              if (district.isNotEmpty)
                Text(district, style: TextStyle(color: textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          _AddressRow(address: address, textSecondary: textSecondary),
          const SizedBox(height: 14),
          _QuickActions(phone: phone),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.textSecondary});

  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: textSecondary, shape: BoxShape.circle),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address, required this.textSecondary});

  final String address;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.place, size: 18, color: Color(0xFFFF6A00)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textSecondary),
          ),
        ),
        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _QuickAction(icon: Icons.call, label: 'Goi dien'),
        _QuickAction(icon: Icons.navigation, label: 'Chi duong'),
        _QuickAction(icon: Icons.event, label: 'Dat ban', highlight: true),
        _QuickAction(icon: Icons.group, label: 'Moi ban'),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? const Color(0xFFFFF3E6) : const Color(0xFFF8FAFC);
    final border = highlight ? const Color(0xFFFFE0C2) : const Color(0xFFE2E8F0);
    final color = highlight ? const Color(0xFFFF6A00) : const Color(0xFF64748B);
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}

class _PhotoThumbList extends StatelessWidget {
  const _PhotoThumbList({
    required this.photoUrls,
    required this.currentIndex,
    required this.onTap,
  });

  final List<String> photoUrls;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final url = photoUrls[i];
          final active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? const Color(0xFFFF6A00) : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: url.isNotEmpty
                      ? Image.network(url, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1F242C)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionText});

  final String title;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Text(actionText, style: const TextStyle(fontSize: 12, color: Color(0xFFFF6A00))),
        ],
      ),
    );
  }
}

class _MustTrySection extends StatelessWidget {
  const _MustTrySection({required this.items});

  final List<PlaceMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Mon nen thu', actionText: 'Menu full'),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final item = items[i];
              return _MenuCard(item: item);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.length,
          ),
        ),
      ],
    );
  }
}

class _MenuHighlightsSection extends StatelessWidget {
  const _MenuHighlightsSection({
    required this.placeKey,
    required this.textSecondary,
  });

  final String placeKey;
  final Color textSecondary;

  Future<List<PlaceMenuItem>> _fetchMenuItems() async {
    if (placeKey.isEmpty) return const [];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('place_menus')
          .doc(placeKey)
          .collection('items')
          .limit(12)
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return PlaceMenuItem(
          name: (data['name'] ?? '').toString(),
          price: (data['price'] ?? '').toString(),
          photoUrl: (data['photoUrl'] ?? '').toString(),
          badge: (data['badge'] ?? '').toString(),
        );
      }).where((e) => e.name.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaceMenuItem>>(
      future: _fetchMenuItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <PlaceMenuItem>[];
        if (items.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: 'Mon nen thu', actionText: 'Menu full'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Dang cap nhat mon nen thu.',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            ],
          );
        }
        return _MustTrySection(items: items);
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final PlaceMenuItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: item.photoUrl.isNotEmpty
                  ? Image.network(item.photoUrl, fit: BoxFit.cover)
                  : Container(color: const Color(0xFF1F242C)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            item.price,
            style: const TextStyle(color: Color(0xFFFF6A00), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.hours,
    required this.amenities,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<String> hours;
  final List<String> amenities;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFF6A00)),
              const SizedBox(width: 8),
              Text('Thong tin quan', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          _HoursRow(
            hours: hours,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities.isEmpty
                ? [
                    _AmenityChip(text: 'May lanh'),
                    _AmenityChip(text: 'Chuyen khoan'),
                    _AmenityChip(text: 'Gui xe mien phi'),
                  ]
                : amenities.map((e) => _AmenityChip(text: e)).toList(),
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatefulWidget {
  const _HoursRow({
    required this.hours,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<String> hours;
  final Color textPrimary;
  final Color textSecondary;

  @override
  State<_HoursRow> createState() => _HoursRowState();
}

class _HoursRowState extends State<_HoursRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hours = widget.hours;
    final compact = hours.isEmpty ? 'Dang cap nhat gio mo cua' : hours.first;
    final canExpand = hours.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('Gio mo cua', style: TextStyle(color: widget.textSecondary, fontSize: 12)),
                const Spacer(),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: widget.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        Text(
          compact,
          style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.w600),
        ),
        if (_expanded && canExpand) ...[
          const SizedBox(height: 6),
          ...hours.skip(1).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(e, style: TextStyle(color: widget.textSecondary)),
                ),
              ),
        ],
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
    );
  }
}

class _MiniMapCard extends StatefulWidget {
  const _MiniMapCard({
    required this.cardBg,
    required this.borderColor,
    required this.lat,
    required this.lng,
  });

  final Color cardBg;
  final Color borderColor;
  final double lat;
  final double lng;

  @override
  State<_MiniMapCard> createState() => _MiniMapCardState();
}

class _MiniMapCardState extends State<_MiniMapCard> {
  MapLibreMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    if (widget.lat == 0 || widget.lng == 0) return;
    controller.addCircle(
      CircleOptions(
        geometry: LatLng(widget.lat, widget.lng),
        circleColor: '#FF6A00',
        circleRadius: 6,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lat == 0 || widget.lng == 0) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.borderColor),
        ),
        child: const Center(
          child: Text('Khong co toa do'),
        ),
      );
    }

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            MapLibreMap(
              styleString:
                  'https://tiles.goong.io/assets/goong_map_web.json?api_key=$goongMapApiKey',
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.lat, widget.lng),
                zoom: 15.2,
              ),
              onMapCreated: _onMapCreated,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationEnabled: false,
              compassEnabled: false,
              attributionButtonMargins: const Point(0, -1000),
              logoViewMargins: const Point(0, -1000),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place, size: 16, color: Color(0xFFFF6A00)),
                    SizedBox(width: 6),
                    Text('Mo ban do', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.reviews,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final List<SerpApiReview> reviews;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Danh gia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFFE0C2)),
              ),
              child: const Text('Viet danh gia', style: TextStyle(fontSize: 11, color: Color(0xFFFF6A00), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          Text('Chua co bai danh gia.', style: TextStyle(color: textSecondary))
        else
          ...reviews.map(
            (r) => _ReviewCard(
              review: r,
              cardBg: cardBg,
              borderColor: borderColor,
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.cardBg,
    required this.borderColor,
  });

  final SerpApiReview review;
  final Color cardBg;
  final Color borderColor;

  List<Widget> _buildStars(double rating) {
    final out = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      if (rating >= i) {
        out.add(const Icon(Icons.star, size: 14, color: Color(0xFFFF6A00)));
      } else if (rating >= i - 0.5) {
        out.add(const Icon(Icons.star_half, size: 14, color: Color(0xFFFF6A00)));
      } else {
        out.add(const Icon(Icons.star_border, size: 14, color: Color(0xFFFF6A00)));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final name = review.userName.isEmpty ? 'Nguoi dung' : review.userName;
    final subtitle = review.dateText.isNotEmpty
        ? '${review.dateText} • Da an o quan nay'
        : 'Da an o quan nay';
    final rating = review.rating;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE2E8F0),
                child: Text(name[0].toUpperCase()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(children: _buildStars(rating)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.text,
            style: TextStyle(color: textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border, size: 18),
              label: const Text('Luu'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Dat mon ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


