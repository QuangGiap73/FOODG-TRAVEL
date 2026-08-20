import 'package:flutter_test/flutter_test.dart';
import 'package:food_travel/models/dish_model.dart';
import 'package:food_travel/models/user_preferences.dart';
import 'package:food_travel/services/recommendation/dish_recommendation_engine.dart';

DishModel _dish({
  required String id,
  required String name,
  String ingredients = '',
  List<String> normalizedIngredients = const [],
}) {
  return DishModel(
    id: id,
    name: name,
    imageUrl: '',
    provinceCode: 'ha_noi',
    tag: 'Món Việt',
    spicyLevel: 0,
    ingredients: ingredients,
    nameI18n: {'vi': name, 'en': name},
    ingredientsI18n: {'vi': ingredients, 'en': ingredients},
    // Mô phỏng dữ liệu món cũ chưa có danh sách nguyên liệu chuẩn hóa.
    ingredientsListNormalized: normalizedIngredients,
  );
}

void main() {
  const engine = DishRecommendationEngine();

  test('loại món theo dị ứng ngay cả khi dữ liệu chuẩn hóa bị thiếu', () {
    final dishes = [
      _dish(id: 'bun-rieu', name: 'Bún riêu'),
      _dish(id: 'chicken', name: 'Cơm gà', ingredients: 'Thịt gà, cơm'),
      _dish(id: 'safe', name: 'Chè sen', ingredients: 'Hạt sen, đường'),
    ];

    final result = engine.recommendTodayWithReasons(
      dishes: dishes,
      preferences: const UserPreferences(allergies: ['bún', 'gà']),
      now: DateTime(2026, 8, 15, 12),
    );

    expect(result.map((item) => item.dish.id), ['safe']);
  });

  test('đối chiếu bí danh cụ thể mà không mở rộng sai nhóm tổng quát', () {
    final dishes = [
      _dish(id: 'bun', name: 'Bún riêu'),
      _dish(
        id: 'rice',
        name: 'Cơm sen',
        normalizedIngredients: const ['com', 'hat_sen'],
      ),
      _dish(
        id: 'shrimp',
        name: 'Tôm hấp',
        normalizedIngredients: const ['tom'],
      ),
    ];

    final result = engine.recommendTodayWithReasons(
      dishes: dishes,
      preferences: const UserPreferences(allergies: ['bún']),
      now: DateTime(2026, 8, 15, 12),
    );

    expect(result.map((item) => item.dish.id), containsAll(['rice', 'shrimp']));
    expect(result.map((item) => item.dish.id), isNot(contains('bun')));
  });
}
