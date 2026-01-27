import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/places_model.dart';
import '../../services/restaurants/favorite_place_service.dart';

class PlaceFavoriteController extends ChangeNotifier {
  PlaceFavoriteController() : _service = FavoritePlaceService();

  final FavoritePlaceService _service;

  StreamSubscription<Set<String>>? _sub;
  String? _uid;
  Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;
  void bindUser(String? uid){
    if(_uid == uid) return;

    // doi user thi resset va bind lai stream
    _uid = uid;
    _sub?.cancel();
    _favoriteIds = {};
    
    if (uid == null){
      notifyListeners();
      return;
    }
    _sub = _service.watchFavoriteIds(uid).listen((ids){
      _favoriteIds = ids;
      notifyListeners();
    });
  }
  String keyOf(GoongNearbyPlace place) => buildPlacekey(place);

  bool isFavorite(GoongNearbyPlace place){
    final key = keyOf(place);
    return _favoriteIds.contains(key);
  }
  Future<void> toggle(GoongNearbyPlace place) async {
    final uid = _uid;
    if(uid == null) return;

    final key = keyOf(place);
    await _service.toggleFavorite(uid, place, placeKey: key);
  }
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}