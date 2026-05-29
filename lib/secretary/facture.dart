import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FacturationPage extends StatefulWidget {
  const FacturationPage({super.key});
  @override
  State<FacturationPage> createState() => _FacturationPageState();
}

class _FacturationPageState extends State<FacturationPage> {
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

  void _showAddFactureDialog() {
    final patientCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    final descCtrl    = TextEditingController();
    String statut = 'en_attente';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouvelle Facture', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(patientCtrl, 'Nom du patient', Icons.person_outline),
          const SizedBox(height: 12),
          _field(montantCtrl, 'Montant (DA)', Icons.attach_money, isNum: true),
          const SizedBox(height: 12),
          _field(descCtrl,    'Description', Icons.description_outlined),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: statut,
            decoration: InputDecoration(labelText: 'Statut', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF8FAFC)),
            items: [
              const DropdownMenuItem(value: 'payee',       child: Text('Payée')),
              const DropdownMenuItem(value: 'en_attente',  child: Text('En attente')),
            ],
            onChanged: (v) => setDlg(() => statut = v!),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (patientCtrl.text.isEmpty || montantCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('factures').add({
                'patientName': patientCtrl.text.trim(),
                'montant':     double.tryParse(montantCtrl.text.trim()) ?? 0,
                'description': descCtrl.text.trim(),
                'statut':      statut,
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

  Future<void> _deleteFacture(String id) async {
    await FirebaseFirestore.instance.collection('factures').doc(id).delete();
  }

  Future<void> _toggleStatut(String id, String current) async {
    final next = current == 'payee' ? 'en_attente' : 'payee';
    await FirebaseFirestore.instance.collection('factures').doc(id).update({'statut': next});
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool isNum = false}) => TextField(
    controller: c,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF8FAFC)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Gestion des Factures', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              SizedBox(height: 4),
              Text('Toutes les factures', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ]),
            ElevatedButton.icon(
              onPressed: _showAddFactureDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouvelle Facture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ]),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: doctorId != null
                  ? FirebaseFirestore.instance.collection('factures').where('doctorId', isEqualTo: doctorId).orderBy('createdAt', descending: true).snapshots()
                  : FirebaseFirestore.instance.collection('factures').orderBy('createdAt', descending: true).snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Aucune facture', style: TextStyle(color: Colors.grey)));

                return Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
                        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(2), 3: FlexColumnWidth(1.2), 4: FlexColumnWidth(1.5), 5: FlexColumnWidth(1.2)},
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade50),
                            children: ['Patient','Montant','Description','Date','Statut','Action']
                                .map((h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)))).toList(),
                          ),
                          ...docs.map((doc) {
                            final d       = doc.data() as Map<String, dynamic>;
                            final statut  = d['statut']?.toString() ?? 'en_attente';
                            final isPaid  = statut == 'payee';
                            final sColor  = isPaid ? const Color(0xFF10B981) : const Color(0xFFEA580C);
                            final sBg     = isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5);
                            return TableRow(children: [
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(d['patientName'] ?? '--', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text('${d['montant'] ?? 0} DA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(d['description'] ?? '--', style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(d['date'] ?? '--', style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: GestureDetector(
                                  onTap: () => _toggleStatut(doc.id, statut),
                                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(20)), child: Text(isPaid ? 'Payée' : 'En attente', style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 12))),
                                )),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _deleteFacture(doc.id), padding: EdgeInsets.zero, constraints: const BoxConstraints())),
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
