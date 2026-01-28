import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/places_model.dart';

class FavoritePlaceService {
  FavoritePlaceService._internal();
  static final FavoritePlaceService _instance = FavoritePlaceService._internal();
  factory FavoritePlaceService() => _instance;

  final _db = FirebaseFirestore.instance;

  // Tao collection rieng cho quan yeu thich: users/{uid}/favorite_places
  CollectionReference<Map<String, dynamic>> _ref(String uid) {
    return _db.collection('users').doc(uid).collection('favorite_places');
  }

  // Theo doi realtime danh sach id (de check nhanh tren UI)
  Stream<Set<String>> watchFavoriteIds(String uid) {
    return _ref(uid).snapshots().map((snap) {
      return snap.docs.map((d) => d.id).toSet();
    });
  }

  // Theo doi realtime danh sach quan yeu thich (de hien thi danh sach)
  Stream<List<GoongNearbyPlace>> watchFavoritePlaces(String uid) {
    return _ref(uid).snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();

        // Map du lieu Firestore ve model GoongNearbyPlace
        return GoongNearbyPlace(
          id: (data['id'] ?? doc.id).toString(),
          name: (data['name'] ?? '').toString(),
          address: (data['address'] ?? '').toString(),
          lat: _toDouble(data['lat']),
          lng: _toDouble(data['lng']),
          photoUrl: (data['photoUrl'] ?? '').toString(),
          rating: _toDoubleOrNull(data['rating']),
          reviewCount: _toIntOrNull(data['reviewCount']),
          price: _toStringOrNull(data['price']),
          phone: _toStringOrNull(data['phone']),
          category: _toStringOrNull(data['category']),
          isOpen: data['isOpen'] is bool ? data['isOpen'] as bool : null,
          closingTime: _toStringOrNull(data['closingTime']),
        );
      }).toList();
    });
  }

  // Bat/tat tim yeu thich cho 1 quan
  Future<void> toggleFavorite(
    String uid,
    GoongNearbyPlace place, {
    required String placeKey,
  }) async {
    final docRef = _ref(uid).doc(placeKey);
    final doc = await docRef.get();

    if (doc.exists) {
      // Neu da ton tai thi xoa
      await docRef.delete();
      return;
    }

    // Neu chua co thi luu snapshot de hien thi nhanh
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
      // Luu ca 2 key de tranh lech ten truong trong tuong lai
      'createdAt': FieldValue.serverTimestamp(),
      'createAt': FieldValue.serverTimestamp(),
    });
  }
}

// Tao khoa on dinh cho quan (uu tien id, fallback lat/lng)
String buildPlacekey(GoongNearbyPlace place) {
  final rawId = place.id.trim();
  if (rawId.isNotEmpty) return rawId;

  final lat = place.lat.toStringAsFixed(5);
  final lng = place.lng.toStringAsFixed(5);
  final slug = place.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  return '${slug}_${lat}_$lng';
}

// Helper: parse double an toan, neu loi thi tra ve 0
double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

// Helper: parse double co the null (rating, v.v.)
double? _toDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// Helper: parse int co the null
int? _toIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

// Helper: parse string co the null
String? _toStringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

