import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the current locale and persists the user's choice.
class LocalizationService extends ChangeNotifier {
  static const _localeKey = 'locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  /// Load the saved locale from [SharedPreferences].
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      _locale = Locale(code);
    }
  }

  /// Update the active locale and persist the selection.
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
}