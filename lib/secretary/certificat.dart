import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CertificatsPage extends StatefulWidget {
  const CertificatsPage({super.key});
  @override
  State<CertificatsPage> createState() => _CertificatsPageState();
}

class _CertificatsPageState extends State<CertificatsPage> {
  String? doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) setState(() => doctorId = doc['doctorId']);
  }

  void _showAddCertificatDialog() {
    final patientCtrl = TextEditingController();
    final motifCtrl   = TextEditingController();
    final dureeCtrl   = TextEditingController();
    String type = 'Repos';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouveau Certificat', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(patientCtrl, 'Nom du patient', Icons.person_outline),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: type,
            decoration: InputDecoration(labelText: 'Type de certificat', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF8FAFC)),
            items: ['Repos','Maladie','Aptitude','Vaccination','Autre'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setDlg(() => type = v!),
          ),
          const SizedBox(height: 12),
          _field(motifCtrl, 'Motif', Icons.notes_outlined),
          const SizedBox(height: 12),
          _field(dureeCtrl, 'Durée (ex: 3 jours)', Icons.timelapse_outlined),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (patientCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('certificats').add({
                'patientName': patientCtrl.text.trim(),
                'type':        type,
                'motif':       motifCtrl.text.trim(),
                'duree':       dureeCtrl.text.trim(),
                'doctorId':    doctorId,
                'date':        DateFormat('yyyy-MM-dd').format(DateTime.now()),
                'createdAt':   FieldValue.serverTimestamp(),
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('certificats').doc(id).delete();
  }

  Widget _field(TextEditingController c, String label, IconData icon) => TextField(
    controller: c,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF8FAFC)),
  );

  Color _typeColor(String t) {
    return {'Repos': const Color(0xFF2563EB), 'Maladie': const Color(0xFFEA580C), 'Aptitude': const Color(0xFF10B981), 'Vaccination': const Color(0xFF7C3AED)}[t] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Gestion des Certificats', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              SizedBox(height: 4),
              Text('Tous les certificats médicaux', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ]),
            ElevatedButton.icon(
              onPressed: _showAddCertificatDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouveau Certificat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ]),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: doctorId != null
                  ? FirebaseFirestore.instance.collection('certificats').where('doctorId', isEqualTo: doctorId).orderBy('createdAt', descending: true).snapshots()
                  : FirebaseFirestore.instance.collection('certificats').orderBy('createdAt', descending: true).snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Aucun certificat', style: TextStyle(color: Colors.grey)));

                return Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
                        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1.5), 4: FlexColumnWidth(1.5), 5: FlexColumnWidth(1)},
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade50),
                            children: ['Patient','Type','Motif','Durée','Date','Action']
                                .map((h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)))).toList(),
                          ),
                          ...docs.map((doc) {
                            final d    = doc.data() as Map<String, dynamic>;
                            final type = d['type']?.toString() ?? 'Autre';
                            final col  = _typeColor(type);
                            return TableRow(children: [
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(d['patientName'] ?? '--', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(type, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12)))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(d['motif'] ?? '--', style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(d['duree'] ?? '--', style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(d['date'] ?? '--', style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _delete(doc.id), padding: EdgeInsets.zero, constraints: const BoxConstraints())),
                            ]);
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
