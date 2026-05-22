import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تحديث هذه الدالة لتطابق الكود الجديد
  Future<bool> signUpUser({
    required String email,
    required String password,
    required String name,
    required String role,      // أضفنا هذا
    String? specialty,         // أضفنا هذا (اختياري للسكرتيرة)
    String? idProf,            // أضفنا هذا (اختياري للسكرتيرة)
  }) async {
    try {
      // 1. إنشاء المستخدم في Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 2. حفظ معلومات المستخدم الإضافية في Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'specialty': specialty ?? '', // إذا كان سكرتيرة يحفظ كفراغ
          'idProf': idProf ?? '',       // إذا كان سكرتيرة يحفظ كفراغ
          'createdAt': DateTime.now(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print("Error in signUpUser: $e");
      return false;
    }
  }
  
  // دالة لجلب الرتبة (نحتاجها في تسجيل الدخول)
  Future<String> getUserRole(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return doc['role'] ?? 'patient';
  }

  // دالة تسجيل الدخول
  Future<User?> signIn(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }
}