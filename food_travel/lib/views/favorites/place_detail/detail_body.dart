import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../models/places_model.dart';
import '../../../services/map/serpapi_places_service.dart';
import '../../../controller/restaurants/place_favorite_controller.dart';
import '../../../services/restaurants/place_review_service.dart';
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
  final _reviewService = PlaceReviewService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Luu thong tin quan vao Firestore ngay khi mo trang chi tiet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reviewService.upsertPlaceFromApi(widget.place);
    });

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

  Future<void> _showWriteReviewSheet(GoongNearbyPlace place) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    double rating = 5;
    final commentCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF15181E) : Colors.white;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (localContext, setLocalState) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Viet danh gia',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final star = i + 1;
                            return IconButton(
                              onPressed: () {
                                setLocalState(() => rating = star.toDouble());
                              },
                              icon: Icon(
                                star <= rating ? Icons.star : Icons.star_border,
                                color: const Color(0xFFFF6A00),
                              ),
                            );
                          }),
                        ),
                        TextField(
                          controller: commentCtrl,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Nhap nhan xet cua ban...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                child: const Text('Huy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final comment = commentCtrl.text.trim();
                                  if (comment.isEmpty) return;

                                  await _reviewService.addReview(
                                    place: place,
                                    userId: user.uid,
                                    userName: user.displayName ?? 'Nguoi dung',
                                    userAvatar: user.photoURL ?? '',
                                    rating: rating,
                                    comment: comment,
                                  );
                                  if (!mounted) return;
                                  // Dong ban phim truoc khi dong sheet de tranh loi
                                  // "TextEditingController used after disposed".
                                  FocusScope.of(sheetContext).unfocus();
                                  Navigator.pop(sheetContext);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6A00),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Gui'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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

    final fav = context.watch<PlaceFavoriteController>(); // yeu thich mon ăn
    final isFavorive = fav.isFavorite(place);

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

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
            children: [
              PlaceHeroHeader(
                photoUrls: photos,
                isOpen: isOpen,
                closingTime: closingTime,
                controller: _pageController,
                onIndexChanged: (idx) => setState(() => _pageIndex = idx),
                onTapImage: (idx) => _openGallery(context, photos, idx),
                isFavorite: isFavorive,
                onToggleFavorite: () => fav.toggle(place),
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
                  place: place,
                  reviews: reviews,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onWriteReview: () => _showWriteReviewSheet(place),
                ),
              ),
              const SizedBox(height: 110),
            ],
        ),
        // thanh icon cố định phía trên
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
                  _CircleIcon(
                    icon: isFavorive ? Icons.favorite : Icons.favorite_border,
                    color: isFavorive ? Colors.red : Colors.white,
                    onTap: () => fav.toggle(place),

                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap, this.color = Colors.white});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

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
        child: Icon(icon, color: color),
      ),
    );
  }
}




