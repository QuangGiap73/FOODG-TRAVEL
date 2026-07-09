class UserPreferences {
  final String? provinceCode;
  final String? provinceName;
  final String? legacyProvinceCode;
  final int spicyLevel;
  final List<String> favoriteTags;
  final List<String> dislikedIngredients;
  final List<String> preferredDishTypes;
  final List<String> flavorPreferences;
  final int satietyPreference;
  final List<String> preferredMealTimes;
  final List<String> preferredRegions;
  final List<String> allergies;
  final List<String> dietPreferences;
  final int budgetMin;
  final int budgetMax;
  final int discoveryLevel;
  final List<String> diningContexts;
  final List<String> recommendationGoals;
  final int surveyVersion;

  const UserPreferences({
    this.provinceCode,
    this.provinceName,
    this.legacyProvinceCode,
    this.spicyLevel = 0,
    this.favoriteTags = const [],
    this.dislikedIngredients = const [],
    this.preferredDishTypes = const [],
    this.flavorPreferences = const [],
    this.satietyPreference = 1,
    this.preferredMealTimes = const [],
    this.preferredRegions = const [],
    this.allergies = const [],
    this.dietPreferences = const [],
    this.budgetMin = 0,
    this.budgetMax = 0,
    this.discoveryLevel = 3,
    this.diningContexts = const [],
    this.recommendationGoals = const [],
    this.surveyVersion = 2,
  });

  Map<String, dynamic> toMap() {
    return {
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'provinceCode34': provinceCode,
      'provinceName34': provinceName,
      'legacyProvinceCode': legacyProvinceCode,
      'spicyLevel': spicyLevel,
      'favoriteTags': favoriteTags,
      'dislikedIngredients': dislikedIngredients,
      'preferredDishTypes': preferredDishTypes,
      'flavorPreferences': flavorPreferences,
      'satietyPreference': satietyPreference,
      'preferredMealTimes': preferredMealTimes,
      'preferredRegions': preferredRegions,
      'allergies': allergies,
      'dietPreferences': dietPreferences,
      'budgetPreference': {
        'min': budgetMin,
        'max': budgetMax,
      },
      'discoveryLevel': discoveryLevel,
      'diningContexts': diningContexts,
      'recommendationGoals': recommendationGoals,
      'surveyVersion': surveyVersion,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPreferences();
    final budgetMap = map['budgetPreference'];
    final budgetMin = budgetMap is Map<String, dynamic>
        ? (budgetMap['min'] as num?)?.toInt() ?? 0
        : 0;
    final budgetMax = budgetMap is Map<String, dynamic>
        ? (budgetMap['max'] as num?)?.toInt() ?? 0
        : 0;

    return UserPreferences(
      provinceCode: (map['provinceCode34'] ?? map['provinceCode']) as String?,
      provinceName: (map['provinceName34'] ?? map['provinceName']) as String?,
      legacyProvinceCode: map['legacyProvinceCode'] as String?,
      spicyLevel: (map['spicyLevel'] as num?)?.toInt() ?? 0,
      favoriteTags: _toStringList(map['favoriteTags'] ?? map['favoritetags']),
      dislikedIngredients: _toStringList(map['dislikedIngredients']),
      preferredDishTypes: _toStringList(map['preferredDishTypes']),
      flavorPreferences: _toStringList(map['flavorPreferences']),
      satietyPreference: (map['satietyPreference'] as num?)?.toInt() ?? 1,
      preferredMealTimes: _toStringList(map['preferredMealTimes']),
      preferredRegions: _toStringList(map['preferredRegions']),
      allergies: _toStringList(map['allergies']),
      dietPreferences: _toStringList(map['dietPreferences']),
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      discoveryLevel: (map['discoveryLevel'] as num?)?.toInt() ?? 3,
      diningContexts: _toStringList(map['diningContexts']),
      recommendationGoals: _toStringList(map['recommendationGoals']),
      surveyVersion: (map['surveyVersion'] as num?)?.toInt() ?? 1,
    );
  }

  UserPreferences copyWith({
    String? provinceCode,
    String? provinceName,
    String? legacyProvinceCode,
    int? spicyLevel,
    List<String>? favoriteTags,
    List<String>? dislikedIngredients,
    List<String>? preferredDishTypes,
    List<String>? flavorPreferences,
    int? satietyPreference,
    List<String>? preferredMealTimes,
    List<String>? preferredRegions,
    List<String>? allergies,
    List<String>? dietPreferences,
    int? budgetMin,
    int? budgetMax,
    int? discoveryLevel,
    List<String>? diningContexts,
    List<String>? recommendationGoals,
    int? surveyVersion,
  }) {
    return UserPreferences(
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      legacyProvinceCode: legacyProvinceCode ?? this.legacyProvinceCode,
      spicyLevel: spicyLevel ?? this.spicyLevel,
      favoriteTags: favoriteTags ?? this.favoriteTags,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
      preferredDishTypes: preferredDishTypes ?? this.preferredDishTypes,
      flavorPreferences: flavorPreferences ?? this.flavorPreferences,
      satietyPreference: satietyPreference ?? this.satietyPreference,
      preferredMealTimes: preferredMealTimes ?? this.preferredMealTimes,
      preferredRegions: preferredRegions ?? this.preferredRegions,
      allergies: allergies ?? this.allergies,
      dietPreferences: dietPreferences ?? this.dietPreferences,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      discoveryLevel: discoveryLevel ?? this.discoveryLevel,
      diningContexts: diningContexts ?? this.diningContexts,
      recommendationGoals: recommendationGoals ?? this.recommendationGoals,
      surveyVersion: surveyVersion ?? this.surveyVersion,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}
