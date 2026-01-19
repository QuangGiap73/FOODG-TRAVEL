import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:food_travel/services/favorite_service.dart';
class FavoriteController extends ChangeNotifier {
  FavoriteController() : _service = FavoriteService();

  final FavoriteService _service;
  StreamSubscription<Set<String>>? _sub;
  Set<String> _favoriteIds = {};
  String? _uid;

  Set<String> get favoriteIds => _favoriteIds; // expose ra ngoai nhung khong cho set truc tiep

  void bindUser(String? uid) {
    if (_uid == uid) return;
    // neu doi user thi reset
    _uid = uid;
    _sub?.cancel();
    _favoriteIds = {};
    if(uid == null){
      notifyListeners();
      return;
    }
    _sub = _service.watchFavoriteIds(uid).listen((ids){
      _favoriteIds = ids;
      notifyListeners();
    });
  }
    bool isFavorite(String dishId) => _favoriteIds.contains(dishId); // check nhanh UI

  // chua login thi khong day
  Future<void> toggleFavorite(String dishId) async {
    final uid = _uid;
    if (uid == null ) return;
    await _service.toggleFavorite(uid, dishId);
  }
  @override
  void dispose(){
    _sub?.cancel();
    super.dispose();
  }

}
