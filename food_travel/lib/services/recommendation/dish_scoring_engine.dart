import 'dart:math';

import '../../models/dish_model.dart';
import 'dish_score.dart';
import 'ingredient_alias_utils.dart';
import 'recommendation_context.dart';
import 'recommendation_profile.dart';
import 'recommendation_text_utils.dart';

class DishScoringEngine {
  const DishScoringEngine();

  DishScore score({
    required DishModel dish,
    required RecommendationProfile profile,
    required RecommendationContext context,
  }) {
    var score = 0;
    final reasons = <String>[];

    final dishIngredients = IngredientAliasUtils.expand(
      dish.ingredientsListNormalized,
    );
    if (dishIngredients.intersection(profile.avoidIngredients).isNotEmpty) {
      return DishScore(
        dish: dish,
        value: -10000,
        reasons: const ['Trung nguyen lieu can tranh'],
        blocked: true,
      );
    }

    final dishTypes = _normalizedSet(dish.dishTypeCodes);
    if (profile.preferredDishTypes.isNotEmpty &&
        dishTypes.isNotEmpty &&
        dishTypes.intersection(profile.preferredDishTypes).isEmpty) {
      return DishScore(
        dish: dish,
        value: -10000,
        reasons: const ['Khong dung kieu mon da chon'],
        blocked: true,
      );
    }

    final spiceScore = max(0, 5 - (dish.spicyLevel - profile.spicyLevel).abs()) * 8;
    score += spiceScore;
    if (spiceScore >= 32) reasons.add('Do cay phu hop');

    final satietyScore =
        max(0, 5 - (dish.satietyLevel - profile.satietyLevel).abs()) * 7;
    score += satietyScore;
    if (satietyScore >= 28) reasons.add('Do no phu hop');

    final dishTypeScore = _overlapScore(dishTypes, profile.preferredDishTypes, 28);
    score += dishTypeScore;
    if (dishTypeScore > 0) reasons.add('Dung kieu mon yeu thich');

    final mealTimes = _normalizedSet(dish.mealTimeTags);
    final mealPreferenceScore =
        _overlapScore(mealTimes, profile.preferredMealTimes, 16);
    score += mealPreferenceScore;
    if (mealPreferenceScore > 0) reasons.add('Dung thoi diem an da chon');

    if (mealTimes.contains(context.mealTime)) {
      score += 34;
      reasons.add('Phu hop thoi diem hien tai');
    } else if (mealTimes.isNotEmpty) {
      score -= 60;
    }

    final seasons = _normalizedSet(dish.suitableForSeason);
    if (seasons.contains('all_season')) {
      score += 12;
      reasons.add('Phu hop quanh nam');
    } else if (seasons.contains(context.season)) {
      score += 22;
      reasons.add('Hop mua hien tai');
    }

    final seasonPreferenceScore =
        _overlapScore(seasons, profile.preferredSeasons, 14);
    score += seasonPreferenceScore;
    if (seasonPreferenceScore > 0) reasons.add('Dung mua nguoi dung chon');

    if (profile.preferredSeasons.isNotEmpty &&
        seasons.isNotEmpty &&
        !seasons.contains('all_season') &&
        seasons.intersection(profile.preferredSeasons).isEmpty) {
      score -= 35;
    }

    final searchable = RecommendationTextUtils.normalizeText(
      [
        dish.name,
        dish.description,
        dish.ingredients,
        dish.tag,
        ...dish.tags,
      ].join(' '),
    );
    for (final token in profile.favoriteTokens) {
      if (token.isNotEmpty && searchable.contains(token)) {
        score += 10;
        reasons.add('Gan voi tu khoa yeu thich');
      }
    }

    return DishScore(dish: dish, value: score, reasons: reasons);
  }

  int _overlapScore(Set<String> dishValues, Set<String> profileValues, int weight) {
    if (profileValues.isEmpty) return 0;
    return dishValues.intersection(profileValues).length * weight;
  }

  Set<String> _normalizedSet(Iterable<String> values) {
    return values
        .map(RecommendationTextUtils.normalizeToken)
        .where((value) => value.isNotEmpty)
        .toSet();
  }
}
