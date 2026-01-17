import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // lưu ngôn ngữ vào bộ nhớ máy 

// quản lí ngôn ngữ cho toàn app 
class LocaleController extends ChangeNotifier {
    LocaleController._internal();
    static final LocaleController _instance = LocaleController._internal();
    factory LocaleController() => _instance;
    // tạo khóa key để lưu
    static const _storageKey = 'locale_code';
    Locale? _locale;
    bool _isLoaded = false;
    Locale? get locale => _locale; // ui doc
    // hàm load ngôn ngữ khi mở app
    Future<void> load() async {
        if (_isLoaded) return;
        final prefs = await SharedPreferences.getInstance();
        final code = prefs.getString(_storageKey);
        _locale = code == null ? null : Locale(code);
        _isLoaded = true;
        notifyListeners();
    }
    // hàm đổi ngôn ngữ khi người dùng chọn
    Future<void> setLocale(Locale? locale) async {
        _locale = locale;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        if (locale == null) {
        await prefs.remove(_storageKey);
        } else {
        await prefs.setString(_storageKey, locale.languageCode);
        }
    }
}