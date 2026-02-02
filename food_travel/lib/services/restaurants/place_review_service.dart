import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/places_model.dart';
import '../../models/place_review_model.dart';

class PlaceReviewService {
  PlaceReviewService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _places =>
      _db.collection('places');

  String placeIdOf(GoongNearbyPlace p) {
    if (p.serpDataId.trim().isNotEmpty) return p.serpDataId.trim();
    if (p.id.trim().isNotEmpty) return p.id.trim();
    return '${p.name.trim()}_${p.lat}_${p.lng}'.replaceAll(' ', '_');
  }

  Future<void> upsertPlaceFromApi(GoongNearbyPlace p) async {
    final placeId = placeIdOf(p);
    await _places.doc(placeId).set({
      'name': p.name,
      'address': p.address,
      'lat': p.lat,
      'lng': p.lng,
      'phone': p.phone ?? '',
      'category': p.category ?? '',
      'photoUrl': p.photoUrl,
      'avg_rating': (p.rating ?? 0).toDouble(),
      'review_count': p.reviewCount ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<PlaceReviewModel>> watchReviews(String placeId) {
    return _places
        .doc(placeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PlaceReviewModel.fromDoc).toList());
  }

  Future<void> addReview({
    required GoongNearbyPlace place,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    final placeId = placeIdOf(place);
    final placeRef = _places.doc(placeId);
    final reviewRef = placeRef.collection('reviews').doc();

    final review = PlaceReviewModel(
      id: reviewRef.id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await _db.runTransaction((tx) async {
      final snap = await tx.get(placeRef);
      final data = snap.data() ?? {};

      final oldCount = (data['review_count'] as num?)?.toInt() ?? 0;
      final oldAvg = (data['avg_rating'] as num?)?.toDouble() ?? 0.0;
      final newCount = oldCount + 1;
      final newAvg = ((oldAvg * oldCount) + rating) / newCount;

      tx.set(reviewRef, review.toJson());
      tx.set(
        placeRef,
        {
          'name': place.name,
          'address': place.address,
          'lat': place.lat,
          'lng': place.lng,
          'phone': place.phone ?? '',
          'category': place.category ?? '',
          'photoUrl': place.photoUrl,
          'avg_rating': newAvg,
          'review_count': newCount,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
