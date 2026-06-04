import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { doctor, secretary }

const _kCurrentRole   = 'current_user_role';
const _kDoctorTheme   = 'doctor_theme';
const _kDoctorLang    = 'doctor_lang';
const _kDoctorFont    = 'doctor_font';
const _kSecretaryTheme = 'secretary_theme';
const _kSecretaryLang  = 'secretary_lang';
const _kSecretaryFont  = 'secretary_font';

final ValueNotifier<UserRole> currentUserRole = ValueNotifier(UserRole.doctor);
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));
final ValueNotifier<double> appFontScale = ValueNotifier(1.0);

final ValueNotifier<ThemeMode> doctorThemeMode = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale> doctorLocale = ValueNotifier(const Locale('en'));
final ValueNotifier<double> doctorFontScale = ValueNotifier(1.0);

final ValueNotifier<ThemeMode> secretaryThemeMode = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale> secretaryLocale = ValueNotifier(const Locale('en'));
final ValueNotifier<double> secretaryFontScale = ValueNotifier(1.0);

String _themeToString(ThemeMode mode) => mode == ThemeMode.dark ? 'dark' : 'light';
ThemeMode _themeFromString(String value) => value == 'dark' ? ThemeMode.dark : ThemeMode.light;

Future<void> loadInitialSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final savedRole = prefs.getString(_kCurrentRole);
  final role = savedRole == 'secretary' ? UserRole.secretary : UserRole.doctor;

  currentUserRole.value = role;
  _loadDoctorSettings(prefs);
  _loadSecretarySettings(prefs);
  _applyRole(role);
}

Future<void> setActiveRole(UserRole role) async {
  currentUserRole.value = role;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kCurrentRole, role == UserRole.secretary ? 'secretary' : 'doctor');
  _applyRole(role);
}

Future<void> setDoctorTheme(ThemeMode mode) async => _setTheme(mode, UserRole.doctor);
Future<void> setDoctorLocale(String langCode) async => _setLocale(langCode, UserRole.doctor);
Future<void> setDoctorFontScale(double scale) async => _setFontScale(scale, UserRole.doctor);

Future<void> setSecretaryTheme(ThemeMode mode) async => _setTheme(mode, UserRole.secretary);
Future<void> setSecretaryLocale(String langCode) async => _setLocale(langCode, UserRole.secretary);
Future<void> setSecretaryFontScale(double scale) async => _setFontScale(scale, UserRole.secretary);

void _loadDoctorSettings(SharedPreferences prefs) {
  doctorThemeMode.value = _themeFromString(prefs.getString(_kDoctorTheme) ?? 'light');
  doctorLocale.value = Locale(prefs.getString(_kDoctorLang) ?? 'en');
  doctorFontScale.value = prefs.getDouble(_kDoctorFont) ?? 1.0;
}

void _loadSecretarySettings(SharedPreferences prefs) {
  secretaryThemeMode.value = _themeFromString(prefs.getString(_kSecretaryTheme) ?? 'light');
  secretaryLocale.value = Locale(prefs.getString(_kSecretaryLang) ?? 'en');
  secretaryFontScale.value = prefs.getDouble(_kSecretaryFont) ?? 1.0;
}

Future<void> _setTheme(ThemeMode mode, UserRole role) async {
  final prefs = await SharedPreferences.getInstance();
  if (role == UserRole.doctor) {
    doctorThemeMode.value = mode;
    await prefs.setString(_kDoctorTheme, _themeToString(mode));
  } else {
    secretaryThemeMode.value = mode;
    await prefs.setString(_kSecretaryTheme, _themeToString(mode));
  }

  // Always apply the changed theme to the active app state so the UI
  // reflects the update immediately. The setting is stored per-role.
  appThemeMode.value = mode;
}

Future<void> _setLocale(String langCode, UserRole role) async {
  final prefs = await SharedPreferences.getInstance();
  if (role == UserRole.doctor) {
    doctorLocale.value = Locale(langCode);
    await prefs.setString(_kDoctorLang, langCode);
  } else {
    secretaryLocale.value = Locale(langCode);
    await prefs.setString(_kSecretaryLang, langCode);
  }

  // Apply immediately to the app locale so all pages update.
  appLocale.value = Locale(langCode);
}

Future<void> _setFontScale(double scale, UserRole role) async {
  final prefs = await SharedPreferences.getInstance();
  if (role == UserRole.doctor) {
    doctorFontScale.value = scale;
    await prefs.setDouble(_kDoctorFont, scale);
  } else {
    secretaryFontScale.value = scale;
    await prefs.setDouble(_kSecretaryFont, scale);
  }

  // Apply immediately to the app font scale so all pages update.
  appFontScale.value = scale;
}

void _applyRole(UserRole role) {
  if (role == UserRole.doctor) {
    appThemeMode.value = doctorThemeMode.value;
    appLocale.value = doctorLocale.value;
    appFontScale.value = doctorFontScale.value;
  } else {
    appThemeMode.value = secretaryThemeMode.value;
    appLocale.value = secretaryLocale.value;
    appFontScale.value = secretaryFontScale.value;
  }
}
