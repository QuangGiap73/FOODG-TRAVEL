import '../../models/user_preferences.dart';
import 'ingredient_alias_utils.dart';
import 'recommendation_text_utils.dart';

class RecommendationProfile {
  const RecommendationProfile({
    required this.spicyLevel,
    required this.satietyLevel,
    required this.preferredDishTypes,
    required this.preferredMealTimes,
    required this.preferredSeasons,
    required this.avoidIngredients,
    required this.favoriteTokens,
  });

  final int spicyLevel;
  final int satietyLevel;
  final Set<String> preferredDishTypes;
  final Set<String> preferredMealTimes;
  final Set<String> preferredSeasons;
  final Set<String> avoidIngredients;
  final List<String> favoriteTokens;

  factory RecommendationProfile.fromPreferences(UserPreferences preferences) {
    return RecommendationProfile(
      spicyLevel: preferences.spicyLevel.clamp(0, 5).toInt(),
      satietyLevel: preferences.satietyPreference.clamp(0, 5).toInt(),
      preferredDishTypes: _normalizeSet(preferences.preferredDishTypes),
      preferredMealTimes: _normalizeSet(preferences.preferredMealTimes),
      preferredSeasons: _normalizeSet(preferences.preferredSeasons),
      avoidIngredients: IngredientAliasUtils.expand([
        ...preferences.allergies,
        ...preferences.dislikedIngredients,
      ]),
      favoriteTokens:
          preferences.favoriteTags
              .map(RecommendationTextUtils.normalizeText)
              .where((value) => value.isNotEmpty)
              .toList(),
    );
  }

  static Set<String> _normalizeSet(Iterable<String> values) {
    return values
        .map(RecommendationTextUtils.normalizeToken)
        .where((value) => value.isNotEmpty)
        .toSet();
  }
}
