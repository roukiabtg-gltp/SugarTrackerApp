import 'package:flutter/material.dart';


class AppointmentPage extends StatelessWidget {
  const AppointmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFFF8F9FB), // لون الخلفية الرمادي الفاتح الموحد
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- الجزء العلوي (العنوان وزر الإضافة) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gestion des Rendez-vous",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Text(
                    "Tous les rendez-vous",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
              // زر Nouveau Rendez-vous الأزرق
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Nouveau Rendez-vous",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // --- جدول المواعيد (الخلفية البيضاء) ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  horizontalMargin: 30,
                  columnSpacing: 40,
                  headingRowHeight: 60,
                  dataRowMaxHeight: 80, // مساحة مريحة للبيانات
                  columns: const [
                    DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataColumn(label: Text('Heure', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                  rows: [
                    _buildDataRow("Marie Dubois", "2026-04-15", "09:00", "Consultation", "confirme", Colors.green),
                    _buildDataRow("Jean Martin", "2026-04-15", "10:00", "Controle", "en-attente", Colors.orange),
                    _buildDataRow("Sophie Bernard", "2026-04-15", "11:00", "Consultation", "confirme", Colors.green),
                    _buildDataRow("Pierre Petit", "2026-04-16", "14:00", "Urgence", "confirme", Colors.green),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء سطر البيانات في الجدول
  DataRow _buildDataRow(String name, String date, String time, String type, String status, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(date)),
        DataCell(Text(time)),
        DataCell(Text(type)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit_note, color: Color(0xFF2563EB)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}