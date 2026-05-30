import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_invoice_page.dart'; // استدعاء صفحة الإضافة الجديدة
import 'modifier_facture_page.dart';

class FacturePage extends StatefulWidget {
  const FacturePage({super.key});

  @override
  State<FacturePage> createState() => _FacturePageState();
}

class _FacturePageState extends State<FacturePage> {
  String? doctorUid;
  bool isLoading = true;

  Future<void> updateFactureStatus(String invoiceId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('invoices').doc(invoiceId).update({'status': status});
    } catch (e, st) {
      debugPrint('خطأ أثناء تحديث حالة الفاتورة ($invoiceId): $e');
      debugPrint('$st');
    }
  }

  // حذف فاتورة من Firestore
  Future<void> deleteFacture(String invoiceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('invoices') // تأكدي من اسم الـ collection في Firebase
          .doc(invoiceId)
          .delete();
    } catch (e) {
      debugPrint('خطأ أثناء حذف الفاتورة: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDoctorId();
  }

  Future<void> _fetchDoctorId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          doctorUid = doc['doctorId'];
          isLoading = false;
        });
      }
    }
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
          // الجزء العلوي: العنوان وزر إضافة فاتورة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Gestion des Factures", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text("Toutes les factures", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddInvoicePage(doctorUid: doctorUid!)),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Nouvelle Facture", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // جدول عرض الفواتير المجلوبة من Firestore
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('invoices')
                    .where('doctorId', isEqualTo: doctorUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Aucune facture trouvée."));

                  var docs = snapshot.data!.docs;
                  return SingleChildScrollView(
                    child: DataTable(
                      horizontalMargin: 30,
                      columnSpacing: 40,
                      headingRowHeight: 60,
                      dataRowMaxHeight: 80,
                      columns: const [
                        DataColumn(label: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                      ],
                      rows: docs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String invoiceId = doc.id;
                        bool isPaid = data['status'] == 'Payée';
                        final facture = {...data, 'id': invoiceId};

                        return DataRow(cells: [
                          DataCell(Text(data['patientName'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(data['description'] ?? '-')),
                          DataCell(Text("${data['amount'] ?? '0'} DA", style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(data['date'] ?? '-')),
                          // حالة الدفع الملونة (Payée بالأخضر / Impayée بالأحمر)
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data['status'] ?? 'Impayée',
                                style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    String currentStatus = data['status'] ?? 'Impayée';
                                    if (currentStatus == 'Impayée') {
                                      await updateFactureStatus(invoiceId, 'Payée');
                                    } else {
                                      await updateFactureStatus(invoiceId, 'Impayée');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (data['status'] ?? 'Impayée') == 'Impayée'
                                        ? const Color(0xFF00A86B)
                                        : Colors.red[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  icon: (data['status'] ?? 'Impayée') == 'Impayée'
                                      ? const Icon(Icons.check_circle_outline, size: 14)
                                      : const Icon(Icons.remove_circle_outline, size: 14),
                                  label: (data['status'] ?? 'Impayée') == 'Impayée'
                                      ? const Text("Marquer payée", style: TextStyle(fontSize: 12))
                                      : const Text("Marquer impayée", style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: Colors.blue),
                                  tooltip: "Modifier",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ModifierFacturePage(facture: facture),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                                  tooltip: "Supprimer",
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirmer la suppression"),
                                          content: const Text("Voulez-vous vraiment supprimer cette facture ?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text("Annuler"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await deleteFacture(invoiceId);
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ]);
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
}