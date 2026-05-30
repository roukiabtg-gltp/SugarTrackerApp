import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModifierFacturePage extends StatefulWidget {
  final dynamic facture; // تمرير كائن الفاتورة الحالية هنا

  const ModifierFacturePage({Key? key, required this.facture}) : super(key: key);

  @override
  State<ModifierFacturePage> createState() => _ModifierFacturePageState();
}

class _ModifierFacturePageState extends State<ModifierFacturePage> {
  late TextEditingController _descriptionController;
  late TextEditingController _montantController;
  late String selectedStatus;
  late String patientName;

  final List<String> statuses = ['Payée', 'Impayée'];

  @override
  void initState() {
    super.initState();
    // تهيئة الحقول بالبيانات الحالية للفاتورة القادمة من الجدول
    patientName = widget.facture.patientName ?? widget.facture['patientName'] ?? 'Inconnu';
    _descriptionController = TextEditingController(
        text: widget.facture.description ?? widget.facture['description'] ?? '');
    _montantController = TextEditingController(
        text: widget.facture.montant?.toString() ?? widget.facture['montant']?.toString() ?? '');
    selectedStatus = widget.facture.status ?? widget.facture['status'] ?? 'Impayée';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  // دالة تحديث البيانات في Firebase Firestore
  Future<void> _enregistrerModification() async {
    try {
      final double? montant = double.tryParse(_montantController.text);
      if (montant == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez saisir un montant valide")),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('factures')
          .doc(widget.facture.id ?? widget.facture.documentId) // تأكدي من مسمى حقل الـ ID عندك
          .update({
        'description': _descriptionController.text,
        'montant': montant,
        'status': selectedStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Facture modifiée avec succès")),
      );
      Navigator.pop(context); // العودة لجدول الفواتير بعد الحفظ
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la modification: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Modifier Facture",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 650), // نفس أبعاد بوكس المواعيد المتناسق
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // اسم المريض (ثابت لا يتغير مثل تصميم الموعد)
                Text(
                  "Patient: $patientName",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 24),

                // حقل الوصف (Description)
                const Text("Description", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // حقل المبلغ بالـ DA (Montant)
                const Text("Montant (DA)", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _montantController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                    ),
                    suffixText: "DA",
                  ),
                ),
                const SizedBox(height: 20),

                // قائمة اختيار الحالة (Statut)
                const Text("Statut", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                    ),
                  ),
                  items: statuses.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // شريط الأزرار التحتية (مطابق تماماً للمواعيد)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _enregistrerModification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Enregistrer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                          ),
                          child: const Text("Annuler", style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}