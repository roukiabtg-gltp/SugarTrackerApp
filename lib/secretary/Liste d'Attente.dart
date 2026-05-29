import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WaitingListPage extends StatefulWidget {
  const WaitingListPage({super.key});
  @override
  State<WaitingListPage> createState() => _WaitingListPageState();
}

class _WaitingListPageState extends State<WaitingListPage> {
  String? doctorId;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).update({'status': status});
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).delete();
  }

  Color _statusColor(String s) =>
      {'confirme': const Color(0xFF10B981), 'en_attente': const Color(0xFFEA580C), 'en-attente': const Color(0xFFEA580C), 'annule': Colors.grey}[s] ?? const Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.access_time_filled, color: Color(0xFF2563EB), size: 26)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Liste d'Attente", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text("Patients en attente — $today", style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ]),
          ]),
          const SizedBox(height: 28),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: () {
                Query q = FirebaseFirestore.instance.collection('appointments');
                if (doctorId != null) q = q.where('doctorId', isEqualTo: doctorId);
                return q.orderBy('createdAt', descending: false).snapshots();
              }(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));

                final allDocs = snap.data?.docs ?? [];
                final todayDocs = allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['date'] ?? '').toString().startsWith(today) &&
                         (data['status'] != 'annule');
                }).toList();

                if (todayDocs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text("Aucun patient en attente aujourd'hui", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ]));
                }

                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Summary chips
                  Row(children: [
                    _chip('${todayDocs.length} total',   const Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    _chip('${todayDocs.where((d) => (d.data() as Map)['status'] == 'confirme').length} confirmés', const Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    _chip('${todayDocs.where((d) {final s=(d.data() as Map)['status']??''; return s=='en_attente'||s=='en-attente';}).length} en attente', const Color(0xFFEA580C)),
                  ]),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: todayDocs.length,
                      itemBuilder: (_, i) {
                        final doc    = todayDocs[i];
                        final d      = doc.data() as Map<String, dynamic>;
                        final status = d['status']?.toString() ?? 'en_attente';
                        final color  = _statusColor(status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border(left: BorderSide(color: color, width: 4)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Row(children: [
                            // Position number
                            Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), alignment: Alignment.center, child: Text('${i+1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['patientName'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 3),
                              Text('${d['time'] ?? '--'}  •  ${d['type'] ?? '--'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ])),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            // Actions
                            if (status != 'confirme')
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 22),
                                tooltip: 'Confirmer',
                                onPressed: () => _updateStatus(doc.id, 'confirme'),
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                              ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              tooltip: 'Supprimer',
                              onPressed: () => _delete(doc.id),
                              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
  );
}
