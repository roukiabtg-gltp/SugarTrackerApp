import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../doctor_settings_notifier.dart';
import 'patient_profile_helpers.dart';

class PrescriptionTab extends StatefulWidget {
  final String patientId;

  const PrescriptionTab({super.key, required this.patientId});

  @override
  State<PrescriptionTab> createState() => _PrescriptionTabState();
}

class _PrescriptionTabState extends State<PrescriptionTab> {
  final _db = FirebaseDatabase.instance.ref();
  final _prescController = TextEditingController();

  @override
  void dispose() {
    _prescController.dispose();
    super.dispose();
  }

  void _addPrescription() {
    final text = _prescController.text.trim();
    if (text.isEmpty) return;
    _db.child('prescriptions').child(widget.patientId).push().set({
      'content': text,
      'sender': 'doctor',
      'timestamp': ServerValue.timestamp,
      'date': DateTime.now().toString().substring(0, 16),
    });
    _prescController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t('Prescriptions', 'الوصفات الطبية', 'Prescriptions'),
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _prescController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t('Write prescription details...', 'اكتب تفاصيل الوصفة...',
                  'Écrivez les détails de l\'ordonnance...'),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _addPrescription,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.medical_services_outlined,
              color: Colors.white),
          label: Text(t('Add', 'إضافة', 'Ajouter'),
              style: const TextStyle(color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 20),
      StreamBuilder(
        stream:
            _db.child('prescriptions').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text(
                        t('No prescriptions yet', 'لا توجد وصفات حتى الآن',
                            'Aucune ordonnance pour le moment'),
                        style: const TextStyle(color: Colors.grey))));
          }
          final Map raw = snap.data!.snapshot.value as Map;
          final entries = raw.entries.toList()
            ..sort((a, b) => (b.value['timestamp'] ?? 0)
                .compareTo(a.value['timestamp'] ?? 0));
          return Column(
            children: entries.map((e) {
              final d = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3))),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(d['content'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D3142))),
                            const SizedBox(height: 4),
                            Text(fmtDate(d['timestamp']),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ])),
                    ]),
              );
            }).toList(),
          );
        },
      ),
    ]);
  }
}
