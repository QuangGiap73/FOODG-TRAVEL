class RecommendationContext {
  const RecommendationContext({
    required this.now,
    required this.mealTime,
    required this.season,
  });

  final DateTime now;
  final String mealTime;
  final String season;

  factory RecommendationContext.fromDateTime(DateTime now) {
    return RecommendationContext(
      now: now,
      mealTime: _mealTimeFor(now),
      season: _seasonFor(now),
    );
  }

  static String _mealTimeFor(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 10) return 'breakfast';
    if (hour >= 10 && hour < 14) return 'lunch';
    if (hour >= 14 && hour < 17) return 'snack';
    if (hour >= 17 && hour < 21) return 'dinner';
    return 'late_night';
  }

  static String _seasonFor(DateTime now) {
    switch (now.month) {
      case 2:
      case 3:
      case 4:
        return 'spring';
      case 5:
      case 6:
      case 7:
        return 'summer';
      case 8:
      case 9:
      case 10:
        return 'autumn';
      default:
        return 'winter';
    }
  }
}
