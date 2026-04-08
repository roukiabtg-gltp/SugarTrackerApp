import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardDoctor extends StatefulWidget {
  const DashboardDoctor({super.key});

  @override
  State<DashboardDoctor> createState() => _DashboardDoctorState();
}

class _DashboardDoctorState extends State<DashboardDoctor> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          int myPatientsCount = 0;
          List<Map<dynamic, dynamic>> myEmergencies = [];

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            
            // حساب مرضاي فقط
            if (data['users'] != null) {
              (data['users'] as Map).forEach((key, value) {
                if (value['doctorId'] == doctorId) myPatientsCount++;
              });
            }

            // جلب حالات الطوارئ لمرضاي فقط
            if (data['emergencies'] != null) {
              (data['emergencies'] as Map).forEach((key, value) {
                if (value['doctorId'] == doctorId) myEmergencies.add(value);
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("نظرة عامة", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Row(
                  children: [
                    _buildStatCard("إجمالي المرضى", myPatientsCount.toString(), Icons.people, Colors.blue),
                    const SizedBox(width: 20),
                    _buildStatCard("تنبيهات SOS", myEmergencies.length.toString(), Icons.emergency, Colors.red),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSOSSection(myEmergencies),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSSection(List<Map<dynamic, dynamic>> alerts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🚨 SOS Alerts", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          if (alerts.isEmpty) const Text("لا توجد تنبيهات") else ...alerts.map((a) => ListTile(
            title: Text(a['userName'] ?? "مريض مجهول"),
            subtitle: Text("ارتفاع سكر حاد!"),
          )),
        ],
      ),
    );
  }
}