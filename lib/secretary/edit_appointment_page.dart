import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditAppointmentPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const EditAppointmentPage({super.key, required this.appointmentId, required this.appointmentData});

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  late TextEditingController dateController;
  late TextEditingController timeController;
  late String selectedType;
  late String selectedStatus;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(text: widget.appointmentData['date']);
    timeController = TextEditingController(text: widget.appointmentData['time']);
    selectedType = widget.appointmentData['type'] ?? 'Consultation';
    
    var currentStatus = widget.appointmentData['status'];
    if (currentStatus == 'confirme') {
      selectedStatus = 'Confirme';
    } else if (currentStatus == 'Annulé') {
      selectedStatus = 'Annulé';
    } else if (currentStatus == 'Terminé') {
      selectedStatus = 'Terminé';
    } else {
      selectedStatus = 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Modifier Rendez-vous", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // إحاطة الـ body بالكامل بـ SingleChildScrollView لحل مشكلة الـ Overflow
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 600, 
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), 
                  blurRadius: 15, 
                  offset: const Offset(0, 5)
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // لجعل العمود يأخذ مساحة عناصره فقط
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Patient: ${widget.appointmentData['patientName']}", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 25),
                
                const Text("Date", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),

                const Text("Heure", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 15),

                const Text("Type", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: ['Consultation', 'Controle', 'Urgence'].map((String type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                const SizedBox(height: 15),

                const Text("Statut", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: ['Confirme', 'En attente', 'Annulé', 'Terminé'].map((String status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedStatus = val!),
                ),
                const SizedBox(height: 30),

                // أزرار التحكم منسقة عمودياً وأفقياً لمنع التداخل
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            String saveStatus = selectedStatus == 'Confirme' ? 'confirme' : (selectedStatus == 'En attente' ? 'en_attente' : selectedStatus);
                            await FirebaseFirestore.instance
                                .collection('appointments')
                                .doc(widget.appointmentId)
                                .update({
                              'date': dateController.text.trim(),
                              'time': timeController.text.trim(),
                              'type': selectedType,
                              'status': saveStatus,
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Enregistrer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler", style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                    
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        bool confirmDelete = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmer la suppression"),
                            content: const Text("Voulez-vous vraiment supprimer ce rendez-vous ?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui, Supprimer", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          await FirebaseFirestore.instance
                              .collection('appointments')
                              .doc(widget.appointmentId)
                              .delete();
                          Navigator.pop(context); 
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Supprimer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}