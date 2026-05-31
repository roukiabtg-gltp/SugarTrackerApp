import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});
  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final _db = FirebaseDatabase.instance.ref('users');
  String? doctorId;
  String _search = '';

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

  void _showAddPatientDialog() {
    final firstCtrl   = TextEditingController();
    final lastCtrl    = TextEditingController();
    final emailCtrl   = TextEditingController();
    final phoneCtrl   = TextEditingController();
    final birthCtrl   = TextEditingController();
    final addressCtrl = TextEditingController();
    String blood  = 'A+';
    String gender = 'Homme';
    bool loading  = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouveau Patient', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: _field(firstCtrl, 'Prénom',    Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _field(lastCtrl,  'Nom',       Icons.person_outline)),
          ]),
          const SizedBox(height: 12),
          _field(emailCtrl,   'Email',      Icons.email_outlined),
          const SizedBox(height: 12),
          _field(phoneCtrl,   'Téléphone',  Icons.phone_outlined),
          const SizedBox(height: 12),
          TextField(
            controller: birthCtrl,
            readOnly: true,
            decoration: InputDecoration(labelText: 'Date de naissance', prefixIcon: const Icon(Icons.cake_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF8FAFC)),
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: DateTime(1990), firstDate: DateTime(1930), lastDate: DateTime.now());
              if (d != null) birthCtrl.text = DateFormat('dd/MM/yyyy').format(d);
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: gender,
              decoration: InputDecoration(labelText: 'Genre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF8FAFC)),
              items: ['Homme','Femme'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setDlg(() => gender = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              value: blood,
              decoration: InputDecoration(labelText: 'Groupe sanguin', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF8FAFC)),
              items: ['A+','A-','B+','B-','AB+','AB-','O+','O-'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setDlg(() => blood = v!),
            )),
          ]),
          const SizedBox(height: 12),
          _field(addressCtrl, 'Adresse', Icons.location_on_outlined),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          if (loading)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator())
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (firstCtrl.text.isEmpty || lastCtrl.text.isEmpty) return;
                setDlg(() => loading = true);
                await _db.push().set({
                  'first_name': firstCtrl.text.trim(),
                  'last_name':  lastCtrl.text.trim(),
                  'email':      emailCtrl.text.trim(),
                  'phone':      phoneCtrl.text.trim(),
                  'birth_date': birthCtrl.text,
                  'gender':     gender,
                  'blood_type': blood,
                  'address':    addressCtrl.text.trim(),
                  'role':       'patient',
                  'doctorId':   doctorId,
                  'createdAt':  ServerValue.timestamp,
                });
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
        ],
      )),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) => TextField(
    controller: c,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF8FAFC)),
  );

  String _age(String? s) {
    if (s == null || s.isEmpty) return '--';
    try {
      final parts = s.replaceAll('/', '-').split('-');
      if (parts.length != 3) return '--';
      final dt = parts[0].length < 4
          ? DateTime.parse('${parts[2]}-${parts[1].padLeft(2,'0')}-${parts[0].padLeft(2,'0')}')
          : DateTime.parse(s);
      int age = DateTime.now().year - dt.year;
      if (DateTime.now().month < dt.month || (DateTime.now().month == dt.month && DateTime.now().day < dt.day)) age--;
      return age >= 0 ? '$age ans' : '--';
    } catch (_) { return '--'; }
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
              Text('Gestion des Patients', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              SizedBox(height: 4),
              Text('Tous les dossiers patients', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ]),
            ElevatedButton.icon(
              onPressed: _showAddPatientDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouveau Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ]),
          const SizedBox(height: 20),
          // Search
          TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Rechercher un patient...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder(
              stream: doctorId != null
                  ? _db.orderByChild('doctorId').equalTo(doctorId).onValue
                  : _db.orderByChild('role').equalTo('patient').onValue,
              builder: (_, AsyncSnapshot<DatabaseEvent> snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
                if (!snap.hasData || snap.data!.snapshot.value == null) return const Center(child: Text('Aucun patient trouvé', style: TextStyle(color: Colors.grey)));

                final raw = snap.data!.snapshot.value as Map;
                var entries = raw.entries
                    .where((e) => (e.value['role'] ?? '') == 'patient')
                    .toList();
                if (_search.isNotEmpty) {
                  entries = entries.where((e) {
                    final fn = (e.value['first_name'] ?? '').toString().toLowerCase();
                    final ln = (e.value['last_name']  ?? '').toString().toLowerCase();
                    return fn.contains(_search) || ln.contains(_search);
                  }).toList();
                }

                return Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
                        columnWidths: const {0: FlexColumnWidth(2.5), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(1.2), 3: FlexColumnWidth(1.2), 4: FlexColumnWidth(2)},
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade50),
                            children: ['Patient', 'Téléphone', 'Âge', 'Groupe', 'Adresse']
                                .map((h) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)))).toList(),
                          ),
                          ...entries.map((e) {
                            final d  = e.value as Map;
                            final fn = d['first_name']?.toString() ?? '';
                            final ln = d['last_name']?.toString()  ?? '';
                            final initials = '${fn.isNotEmpty ? fn[0] : ''}${ln.isNotEmpty ? ln[0] : ''}'.toUpperCase();
                            return TableRow(children: [
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(children: [
                                  CircleAvatar(radius: 16, backgroundColor: const Color(0xFF2563EB).withOpacity(0.1), child: Text(initials, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 10),
                                  Text('$fn $ln'.trim(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ])),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Text(d['phone']?.toString() ?? '--', style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Text(_age(d['birth_date']?.toString()), style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)), child: Text(d['blood_type']?.toString() ?? '--', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Text(d['address']?.toString() ?? '--', style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis)),
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
