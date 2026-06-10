// lib/services/sucritere_settings_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> secThemeMode  = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale>    secLocale     = ValueNotifier(const Locale('fr'));
final ValueNotifier<double>    secFontScale  = ValueNotifier(1.0);

const _kTheme = 'sec_theme';
const _kLang  = 'sec_lang';
const _kFont  = 'sec_font';

Future<void> loadSecretarySettings() async {
  final prefs = await SharedPreferences.getInstance();
  secThemeMode.value = (prefs.getString(_kTheme) ?? 'light') == 'dark'
      ? ThemeMode.dark : ThemeMode.light;
  secLocale.value    = Locale(prefs.getString(_kLang) ?? 'fr');
  secFontScale.value = prefs.getDouble(_kFont) ?? 1.0;
}

Future<void> setSecTheme(ThemeMode mode) async {
  secThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kTheme, mode == ThemeMode.dark ? 'dark' : 'light');
}

Future<void> setSecLocale(String code) async {
  secLocale.value = Locale(code);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLang, code);
}

Future<void> setSecFontScale(double scale) async {
  secFontScale.value = scale;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_kFont, scale);
}

String ts(String en, String ar, String fr) {
  final lang = secLocale.value.languageCode;
  if (lang == 'ar') return ar;
  if (lang == 'fr') return fr;
  return en;
}