import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- وظيفة السكرتيرة: إضافة موعد جديد ---
  Future<void> addAppointment(Map<String, dynamic> data) async {
    await _db.collection('appointments').add({
      ...data,
      'status': 'confirme',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- وظيفة الطبيب والسكرتيرة: جلب المواعيد حياً ---
  Stream<QuerySnapshot> getAppointments() {
    return _db
        .collection('appointments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}