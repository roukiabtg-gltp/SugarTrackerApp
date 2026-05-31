import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddInvoicePage extends StatefulWidget {
  final String doctorUid;
  const AddInvoicePage({super.key, required this.doctorUid});

  @override
  State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController(text: "Consultation générale");
  final amountController = TextEditingController(text: "50");
  
  String? selectedPatient;
  List<String> patientList = [];
  bool isLoadingPatients = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  // جلب قائمة المرضى تلقائياً من الفايربيز لعرضهم في الـ Dropdown
  Future<void> _fetchPatients() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorUid)
          .get();
      
      Set<String> patients = {};
      for (var doc in snap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['patientName'] != null) {
          patients.add(data['patientName']);
        }
      }

      setState(() {
        patientList = patients.toList();
        if (patientList.isNotEmpty) selectedPatient = patientList[0];
        isLoadingPatients = false;
      });
    } catch (e) {
      setState(() => isLoadingPatients = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Nouvelle Facture", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 600,
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Créer une facture pour un patient", style: TextStyle(color: Colors.grey, fontSize: 15)),
                  const SizedBox(height: 30),

                  // قائمة اختيار المريض
                  const Text("Patient", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  isLoadingPatients
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value: selectedPatient,
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: patientList.map((String patient) {
                            return DropdownMenuItem(value: patient, child: Text(patient));
                          }).toList(),
                          onChanged: (val) => setState(() => selectedPatient = val),
                          validator: (val) => val == null ? "Veuillez choisir un patient" : null,
                        ),
                  const SizedBox(height: 20),

                  // حقل الوصف
                  const Text("Description", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) => val!.isEmpty ? "Champ obligatoire" : null,
                  ),
                  const SizedBox(height: 20),

                  // حقل المبلغ
                  const Text("Montant (€)", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) => val!.isEmpty ? "Champ obligatoire" : null,
                  ),
                  const SizedBox(height: 40),

                  // الأزرار السفلى (إنشاء وإلغاء)
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && selectedPatient != null) {
                            // تسجيل الفاتورة الجديدة في Firestore بوضعية غير مدفوعة تلقائياً
                            await FirebaseFirestore.instance.collection('invoices').add({
                              'patientName': selectedPatient,
                              'description': descriptionController.text.trim(),
                              'amount': amountController.text.trim(),
                              'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                              'status': 'Impayée',
                              'doctorId': widget.doctorUid,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Créer Facture", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 15),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}