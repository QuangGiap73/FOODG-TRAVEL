// giup luu trang thai khi ng dung bat gps
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPreferenceService {
  static const _key = 'location_enabled';
  static final ValueNotifier<bool> enabled = ValueNotifier(false);

  Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_key) ?? false;
    enabled.value = value;
    return value;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    enabled.value = value;
  }
}
