import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> signUpUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? specialty,
    String? idProf,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'specialty': specialty ?? '',
          'idProf': idProf ?? '',
          'createdAt': DateTime.now(),
        });

        return true;
      }

      return false;
    } catch (e) {
      print("SIGNUP ERROR: $e");
      return false;
    }
  }

  Future<String> getUserRole(String uid) async {
    try {
      print("Searching user: $uid");

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      print("Document exists: ${doc.exists}");
      print("Document data: ${doc.data()}");

      if (!doc.exists) {
        throw Exception("User document not found in Firestore");
      }

      Map<String, dynamic> data =
          doc.data() as Map<String, dynamic>;

      return data['role'] ?? 'patient';
    } catch (e) {
      print("GET ROLE ERROR: $e");
      rethrow;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("LOGIN SUCCESS");
      print("UID: ${result.user?.uid}");

      return result.user;
    } catch (e) {
      print("LOGIN ERROR: $e");
      rethrow;
    }
  }
}