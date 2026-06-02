// lib/doctor_settings_notifier.dart
// ═══════════════════════════════════════════════════════════
//  ValueNotifiers عالمية — تُستورد في main.dart والصفحات
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Notifiers ──────────────────────────────────────────────
final ValueNotifier<ThemeMode> doctorThemeMode  = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale>    doctorLocale     = ValueNotifier(const Locale('en'));
final ValueNotifier<double>    doctorFontScale  = ValueNotifier(1.0);

// ── Keys ───────────────────────────────────────────────────
const _kTheme = 'doctor_theme';
const _kLang  = 'doctor_lang';
const _kFont  = 'doctor_font';

// ── Load on startup ────────────────────────────────────────
Future<void> loadDoctorSettings() async {
  final prefs = await SharedPreferences.getInstance();

  final theme = prefs.getString(_kTheme) ?? 'light';
  doctorThemeMode.value = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;

  final lang = prefs.getString(_kLang) ?? 'en';
  doctorLocale.value = Locale(lang);

  final font = prefs.getDouble(_kFont) ?? 1.0;
  doctorFontScale.value = font;
}

// ── Save helpers ───────────────────────────────────────────
Future<void> setDoctorTheme(ThemeMode mode) async {
  doctorThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kTheme, mode == ThemeMode.dark ? 'dark' : 'light');
}

Future<void> setDoctorLocale(String langCode) async {
  doctorLocale.value = Locale(langCode);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLang, langCode);
}

Future<void> setDoctorFontScale(double scale) async {
  doctorFontScale.value = scale;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_kFont, scale);
}
