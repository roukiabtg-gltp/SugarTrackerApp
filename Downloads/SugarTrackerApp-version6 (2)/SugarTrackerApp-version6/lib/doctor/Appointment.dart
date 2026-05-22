import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String currentDoctorId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text("قائمة المواعيد"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب جميع المواعيد المرتبطة بهذا الطبيب
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: currentDoctorId)
            // احذفي الـ orderBy مؤقتاً حتى تضغطي على رابط الـ Index
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("لا توجد مواعيد مسجلة حالياً"),
            );
          }

          var appointments = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                var data = appointments[index].data() as Map<String, dynamic>;
                
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.person, color: Colors.blue),
                    ),
                    title: Text(
                      data['patientName'] ?? 'بدون اسم',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            SizedBox(width: 5),
                            Text(data['date'] ?? 'غير محدد'),
                            SizedBox(width: 15),
                            Icon(Icons.access_time, size: 14, color: Colors.grey),
                            SizedBox(width: 5),
                            Text(data['time'] ?? '--:--'),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(data['status']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['status'] ?? 'en_attente',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // دالة لتغيير لون الحالة (Status)
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirme': return Colors.green;
      case 'en_attente': return Colors.orange;
      case 'annule': return Colors.red;
      default: return Colors.blue;
    }
  }
}