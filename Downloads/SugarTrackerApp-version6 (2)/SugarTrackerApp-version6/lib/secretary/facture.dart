import 'package:flutter/material.dart';


class FacturationPage extends StatelessWidget {
  const FacturationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFFF8F9FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الرأس: العنوان وزر إضافة فاتورة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gestion des Factures",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Text(
                    "Toutes les factures",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Nouvelle Facture", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),

          // الجدول
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
                  dataRowMaxHeight: 85,
                  columns: const [
                    DataColumn(label: Text('Patient')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Montant')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Statut')),
                    DataColumn(label: Text('Action')), // خانة الأكشن
                  ],
                  rows: [
                    _buildFactureRow("Dubois\nMarie", "Consultation\ngénérale", "50 €", "2026-04-10", "Payée", Colors.green, false),
                    _buildFactureRow("Martin\nJean", "Consultation\ndiabète", "50 €", "2026-04-12", "Impayée", Colors.red, true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildFactureRow(String patient, String desc, String amount, String date, String status, Color statusColor, bool showConfirmButton) {
    return DataRow(cells: [
      DataCell(Text(patient, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(desc, style: const TextStyle(color: Color(0xFF64748B)))),
      DataCell(Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      DataCell(Text(date)),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
      DataCell(
        Row(
          children: [
            // زر تأكيد الدفع (الظاهر في الصورة)
            if (showConfirmButton)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                onPressed: () {},
                tooltip: "Valider le paiement",
              ),
            // زر الطباعة (إضافي ومهم للفواتير)
            IconButton(
              icon: const Icon(Icons.print, color: Color(0xFF2563EB), size: 20),
              onPressed: () {},
              tooltip: "Imprimer",
            ),
          ],
        ),
      ),
    ]);
  }
}