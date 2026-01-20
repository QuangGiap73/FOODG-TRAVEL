import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/dish_model.dart';
import '../../services/food_service.dart';

class DishDetailController  extends ChangeNotifier{
  DishDetailController() : _service = FoodService();
  final FoodService _service;
  StreamSubscription<DishModel?>? _sub;

  DishModel? dish;
  bool isLoading = false;
  String? error;
  String? _dishId;

  void bind(String dishId){
    if(_dishId == dishId && _sub != null ) return;
    _dishId = dishId;

    _sub?.cancel();
    dish = null;
    isLoading = true;
    error = null;
    notifyListeners();

    _sub = _service.watchDishById(dishId).listen(
      (data) {
        dish = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (e,st){
        if(kDebugMode){
          print('DishDetailController error: $e');
        }
        error = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}