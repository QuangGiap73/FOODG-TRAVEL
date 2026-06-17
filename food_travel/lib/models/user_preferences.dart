class UserPreferences {
  final String? provinceCode;
  final String? provinceName;
  final String? legacyProvinceCode;
  final int spicyLevel;
  final List<String> favoriteTags;
  final List<String> dislikedIngredients;

  const UserPreferences({
    this.provinceCode,
    this.provinceName,
    this.legacyProvinceCode,
    this.spicyLevel = 0,
    this.favoriteTags = const [],
    this.dislikedIngredients = const [],
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
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPreferences();
    return UserPreferences(
      provinceCode: (map['provinceCode34'] ?? map['provinceCode']) as String?,
      provinceName: (map['provinceName34'] ?? map['provinceName']) as String?,
      legacyProvinceCode: map['legacyProvinceCode'] as String?,
      spicyLevel: (map['spicyLevel'] as num?)?.toInt() ?? 0,
      favoriteTags: _toStringList(map['favoriteTags'] ?? map['favoritetags']),
      dislikedIngredients: _toStringList(map['dislikedIngredients']),
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
