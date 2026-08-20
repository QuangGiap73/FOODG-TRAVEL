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
    String languageCode = 'vi',
  }) {
    var score = 0;
    final reasons = <String>[];

    final dishIngredients = IngredientAliasUtils.canonicalizeDishIngredients(
      dish.ingredientsListNormalized,
    );
    if (dishIngredients.intersection(profile.avoidIngredients).isNotEmpty ||
        _containsAvoidedIngredientInDishText(dish, profile.avoidIngredients)) {
      return DishScore(
        dish: dish,
        value: -10000,
        reasons: [
          _localized(
            languageCode,
            vi: 'Trùng nguyên liệu cần tránh',
            en: 'Contains an ingredient you avoid',
          ),
        ],
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
        reasons: [
          _localized(
            languageCode,
            vi: 'Không đúng kiểu món đã chọn',
            en: 'Does not match your preferred dish type',
          ),
        ],
        blocked: true,
      );
    }

    final spiceScore =
        max(0, 5 - (dish.spicyLevel - profile.spicyLevel).abs()) * 8;
    score += spiceScore;
    if (spiceScore >= 32) {
      reasons.add(
        _localized(
          languageCode,
          vi: 'Độ cay phù hợp',
          en: 'Matches your spice preference',
        ),
      );
    }

    final satietyScore =
        max(0, 5 - (dish.satietyLevel - profile.satietyLevel).abs()) * 7;
    score += satietyScore;
    if (satietyScore >= 28) {
      reasons.add(
        _localized(
          languageCode,
          vi: 'Độ no phù hợp',
          en: 'Matches your preferred portion',
        ),
      );
    }

    final dishTypeScore = _overlapScore(
      dishTypes,
      profile.preferredDishTypes,
      28,
    );
    score += dishTypeScore;
    if (dishTypeScore > 0) {
      reasons.add(
        _localized(
          languageCode,
          vi: 'Đúng kiểu món yêu thích',
          en: 'A dish type you enjoy',
        ),
      );
    }

    final mealTimes = _normalizedSet(dish.mealTimeTags);
    final mealPreferenceScore = _overlapScore(
      mealTimes,
      profile.preferredMealTimes,
      16,
    );
    score += mealPreferenceScore;
    if (mealPreferenceScore > 0) {
      reasons.add(
        _localized(
          languageCode,
          vi: 'Đúng thời điểm ăn đã chọn',
          en: 'Matches your preferred mealtime',
        ),
      );
    }

    if (mealTimes.contains(context.mealTime)) {
      score += 34;
      reasons.add(
        _localized(
          languageCode,
          vi: 'Phù hợp thời điểm hiện tại',
          en: 'Perfect for this time of day',
        ),
      );
    } else if (mealTimes.isNotEmpty) {
      score -= 60;
    }

    final seasons = _normalizedSet(dish.suitableForSeason);
    if (seasons.contains('all_season')) {
      score += 12;
      reasons.add(
        _localized(
          languageCode,
          vi: 'Phù hợp quanh năm',
          en: 'Great all year round',
        ),
      );
    } else if (seasons.contains(context.season)) {
      score += 22;
      reasons.add(
        _localized(languageCode, vi: 'Hợp mùa hiện tại', en: 'In season now'),
      );
    }

    final seasonPreferenceScore = _overlapScore(
      seasons,
      profile.preferredSeasons,
      14,
    );
    score += seasonPreferenceScore;
    if (seasonPreferenceScore > 0) {
      reasons.add(
        _localized(
          languageCode,
          vi: 'Đúng mùa bạn đã chọn',
          en: 'Matches your preferred season',
        ),
      );
    }

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
        reasons.add(
          _localized(
            languageCode,
            vi: 'Gần với từ khóa yêu thích',
            en: 'Matches your favorite keywords',
          ),
        );
      }
    }

    return DishScore(dish: dish, value: score, reasons: reasons);
  }

  int _overlapScore(
    Set<String> dishValues,
    Set<String> profileValues,
    int weight,
  ) {
    if (profileValues.isEmpty) return 0;
    return dishValues.intersection(profileValues).length * weight;
  }

  Set<String> _normalizedSet(Iterable<String> values) {
    return values
        .map(RecommendationTextUtils.normalizeToken)
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  bool _containsAvoidedIngredientInDishText(
    DishModel dish,
    Set<String> avoidIngredients,
  ) {
    if (avoidIngredients.isEmpty) return false;

    // Một số món cũ chưa có ingredientsListNormalized. Dùng thêm tên và
    // nguyên liệu đa ngôn ngữ làm nguồn dự phòng để điều kiện an toàn không
    // phụ thuộc hoàn toàn vào việc dữ liệu Firestore đã được chuẩn hóa hay chưa.
    final searchableText = [
      dish.name,
      dish.ingredients,
      ...dish.nameI18n.values,
      ...dish.ingredientsI18n.values,
      ...dish.ingredientsListNormalized,
    ].where((value) => value.trim().isNotEmpty).join(' ');
    final normalized = RecommendationTextUtils.normalizeToken(searchableText);
    if (normalized.isEmpty) return false;

    // Bọc dấu gạch dưới để so khớp theo từ/cụm từ hoàn chỉnh: "ga" sẽ khớp
    // "thit ga" nhưng không khớp nhầm một phần của từ "gao".
    final haystack = '_${normalized}_';
    for (final avoided in avoidIngredients) {
      final token = RecommendationTextUtils.normalizeToken(avoided);
      if (token.isNotEmpty && haystack.contains('_${token}_')) return true;
    }
    return false;
  }

  String _localized(
    String languageCode, {
    required String vi,
    required String en,
  }) {
    return languageCode.toLowerCase().startsWith('en') ? en : vi;
  }
}
