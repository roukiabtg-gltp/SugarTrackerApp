import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  // المرجع الصحيح حسب كود صفحة المرضى الناجح عندك
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('users');
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // نفس خلفية التصميم المطلوب
      body: StreamBuilder(
        // جلب المرضى المرتبطين بكِ فقط
        stream: _dbRef.orderByChild('doctorId').equalTo(doctorId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          int totalPatients = 0;
          int criticalCases = 0;
          List<Widget> criticalAlertsList = [];

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            totalPatients = data.length;

            data.forEach((key, value) {
              String name = "${value['first_name'] ?? ""} ${value['last_name'] ?? ""}".trim();
              double glucose = double.tryParse(value['glucoseLevel']?.toString() ?? "0") ?? 0;

              // تحديد الحالات الحرجة (Critical)
              if (glucose > 180 || (glucose < 70 && glucose > 0)) {
                criticalCases++;
                criticalAlertsList.add(_buildCriticalAlertItem(
                  name: name.isNotEmpty ? name : "مريض مجهول",
                  reason: glucose > 180 ? "ارتفاع حاد في السكر" : "انخفاض حاد في السكر",
                  reading: "$glucose mg/dL",
                ));
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Dashboard", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const SizedBox(height: 25),

                // صف البطاقات الإحصائية (Stats Cards) بنفس التصميم
                Row(
                  children: [
                    _buildStatCard("Total Patients", totalPatients.toString(), Icons.people_alt_outlined, Colors.blue, "+12%"),
                    const SizedBox(width: 20),
                    _buildStatCard("Critical Cases", criticalCases.toString(), Icons.warning_amber_rounded, Colors.red, "+2"),
                    const SizedBox(width: 20),
                    // عرض عدد المواعيد في بطاقة "Today's Appts"
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('doctorId', isEqualTo: doctorId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return _buildStatCard(
                          "Today's Appts",
                          "0",
                          Icons.calendar_today_outlined,
                          Colors.green,
                          "-",
                        );
                        if (!snapshot.hasData) return _buildStatCard(
                          "Today's Appts",
                          "0",
                          Icons.calendar_today_outlined,
                          Colors.green,
                          "-",
                        );

                        int count = snapshot.data!.docs.length;
                        return _buildStatCard(
                          "Today's Appts",
                          count.toString(),
                          Icons.calendar_today_outlined,
                          Colors.green,
                          "-",
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildStatCard("Avg Health Score", "82.5", Icons.show_chart_rounded, Colors.purple, "+5.2%"),
                  ],
                ),

                const SizedBox(height: 35),

                // قسم التنبيهات والنشاطات الأخيرة
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // قائمة الحالات الحرجة الحقيقية
                    Expanded(
                      flex: 2,
                      child: _buildSectionContainer(
                        title: "Critical Alerts",
                        child: criticalAlertsList.isEmpty 
                          ? const Center(child: Text("لا توجد حالات حرجة حالياً ✅")) 
                          : Column(children: criticalAlertsList),
                      ),
                    ),
                    const SizedBox(width: 25),
                    // قائمة النشاطات الأخيرة
                    Expanded(
                      child: _buildSectionContainer(
                        title: "Recent Activity",
                        child: Column(
                          children: [
                            _buildActivityItem("Sarah Wilson", "Blood pressure reading", "120/80", "2 min ago"),
                            _buildActivityItem("Robert Brown", "Heart rate check", "72 bpm", "8 min ago"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- ودجت البطاقة الإحصائية (التصميم الاحترافي) ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String trend) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(trend, style: TextStyle(color: trend.contains('+') ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // --- حاوية الأقسام السفلى ---
  Widget _buildSectionContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // --- عنصر التنبيه الحرج (الحقيقي) ---
  Widget _buildCriticalAlertItem({required String name, required String reason, required String reading}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(reason, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ),
          Text(reading, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontSize: 16)),
        ],
      ),
    );
  }

  // --- عنصر النشاط الأخير ---
  Widget _buildActivityItem(String name, String action, String detail, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          const CircleAvatar(radius: 4, backgroundColor: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("$action: $detail", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }
}