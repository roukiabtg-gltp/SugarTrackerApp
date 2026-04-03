import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // تأكدي من إضافة هذه المكتبة في pubspec.yaml
import 'package:firebase_database/firebase_database.dart';

class DashboardDoctor extends StatelessWidget {
  const DashboardDoctor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "نظرة عامة على العيادة",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 25),

            // 1️⃣ صف الإحصائيات العلوية
            Row(
              children: [
                _buildStatCard("إجمالي المرضى", "124", Icons.people, Colors.blue),
                const SizedBox(width: 20),
                _buildStatCard("الحالات الحرجة", "8", Icons.warning_amber_rounded, Colors.orange),
                const SizedBox(width: 20),
                _buildStatCard("تنبيهات SOS", "3", Icons.notifications_active, Colors.red),
              ],
            ),
            
            const SizedBox(height: 30),

            // 2️⃣ قسم التنبيهات والرسوم البيانية
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الرسوم البيانية (Glycemia Trends)
                Expanded(
                  flex: 2,
                  child: _buildChartSection(),
                ),
                const SizedBox(width: 25),
                
                // تنبيهات SOS اللحظية
                Expanded(
                  flex: 1,
                  child: _buildSOSAlertList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ودجت كرت الإحصائيات
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // قسم الرسم البياني (مربوط بالبيانات لاحقاً)
  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("تحليل مستويات السكر (أسبوعي)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 100), const FlSpot(1, 150), const FlSpot(2, 120),
                      const FlSpot(3, 200), const FlSpot(4, 180), const FlSpot(5, 90),
                    ],
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 4,
                    belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // قائمة تنبيهات SOS اللحظية
  Widget _buildSOSAlertList() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: 10),
              Text("🚨 SOS Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: const Text("مريض: محمد علي", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("ارتفاع حاد: 320 mg/dL"),
                    trailing: const Text("الآن", style: TextStyle(color: Colors.red)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}