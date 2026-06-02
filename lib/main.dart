import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'desktop/auth/login_desktop.dart';
import 'package:firedart/firedart.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

// ── Localizations delegates ─────────────────────────────
import 'package:flutter_localizations/flutter_localizations.dart';

// ── نظام الإعدادات ──────────────────────────────────────
import 'doctor_settings_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('fr_FR', null);
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en_US', null);
  } catch (e) {
    debugPrint("تهيئة اللغات: $e");
  }

  // تحميل إعدادات الطبيب المحفوظة (theme/lang/font)
  await loadDoctorSettings();

  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } else {
    Firestore.initialize("your-project-id");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: doctorThemeMode,
      builder: (_, themeMode, __) =>
        ValueListenableBuilder<Locale>(
          valueListenable: doctorLocale,
          builder: (_, locale, __) =>
            ValueListenableBuilder<double>(
              valueListenable: doctorFontScale,
              builder: (_, scale, __) => MaterialApp(
                title: 'GlucoLink',
                debugShowCheckedModeBanner: false,

                // ── Localizations (يحل مشكلة TabBar/TextField) ──
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('fr'),
                  Locale('ar'),
                ],
                locale: locale,

                // ── Theme ───────────────────────────────────────
                themeMode: themeMode,
                theme:     _buildTheme(Brightness.light, scale),
                darkTheme: _buildTheme(Brightness.dark,  scale),

                home: const LoginDesktop(),
              ),
            ),
        ),
    );
  }

  ThemeData _buildTheme(Brightness brightness, double scale) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1882FF),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0F1117)
          : const Color(0xFFF8F9FE),
      cardColor: brightness == Brightness.dark
          ? const Color(0xFF1E2130)
          : Colors.white,
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontSizeFactor: scale),
      primaryTextTheme: base.primaryTextTheme.apply(fontSizeFactor: scale),
    );
  }
}
