import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ModifierFacturePage extends StatefulWidget {
  final Map<String, dynamic> facture;

  const ModifierFacturePage({super.key, required this.facture});

  @override
  State<ModifierFacturePage> createState() => _ModifierFacturePageState();
}

class _ModifierFacturePageState extends State<ModifierFacturePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController patientController;
  late final TextEditingController descriptionController;
  late final TextEditingController amountController;
  late final String invoiceId;

  @override
  void initState() {
    super.initState();
    invoiceId = widget.facture['id'] as String;
    patientController = TextEditingController(text: widget.facture['patientName'] ?? '');
    descriptionController = TextEditingController(text: widget.facture['description'] ?? '');
    amountController = TextEditingController(text: widget.facture['amount']?.toString() ?? '');
  }

  @override
  void dispose() {
    patientController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> saveFacture() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('invoices').doc(invoiceId).update({
        'patientName': patientController.text.trim(),
        'description': descriptionController.text.trim(),
        'amount': amountController.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('خطأ أثناء حفظ التعديلات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la modification de la facture.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Modifier la facture', style: TextStyle(fontWeight: FontWeight.bold)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modifier les informations de la facture', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  const SizedBox(height: 30),
                  const Text('Patient', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: patientController,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) => val == null || val.isEmpty ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) => val == null || val.isEmpty ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Montant', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) => val == null || val.isEmpty ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: saveFacture,
                        child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 15),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler', style: TextStyle(color: Colors.black)),
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
