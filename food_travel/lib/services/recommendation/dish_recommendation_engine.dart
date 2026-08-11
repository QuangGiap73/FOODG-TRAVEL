import 'dart:math';

import '../../models/dish_model.dart';
import '../../models/user_preferences.dart';
import 'dish_score.dart';
import 'dish_scoring_engine.dart';
import 'recommendation_context.dart';
import 'recommendation_explainer.dart';
import 'recommendation_profile.dart';
import 'recommended_dish.dart';

class DishRecommendationEngine {
  const DishRecommendationEngine({
    this.scoringEngine = const DishScoringEngine(),
    this.explainer = const RecommendationExplainer(),
  });

  final DishScoringEngine scoringEngine;
  final RecommendationExplainer explainer;

  List<RecommendedDish> recommendTodayWithReasons({
    required List<DishModel> dishes,
    required UserPreferences? preferences,
    required DateTime now,
    int limit = 12,
    String languageCode = 'vi',
  }) {
    if (dishes.isEmpty) return const [];
    final context = RecommendationContext.fromDateTime(now);

    if (preferences == null) {
      return _stableShuffle(dishes, now)
          .take(limit)
          .map(
            (dish) => RecommendedDish(
              dish: dish,
              score: 0,
              explanation:
                  languageCode.toLowerCase().startsWith('en')
                      ? 'A discovery pick for you today.'
                      : 'Gợi ý khám phá dành cho bạn hôm nay.',
            ),
          )
          .toList();
    }

    final profile = RecommendationProfile.fromPreferences(preferences);
    final scores =
        dishes
            .map(
              (dish) => scoringEngine.score(
                dish: dish,
                profile: profile,
                context: context,
                languageCode: languageCode,
              ),
            )
            .where((score) => !score.blocked)
            .toList()
          ..sort(_compareScores);

    return scores
        .take(limit)
        .map(
          (score) => RecommendedDish(
            dish: score.dish,
            score: score.value,
            explanation: explainer.explain(
              score,
              context,
              languageCode: languageCode,
            ),
          ),
        )
        .toList();
  }

  List<DishModel> recommendToday({
    required List<DishModel> dishes,
    required UserPreferences? preferences,
    required DateTime now,
    int limit = 12,
    String languageCode = 'vi',
  }) {
    return recommendTodayWithReasons(
      dishes: dishes,
      preferences: preferences,
      now: now,
      limit: limit,
      languageCode: languageCode,
    ).map((item) => item.dish).toList();
  }

  int _compareScores(DishScore a, DishScore b) {
    final scoreCompare = b.value.compareTo(a.value);
    if (scoreCompare != 0) return scoreCompare;
    return a.dish.getName('vi').compareTo(b.dish.getName('vi'));
  }

  List<DishModel> _stableShuffle(List<DishModel> dishes, DateTime now) {
    final seed = '${now.year}-${now.month}-${now.day}'.hashCode;
    final random = Random(seed);
    final pool = List<DishModel>.from(dishes);
    for (var i = pool.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = pool[i];
      pool[i] = pool[j];
      pool[j] = temp;
    }
    return pool;
  }
}
