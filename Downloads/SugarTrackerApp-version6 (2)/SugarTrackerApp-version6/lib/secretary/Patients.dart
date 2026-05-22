import 'package:flutter/material.dart';


class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFFF8F9FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الجزء العلوي: العنوان وزر الإضافة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gestion des Patients",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Text(
                    "Tous les dossiers patients",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
              // زر Nouveau Patient الأزرق
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  "Nouveau Patient",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),

          // الحاوية البيضاء التي تحتوي على الجدول
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
                  columnSpacing: 20,
                  headingRowHeight: 60,
                  dataRowMaxHeight: 80,
                  // تصميم عناوين الجدول
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  columns: const [
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Prénom')),
                    DataColumn(label: Text('Téléphone')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Date\nNaissance')),
                  ],
                  rows: [
                    _buildPatientRow("Dubois", "Marie", "0601020304", "marie.dubois@email.fr", "1961-05-12"),
                    _buildPatientRow("Martin", "Jean", "0602030405", "jean.martin@email.fr", "1968-08-23"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء سطر المريض في الجدول
  DataRow _buildPatientRow(String nom, String prenom, String tel, String email, String date) {
    return DataRow(cells: [
      DataCell(Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
      DataCell(Text(prenom)),
      DataCell(Text(tel, style: const TextStyle(color: Color(0xFF64748B)))),
      DataCell(Text(email, style: const TextStyle(color: Color(0xFF64748B)))),
      DataCell(Text(date, style: const TextStyle(color: Color(0xFF64748B)))),
    ]);
  }
}