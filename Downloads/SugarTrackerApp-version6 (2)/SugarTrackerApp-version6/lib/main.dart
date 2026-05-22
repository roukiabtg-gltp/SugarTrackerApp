import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// التعديل هنا: نستخدم المسار النسبي المباشر للتأكد
import 'desktop/auth/login_desktop.dart';
import 'package:firedart/firedart.dart';
import 'package:flutter/foundation.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
    // الطريقة العادية للأندرويد والويب
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } else {
    // الطريقة السهلة للويندوز (بدون تعقيدات CMake)
    Firestore.initialize("your-project-id"); // حطي الـ Project ID تاعك هنا
  }

  runApp(MyApp());
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
      home: LoginDesktop(), 
    );
  }
}