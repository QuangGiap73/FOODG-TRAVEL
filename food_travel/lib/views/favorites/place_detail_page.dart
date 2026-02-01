import 'package:flutter/material.dart';

import '../../models/places_model.dart';
import '../../services/map/serpapi_places_service.dart';
import 'place_detail/detail_body.dart';
import 'place_detail/sticky_action_bar.dart';

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
                return PlaceDetailBody(place: detail, reviews: reviews);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const PlaceStickyActionBar(),
    );
  }
}
