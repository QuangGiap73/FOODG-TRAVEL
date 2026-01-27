import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/places_model.dart';

class FavoritePlaceService {
  FavoritePlaceService._internal();
  static final FavoritePlaceService _instance = FavoritePlaceService._internal();
  factory FavoritePlaceService() => _instance;

  final _db = FirebaseFirestore.instance;
  // tạo collection rieng cho quan yeu thich
  CollectionReference<Map<String, dynamic>> _ref(String uid) {
    return _db.collection('users').doc(uid).collection('favorite_places');
  }
  // theo dõi realtime
  Stream<Set<String>> watchFavoriteIds(String uid){
    return _ref(uid).snapshots().map((snap) {
      return snap.docs.map((d)=> d.id).toSet();
    });
  }
  // bat tat tim khi user bam va kiem tra du lieu
  Future<void> toggleFavorite(
    String uid,
    GoongNearbyPlace place, {
    required String placeKey,
    }
  ) async {
    final docRef = _ref(uid).doc(placeKey);
    final doc =  await docRef.get();
    if (doc.exists) {
      await docRef.delete();
      return;
    }
    // lưu 1 bản snapshot để sau này hiện lại
    await docRef.set({
      'id': place.id,
      'name': place.name,
      'address': place.address,
      'lat': place.lat,
      'lng': place.lng,
      'photoUrl': place.photoUrl,
      'rating': place.rating,
      'reviewCount': place.reviewCount,
      'price': place.price,
      'phone': place.phone,
      'category': place.category,
      'isOpen': place.isOpen,
      'closingTime': place.closingTime,
      'createAt': FieldValue.serverTimestamp(),
    });
  }
}
// tạo khóa ổn định cho uán (ưu tiên id , fallback lat.lng)
String buildPlacekey(GoongNearbyPlace place){
  final rawId = place.id.trim();
  if(rawId.isNotEmpty) return rawId;

  final lat = place.lat.toStringAsFixed(5);
  final lng = place.lng.toStringAsFixed(5);
  final slug = place.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  return '${slug}_${lat}_$lng';
}
