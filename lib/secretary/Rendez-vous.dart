import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
// استدعاء ملف صفحة التعديل الجديدة
import 'edit_appointment_page.dart'; 

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  String? doctorIdFromServer; // المتغير المعتمد الوحيد الذي سيحمل المعرف الصحيح للطبيب
  bool isLoading = true; 

  @override
  void initState() {
    super.initState();
    getDoctorIdOfThisSecretary(); // جلب معرف الطبيب المرتبط بحساب السكرتيرة فور تشغيل الصفحة
  }

  Future<void> getDoctorIdOfThisSecretary() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot secretaryDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (secretaryDoc.exists && secretaryDoc.data() != null) {
          var data = secretaryDoc.data() as Map<String, dynamic>;
          setState(() {
            // جلب الـ doctorId الصحيح للطبيب المرتبط بحساب السكرتيرة
            doctorIdFromServer = data['doctorId']; 
            isLoading = false; 
          });
          debugPrint("=== SUCCESS: تم جلب معرف الطبيب الصحيح: $doctorIdFromServer ===");
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("❌ حدث خطأ أثناء جلب معطيات السكرتيرة: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

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
                  readOnly: true, 
                  onTap: () async {
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
                  
                  // فحص أمان للتأكد من أن كود الطبيب تم جلبه وليس فارغاً قبل الحفظ
                  if (doctorIdFromServer == null || doctorIdFromServer!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Erreur: ID du médecin introuvable.")),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance.collection('appointments').add({
                    'patientName': nameController.text.trim(),
                    'date': dateController.text.trim(),
                    'time': timeController.text.trim(),
                    'type': selectedType,
                    
                    // تم التثبيت الحاسم هنا: إرسال معرف الطبيب الصحيح المستخرج لقاعدة البيانات
                    'doctorId': doctorIdFromServer, 
                    
                    'status': 'en_attente', 
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context); 
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
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              child: doctorIdFromServer == null
                  ? const Center(child: Text("Erreur de configuration du médecin."))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('doctorId', isEqualTo: doctorIdFromServer) // فلترة العرض بالمعرف الصحيح أيضاً ومزامنته
                          .snapshots(),
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
                              String appointmentId = doc.id; 
                              
                              Color statusColor = Colors.orange;
                              if (data['status'] == 'confirme') statusColor = Colors.green;
                              if (data['status'] == 'Annulé') statusColor = Colors.red;
                              if (data['status'] == 'Terminé') statusColor = Colors.blue;

                              return _buildDataRow(context, appointmentId, data, statusColor);
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

  DataRow _buildDataRow(BuildContext context, String id, Map<String, dynamic> data, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(data['patientName'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(data['date'] ?? '-')),
        DataCell(Text(data['time'] ?? '-')),
        DataCell(Text(data['type'] ?? '-')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(data['status'] ?? 'en_attente', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit_note, color: Color(0xFF2563EB)), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAppointmentPage(appointmentId: id, appointmentData: data),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}