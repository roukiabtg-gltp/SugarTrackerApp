import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'patient_profile_page.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Alerts", style: TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.grey)),
              Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. قسم الإحصائيات (الكرتات الثلاثة العلوية)
            StreamBuilder(
              stream: _dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                int critical = 0;
                int monitored = 0;
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map data = snapshot.data!.snapshot.value as Map;
                  critical = (data['emergencies'] as Map?)?.length ?? 0;
                  monitored = (data['users'] as Map?)?.length ?? 0;
                }
                return Row(
                  children: [
                    _buildTopStatCard("Critical Alerts", critical.toString(), Icons.warning_amber_rounded, Colors.red),
                    const SizedBox(width: 16),
                    _buildTopStatCard("Pending Review", "4", Icons.access_time, Colors.orange),
                    const SizedBox(width: 16),
                    _buildTopStatCard("Patients Monitored", monitored.toString(), Icons.person_outline, Colors.green),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // 2. قائمة التنبيهات غير المحلولة
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text("Unresolved Alerts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  
                  // جلب بيانات الطوارئ الحقيقية
                  StreamBuilder(
                    stream: _dbRef.child('emergencies').onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: Text("No alerts at the moment ✅")),
                        );
                      }

                      Map emergencies = snapshot.data!.snapshot.value as Map;
                      return Column(
                        children: emergencies.entries.map((entry) {
                          var val = entry.value;
                          return _buildAlertTile(
                            id: entry.key,
                            name: val['patientName'] ?? "Patient",
                            condition: val['condition'] ?? "High Glucose",
                            age: val['age']?.toString() ?? "--",
                            currentVal: "${val['currentValue'] ?? '0.0'} mg/dL",
                            threshold: "Above ${val['threshold'] ?? '140'}",
                            time: "5 min ago",
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تصميم الكرتات العلوية
  Widget _buildTopStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withOpacity(0.7), size: 28),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // تصميم عنصر التنبيه الواحد (Alert Tile) كما في الصورة
  Widget _buildAlertTile({
    required String id, required String name, required String age, 
    required String condition, required String currentVal, 
    required String threshold, required String time
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade50))),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        _buildBadge("critical"),
                        const SizedBox(width: 12),
                        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Age $age • $condition", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              // الأزرار
              Row(
                children: [
                  OutlinedButton(onPressed: () {}, child: const Text("Resolve", style: TextStyle(color: Colors.black87))),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientProfilePage(patientId: id, patientName: name))),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, elevation: 0),
                    child: const Text("View Patient", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // كرت القيم (Current Value & Threshold)
          Row(
            children: [
              const SizedBox(width: 50),
              _buildValueInfo("Current Value", currentVal),
              const SizedBox(width: 20),
              _buildValueInfo("Threshold", threshold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildValueInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}