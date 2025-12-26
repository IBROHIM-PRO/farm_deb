import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('tg', '');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'tg';
    _locale = Locale(languageCode, '');
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'tg':
        return 'Тоҷикӣ';
      default:
        return 'English';
    }
  }

  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
      {'code': 'tg', 'name': 'Тоҷикӣ', 'flag': '🇹🇯'},
    ];
  }
}
