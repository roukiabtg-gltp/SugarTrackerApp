import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  int _selectedIndex = 0;

  // دالة لجلب معرف الطبيب
  Future<String?> _getDoctorId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final userData = doc.data() as Map<String, dynamic>;
        return (userData['doctorId'] ?? userData['doctorUid'] ?? userData['doctorID'])?.toString().trim();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getDoctorId(),
      builder: (context, doctorSnapshot) {
        if (doctorSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final String? doctorUid = doctorSnapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildAccueilContent(doctorUid),
                    _buildRendezVousPage(doctorUid),
                    const Center(child: Text("Liste d'Attente")),
                    const Center(child: Text("Patients")),
                    const Center(child: Text("Facturation")),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // دالة عرض المواعيد الموحدة والمستقرة
  Widget _buildCoreAppointmentsStream(String? doctorUid, bool onlyToday) {
    if (doctorUid == null || doctorUid.isEmpty) {
      return const Center(child: Text("ID du médecin introuvable."));
    }

    return StreamBuilder<QuerySnapshot>(
      // الاستعلام هنا بسيط جداً: فقط doctorId
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorUid.trim())
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // التصفية المحلية للتاريخ (تطابق صيغة 2026-06-05)
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (!onlyToday) return true;
          return data['date'] == today;
        }).toList();

        if (docs.isEmpty) return const Center(child: Text("Aucun rendez-vous."));

        return ListView.builder(
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final rdv = docs[index].data() as Map<String, dynamic>;
            return _buildPatientRow(
              rdv['patientName'] ?? 'Patient',
              rdv['time'] ?? '--:--',
              rdv['status'] ?? 'en_attente',
            );
          },
        );
      },
    );
  }

  Widget _buildAccueilContent(String? doctorUid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          _buildCoreAppointmentsStream(doctorUid, true),
        ],
      ),
    );
  }

  Widget _buildRendezVousPage(String? doctorUid) {
    return _buildCoreAppointmentsStream(doctorUid, false);
  }

  // دالة الـ Sidebar والـ Rows كما هي في كودك (تم اختصارها لضيق المساحة)
  Widget _buildSidebar() => Container(width: 280, color: Colors.white);

  Widget _buildPatientRow(String name, String time, String status) {
    return Card(child: ListTile(title: Text(name), subtitle: Text("$time - $status")));
  }
}