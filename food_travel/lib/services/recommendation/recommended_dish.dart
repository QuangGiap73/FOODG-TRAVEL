import '../../models/dish_model.dart';

class RecommendedDish {
  const RecommendedDish({
    required this.dish,
    required this.score,
    required this.explanation,
  });

  final DishModel dish;
  final int score;
  final String explanation;
}
