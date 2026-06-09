// lib/settings_notifier.dart
// ═══════════════════════════════════════════════════════════
//  نظام الإعدادات الموحّد — يعتمد على doctor_settings_notifier
//  لتجنب تعارض تعريف نفس الـ ValueNotifiers في ملفين
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── إعادة تصدير notifiers الطبيب (لا تُعرَّف هنا مجدداً) ──
export 'doctor_settings_notifier.dart'
    show doctorThemeMode, doctorLocale, doctorFontScale,
         setDoctorTheme, setDoctorLocale, setDoctorFontScale, t;

// ═══════════════════════════════════════════════════════════
//  إعدادات السكرتيرة — مستقلة تماماً
// ═══════════════════════════════════════════════════════════
final ValueNotifier<ThemeMode> secretaryThemeMode = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale>    secretaryLocale    = ValueNotifier(const Locale('fr'));
final ValueNotifier<double>    secretaryFontScale = ValueNotifier(1.0);

const _kSecretaryTheme = 'secretary_theme';
const _kSecretaryLang  = 'secretary_lang';
const _kSecretaryFont  = 'secretary_font';

Future<void> loadSecretarySettings() async {
  final prefs = await SharedPreferences.getInstance();
  final theme = prefs.getString(_kSecretaryTheme) ?? 'light';
  secretaryThemeMode.value = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  secretaryLocale.value    = Locale(prefs.getString(_kSecretaryLang) ?? 'fr');
  secretaryFontScale.value = prefs.getDouble(_kSecretaryFont) ?? 1.0;
}

Future<void> setSecretaryTheme(ThemeMode mode) async {
  secretaryThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kSecretaryTheme, mode == ThemeMode.dark ? 'dark' : 'light');
}

Future<void> setSecretaryLocale(String langCode) async {
  secretaryLocale.value = Locale(langCode);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kSecretaryLang, langCode);
}

Future<void> setSecretaryFontScale(double scale) async {
  secretaryFontScale.value = scale;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_kSecretaryFont, scale);
}

/// دالة الترجمة للسكرتيرة
String ts(String en, String ar, String fr) {
  final lang = secretaryLocale.value.languageCode;
  if (lang == 'ar') return ar;
  if (lang == 'fr') return fr;
  return en;
}
