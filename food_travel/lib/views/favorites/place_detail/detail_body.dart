import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/places_model.dart';
import '../../../services/map/serpapi_places_service.dart';
import 'hero_header.dart';
import 'summary_card.dart';
import 'photo_thumb_list.dart';
import 'menu_sections.dart';
import 'info_section.dart';
import 'mini_map_card.dart';
import 'reviews_section.dart';

class PlaceDetailBody extends StatefulWidget {
  const PlaceDetailBody({super.key, required this.place, required this.reviews});

  final GoongNearbyPlace place;
  final List<SerpApiReview> reviews;

  @override
  State<PlaceDetailBody> createState() => _PlaceDetailBodyState();
}

class _PlaceDetailBodyState extends State<PlaceDetailBody> {
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
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
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
        PlaceHeroHeader(
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
            child: PlaceSummaryCard(
              name: name,
              place: place,
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
            child: PhotoThumbList(
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
          MustTrySection(items: mustTry)
        else
          MenuHighlightsSection(
            placeKey: placeKey,
            textSecondary: textSecondary,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: PlaceInfoSection(
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
          child: PlaceMiniMapCard(
            cardBg: cardBg,
            borderColor: borderColor,
            lat: place.lat,
            lng: place.lng,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: PlaceReviewsSection(
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



