class UserPreferences {
  final String? provinceCode;
  final String? provinceName;
  final int spicyLevel;
  final List<String> favoriteTags;
  final List<String> dislikedIngredients;

  const UserPreferences({
    this.provinceCode,
    this.provinceName,
    this.spicyLevel = 0,
    this.favoriteTags = const [],
    this.dislikedIngredients = const [],
  });
  Map<String, dynamic> toMap(){
    return {
      'provinceCode': provinceCode,
      'provinceName': provinceName,
      'spicyLevel': spicyLevel,
      'favoriteTags': favoriteTags,
      'dislikedIngredients': dislikedIngredients,
    };
  }
  factory UserPreferences.fromMap(Map<String, dynamic>? map){
    if(map == null ) return const UserPreferences();
    return UserPreferences(
      provinceCode: map['provinceCode'] as String?,
      provinceName: map['provinceName'] as String?,
      spicyLevel: (map['spicyLevel'] as num?)?.toInt() ?? 0,
      favoriteTags: _toStringList(map['favoriteTags'] ?? map['favoritetags']),
      dislikedIngredients: _toStringList(map['dislikedIngredients']),
    );
  }
  static List<String> _toStringList(dynamic value){
    if (value is List){
      return value
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}
