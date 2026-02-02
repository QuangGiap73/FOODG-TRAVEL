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

  // Luu/cap nhat thong tin quan tu API vao collection places.
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

  // Lay review hien tai cua user cho 1 quan (neu da danh gia truoc do).
  Future<PlaceReviewModel?> getMyReview({
    required String placeId,
    required String userId,
  }) async {
    final doc = await _places
        .doc(placeId)
        .collection('reviews')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return PlaceReviewModel.fromDoc(doc);
  }

  // Them review moi va cap nhat avg_rating/review_count., 1 user chỉ 1review/quán 
  Future<void> upsertMyReview({
    required GoongNearbyPlace place,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    final placeId = placeIdOf(place);
    final placeRef = _places.doc(placeId);
    final reviewRef = placeRef.collection('reviews').doc(userId);

    await _db.runTransaction((tx) async{
      final placeSnap = await tx.get(placeRef);
      final reviewSnap = await tx.get(reviewRef);

      final placeData = placeSnap.data() ?? {};
      final oldCount = (placeData['review_count'] as num?)?.toInt() ?? 0;
      final oldAvg = (placeData['avg_rating'] as num?)?.toDouble() ?? 0.0;

      final existed = reviewSnap.exists;
      final oldRating = existed
          ? (reviewSnap.data()?['rating'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      late final int newCount;
      late final double newAvg;

      if(existed){
        newCount = oldCount;
        if (oldCount <=0){
          newAvg = rating;
        }else{
          newAvg = ((oldAvg * oldCount) - oldRating + rating) / oldCount;
        }
      }else {
        newCount = oldCount + 1;
        newAvg = ((oldAvg * oldCount) + rating) / newCount;
      }
      tx.set(reviewRef, {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': existed
          ? (reviewSnap.data()?['createdAt'] ?? FieldValue.serverTimestamp())
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    tx.set(placeRef, {
      'name': place.name,
      'address': place.address,
      'lat': place.lat,
      'lng': place.lng,
      'phone': place.phone ?? '',
      'category': place.category ?? '',
      'photoUrl': place.photoUrl,
      'avg_rating': newAvg < 0 ? 0.0 : newAvg,
      'review_count': newCount < 0 ? 0 : newCount,
      'createdAt': placeData['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    });
  }

    

  // Xoa review va cap nhat lai avg_rating/review_count trong 1 transaction.
  Future<void> deleteMyReview({
    required String placeId,
    required String userId,
  }) async {
    final placeRef = _places.doc(placeId);
    final reviewRef = placeRef.collection('reviews').doc(userId);

    await _db.runTransaction((tx) async {
      final placeSnap = await tx.get(placeRef);
      final reviewSnap = await tx.get(reviewRef);
      if (!reviewSnap.exists) return;

      final placeData = placeSnap.data() ?? {};
      final reviewData = reviewSnap.data() ?? {};

      final oldCount = (placeData['review_count'] as num?)?.toInt() ?? 0;
      final oldAvg = (placeData['avg_rating'] as num?)?.toDouble() ?? 0.0;
      final removedRating = (reviewData['rating'] as num?)?.toDouble() ?? 0.0;

      final newCount = oldCount - 1;
      final newAvg = newCount > 0
          ? ((oldAvg * oldCount) - removedRating) / newCount
          : 0.0;
      tx.delete(reviewRef);
      tx.set(placeRef,{
        'avg_rating': newAvg < 0 ? 0.0 : newAvg,
        'review_count': newCount < 0 ? 0 : newCount,
        'updatedAt' : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    });
  }
}
