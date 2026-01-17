import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._internal();

  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;

  static const _storageKey = 'theme_mode';

  // App tu quy dinh gio
  static const _darkStart = TimeOfDay(hour: 18, minute: 0);
  static const _darkEnd = TimeOfDay(hour: 6, minute: 0);

  ThemeMode _themeMode = ThemeMode.light;
  bool _autoByTime = true;
  bool _isLoaded = false;
  Timer? _autoTimer;

  ThemeMode get themeMode => _themeMode;
  bool get isAuto => _autoByTime;

  Future<void> load() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    final mode = _fromString(stored);

    // system = auto theo gio do app dat
    if (mode == ThemeMode.system || mode == null) {
      _autoByTime = true;
      _applyAutoTheme(notify: false);
      _scheduleNextAutoSwitch();
    } else {
      _autoByTime = false;
      _themeMode = mode;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      _autoByTime = true;
      _applyAutoTheme();
      _scheduleNextAutoSwitch();
    } else {
      _autoByTime = false;
      _autoTimer?.cancel();
      _themeMode = mode;
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _toString(mode));
  }

  void _applyAutoTheme({bool notify = true}) {
    if (!_autoByTime) return;

    final now = DateTime.now();
    final start = _timeOnDay(now, _darkStart);
    final end = _timeOnDay(now, _darkEnd);

    // neu khoang toi vuot qua nua dem
    final isDark = start.isBefore(end)
        ? !now.isBefore(start) && now.isBefore(end)
        : !now.isBefore(start) || now.isBefore(end);

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (notify) notifyListeners();
  }

  void _scheduleNextAutoSwitch() {
    _autoTimer?.cancel();
    if (!_autoByTime) return;

    final now = DateTime.now();
    final next = _nextChange(now);
    final delay = next.difference(now);

    _autoTimer = Timer(delay, () {
      if (!_autoByTime) return;
      _applyAutoTheme();
      _scheduleNextAutoSwitch();
    });
  }

  DateTime _nextChange(DateTime now) {
    final start = _timeOnDay(now, _darkStart);
    final end = _timeOnDay(now, _darkEnd);

    final candidates = <DateTime>[
      start.isAfter(now) ? start : start.add(const Duration(days: 1)),
      end.isAfter(now) ? end : end.add(const Duration(days: 1)),
    ];
    candidates.sort((a, b) => a.compareTo(b));
    return candidates.first;
  }

  DateTime _timeOnDay(DateTime day, TimeOfDay time) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  ThemeMode? _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}
