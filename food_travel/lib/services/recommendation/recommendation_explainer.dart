import 'dish_score.dart';
import 'recommendation_context.dart';

class RecommendationExplainer {
  const RecommendationExplainer();

  String explain(
    DishScore score,
    RecommendationContext context, {
    String languageCode = 'vi',
  }) {
    if (score.reasons.isEmpty) {
      return languageCode.toLowerCase().startsWith('en')
          ? 'A good match for your preferences and the current time.'
          : 'Phù hợp với sở thích và thời điểm hiện tại.';
    }
    return score.reasons.take(3).join(', ');
  }
}
