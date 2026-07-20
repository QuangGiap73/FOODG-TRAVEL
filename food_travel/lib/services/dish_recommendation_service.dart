export 'recommendation/dish_recommendation_engine.dart'
    show DishRecommendationEngine;
export 'recommendation/recommended_dish.dart' show RecommendedDish;

import '../models/dish_model.dart';
import '../models/user_preferences.dart';
import 'recommendation/dish_recommendation_engine.dart';
import 'recommendation/recommended_dish.dart';

class DishRecommendationService {
  const DishRecommendationService({
    this.engine = const DishRecommendationEngine(),
  });

  final DishRecommendationEngine engine;

  List<DishModel> recommendToday({
    required List<DishModel> dishes,
    required UserPreferences? preferences,
    required DateTime now,
    int limit = 12,
  }) {
    return engine.recommendToday(
      dishes: dishes,
      preferences: preferences,
      now: now,
      limit: limit,
    );
  }

  List<RecommendedDish> recommendTodayWithReasons({
    required List<DishModel> dishes,
    required UserPreferences? preferences,
    required DateTime now,
    int limit = 12,
  }) {
    return engine.recommendTodayWithReasons(
      dishes: dishes,
      preferences: preferences,
      now: now,
      limit: limit,
    );
  }
}
