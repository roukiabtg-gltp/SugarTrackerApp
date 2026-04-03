import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // سطر مهم جداً
import 'firebase_options.dart'; // سطر مهم جداً
import 'desktop/auth/login_desktop.dart';

void main() async {
  // تأكدي من إضافة هذين السطرين
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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