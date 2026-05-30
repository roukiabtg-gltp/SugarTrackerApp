import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'desktop/auth/login_desktop.dart';
import 'package:firedart/firedart.dart';
import 'package:flutter/foundation.dart';

// 1. إضافة استيراد مكتبة التواريخ واللغات هنا
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة اللغات (الفرنسية، العربية، والإنجليزية) قبل إقلاع أي واجهة
  try {
    await initializeDateFormatting('fr_FR', null);
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en_US', null);
  } catch (e) {
    print("إشعار تهيئة اللغات: $e");
  }

  // إعدادات Firebase والمنصات الخاصة بكِ كما هي
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
    // الطريقة العادية للأندرويد والويب
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } else {
    // الطريقة السهلة للويندوز
    Firestore.initialize("your-project-id"); // حطي الـ Project ID تاعك هنا
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlucoLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
      ),
      home: const LoginDesktop(), 
    );
  }
}