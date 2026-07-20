import '../../models/dish_model.dart';

class DishScore {
  const DishScore({
    required this.dish,
    required this.value,
    this.reasons = const [],
    this.blocked = false,
  });

  final DishModel dish;
  final int value;
  final List<String> reasons;
  final bool blocked;
}
