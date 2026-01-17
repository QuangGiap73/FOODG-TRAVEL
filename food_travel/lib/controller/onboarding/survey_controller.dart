import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_preferences.dart';
import '../../services/user_service.dart';

class SurveyController extends ChangeNotifier{
  SurveyController({FirebaseAuth? auth, UserService? userService})
    : _auth = auth ?? FirebaseAuth.instance,
      _userService = userService ?? UserService();

  final FirebaseAuth _auth; // lấy dữ liệu hiện tại
  final UserService _userService; // lưu dữ liệu form
  // tao controller input
  final provinceController = TextEditingController();
  final favoritesController = TextEditingController();
  final dislikesController = TextEditingController();

  int _spicyLevel = 0;
  bool _isLoading = false;

  int get spicyLevel => _spicyLevel;
  bool get isLoading => _isLoading;
  // set thuc an cay
  void setSpicyLevel(double value){
    _spicyLevel = value.round();
    notifyListeners();
  }
  // ham tách danh sách text -> list
  List<String> _splitList(String raw){
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
  // ham submit khaor sats
  Future<bool> submit() async{
    if(_isLoading) return false;
    final user = _auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();
    try {
      // tao object preferences
      final provinceName = provinceController.text.trim();
      final preferences = UserPreferences(
        provinceCode: _buildProvinceCode(provinceName),
        provinceName: provinceName,
        spicyLevel: _spicyLevel,
        favoriteTags: _splitList(favoritesController.text),
        dislikedIngredients: _splitList(dislikesController.text),
      );
      await _userService.saveOnboarding(uid: user.uid, preferences: preferences);
    
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // don dep bo nho
  @override
  void dispose(){
    provinceController.dispose();
    favoritesController.dispose();
    dislikesController.dispose();
    super.dispose();
  }
  
}
