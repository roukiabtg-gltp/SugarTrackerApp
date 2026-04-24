import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ستحتاجينها لتنسيق التاريخ تلقائياً

class AppointmentPage extends StatelessWidget {
  const AppointmentPage({super.key});

  // --- دالة لإظهار نافذة إضافة موعد جديد ---
  void _showAddAppointmentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    String selectedType = 'Consultation';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Ajouter un Nouveau Rendez-vous", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nom du Patient", prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: "Date (yyyy-MM-dd)", prefixIcon: Icon(Icons.calendar_today)),
                  onTap: () async {
                    // اختيار التاريخ من تقويم النظام
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    }
                  },
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: "Heure (ex: 09:30)", prefixIcon: Icon(Icons.access_time)),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['Consultation', 'Controle', 'Urgence'].map((String type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) => selectedType = val!,
                  decoration: const InputDecoration(labelText: "Type de RDV"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () async {
                if (nameController.text.isNotEmpty && dateController.text.isNotEmpty) {
                  // إرسال البيانات إلى Firebase
                  await FirebaseFirestore.instance.collection('appointments').add({
                    'patientName': nameController.text,
                    'date': dateController.text,
                    'time': timeController.text,
                    'type': selectedType,
                    'status': 'confirme',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context); // غلق النافذة بعد الحفظ
                }
              },
              child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFFF8F9FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Gestion des Rendez-vous", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text("Tous les rendez-vous", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
              // --- الزر المعدل ليفتح الـ Popup ---
              ElevatedButton.icon(
                onPressed: () => _showAddAppointmentDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Nouveau Rendez-vous", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('appointments').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Aucun rendez-vous trouvé."));

                  var docs = snapshot.data!.docs;
                  return SingleChildScrollView(
                    child: DataTable(
                      horizontalMargin: 30,
                      columnSpacing: 40,
                      headingRowHeight: 60,
                      dataRowMaxHeight: 80,
                      columns: const [
                        DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Heure', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                      ],
                      rows: docs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        Color statusColor = data['status'] == 'confirme' ? Colors.green : Colors.orange;
                        return _buildDataRow(
                          data['patientName'] ?? 'Inconnu',
                          data['date'] ?? '-',
                          data['time'] ?? '-',
                          data['type'] ?? '-',
                          data['status'] ?? 'en-attente',
                          statusColor,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        DataCell(IconButton(icon: const Icon(Icons.edit_note, color: Color(0xFF2563EB)), onPressed: () {})),
      ],
    );
  }
}