import 'dish_score.dart';
import 'recommendation_context.dart';

class RecommendationExplainer {
  const RecommendationExplainer();

  String explain(DishScore score, RecommendationContext context) {
    if (score.reasons.isEmpty) {
      return 'Món ăn phù hợp tổng thể với thời điểm ${context.mealTime}.';
    }
    return score.reasons.take(3).join(', ');
  }
}
