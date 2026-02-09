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
              future: _fetchSerpReviews(detail),
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

Future<List<SerpApiReview>> _fetchSerpReviews(GoongNearbyPlace place) async {
  final service = SerpApiPlacesService();
  final dataId = await _resolveReviewDataId(place, service);
  if (dataId.isEmpty) return const <SerpApiReview>[];
  return service.fetchReviews(dataId: dataId, limit: 8);
}

Future<String> _resolveReviewDataId(
  GoongNearbyPlace place,
  SerpApiPlacesService service,
) async {
  final direct = place.serpDataId.trim();
  if (direct.isNotEmpty) return direct;

  // Neu chua co data_id thi thu tim bang searchNearby
  final name = place.name.trim();
  if (name.isEmpty || place.lat == 0 || place.lng == 0) return '';

  final query = place.address.trim().isNotEmpty
      ? '$name ${place.address.trim()}'
      : name;
  final results = await service.searchNearby(
    lat: place.lat,
    lng: place.lng,
    query: query,
    radius: 3000,
    limit: 1,
  );
  if (results.isEmpty) return '';
  return results.first.serpDataId.trim();
}
