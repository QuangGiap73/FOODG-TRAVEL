import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_preferences.dart';
import '../../services/user_service.dart';

class SurveyController extends ChangeNotifier {
  SurveyController({FirebaseAuth? auth, UserService? userService})
      : _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  final FirebaseAuth _auth;
  final UserService _userService;

  final provinceController = TextEditingController();
  final favoritesController = TextEditingController();
  final dislikesController = TextEditingController();

  int _spicyLevel = 0;
  int _satietyPreference = 1;
  int _budgetMin = 30000;
  int _budgetMax = 60000;
  int _discoveryLevel = 3;
  bool _isLoading = false;

  final Set<String> preferredDishTypes = <String>{};
  final Set<String> flavorPreferences = <String>{};
  final Set<String> preferredMealTimes = <String>{};
  final Set<String> preferredRegions = <String>{};
  final Set<String> allergies = <String>{};
  final Set<String> dietPreferences = <String>{};
  final Set<String> diningContexts = <String>{};
  final Set<String> recommendationGoals = <String>{};

  int get spicyLevel => _spicyLevel;
  int get satietyPreference => _satietyPreference;
  int get budgetMin => _budgetMin;
  int get budgetMax => _budgetMax;
  int get discoveryLevel => _discoveryLevel;
  bool get isLoading => _isLoading;

  void setSpicyLevel(double value) {
    _spicyLevel = value.round();
    notifyListeners();
  }

  void setSatietyPreference(int value) {
    _satietyPreference = value;
    notifyListeners();
  }

  void setBudgetRange(int min, int max) {
    _budgetMin = min;
    _budgetMax = max;
    notifyListeners();
  }

  void setDiscoveryLevel(double value) {
    _discoveryLevel = value.round();
    notifyListeners();
  }

  void toggleSetValue(Set<String> source, String value) {
    if (source.contains(value)) {
      source.remove(value);
    } else {
      source.add(value);
    }
    notifyListeners();
  }

  void loadFromPreferences(UserPreferences preferences) {
    provinceController.text = preferences.provinceName ?? '';
    favoritesController.text = preferences.favoriteTags.join(', ');
    dislikesController.text = preferences.dislikedIngredients.join(', ');
    _spicyLevel = preferences.spicyLevel;
    _satietyPreference = preferences.satietyPreference;
    _budgetMin = preferences.budgetMin == 0 ? 30000 : preferences.budgetMin;
    _budgetMax = preferences.budgetMax == 0 ? 60000 : preferences.budgetMax;
    _discoveryLevel = preferences.discoveryLevel;

    preferredDishTypes
      ..clear()
      ..addAll(preferences.preferredDishTypes);
    flavorPreferences
      ..clear()
      ..addAll(preferences.flavorPreferences);
    preferredMealTimes
      ..clear()
      ..addAll(preferences.preferredMealTimes);
    preferredRegions
      ..clear()
      ..addAll(preferences.preferredRegions);
    allergies
      ..clear()
      ..addAll(preferences.allergies);
    dietPreferences
      ..clear()
      ..addAll(preferences.dietPreferences);
    diningContexts
      ..clear()
      ..addAll(preferences.diningContexts);
    recommendationGoals
      ..clear()
      ..addAll(preferences.recommendationGoals);
    notifyListeners();
  }

  List<String> _splitList(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _buildProvinceCode(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    const overrides = {
      'ho chi minh city': 'ho_chi_minh',
      'tp ho chi minh': 'ho_chi_minh',
      'hcm': 'ho_chi_minh',
    };
    final override = overrides[normalized];
    if (override != null) return override;

    final cleaned = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (cleaned.isEmpty) return null;
    return cleaned.split(RegExp(r'\s+')).join('_');
  }

  Future<bool> submit() async {
    if (_isLoading) return false;
    final user = _auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();
    try {
      final provinceName = provinceController.text.trim();
      final preferences = UserPreferences(
        provinceCode: _buildProvinceCode(provinceName),
        provinceName: provinceName,
        spicyLevel: _spicyLevel,
        favoriteTags: _splitList(favoritesController.text),
        dislikedIngredients: _splitList(dislikesController.text),
        preferredDishTypes: preferredDishTypes.toList(),
        flavorPreferences: flavorPreferences.toList(),
        satietyPreference: _satietyPreference,
        preferredMealTimes: preferredMealTimes.toList(),
        preferredRegions: preferredRegions.toList(),
        allergies: allergies.toList(),
        dietPreferences: dietPreferences.toList(),
        budgetMin: _budgetMin,
        budgetMax: _budgetMax,
        discoveryLevel: _discoveryLevel,
        diningContexts: diningContexts.toList(),
        recommendationGoals: recommendationGoals.toList(),
        surveyVersion: 2,
      );
      await _userService.saveOnboarding(
        uid: user.uid,
        preferences: preferences,
      );
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    provinceController.dispose();
    favoritesController.dispose();
    dislikesController.dispose();
    super.dispose();
  }
}
