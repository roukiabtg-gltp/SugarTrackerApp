import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../doctor_settings_notifier.dart';

class EditPatientProfilePage extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> patientData;

  const EditPatientProfilePage({
    super.key,
    required this.patientId,
    required this.patientData,
  });

  @override
  State<EditPatientProfilePage> createState() => _EditPatientProfilePageState();
}

class _EditPatientProfilePageState extends State<EditPatientProfilePage> {
  final _db = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _phone;
  late TextEditingController _email;
  late TextEditingController _address;
  late TextEditingController _birthDate;
  late TextEditingController _bloodType;

  @override
  void initState() {
    super.initState();
    final p = widget.patientData;
    _firstName = TextEditingController(text: p['first_name']?.toString() ?? '');
    _lastName  = TextEditingController(text: p['last_name']?.toString() ?? '');
    _phone     = TextEditingController(text: p['phone']?.toString() ?? '');
    _email     = TextEditingController(text: p['email']?.toString() ?? '');
    _address   = TextEditingController(text: p['address']?.toString() ?? '');
    _birthDate = TextEditingController(text: p['birth_date']?.toString() ?? '');
    _bloodType = TextEditingController(text: p['blood_type']?.toString() ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _birthDate.dispose();
    _bloodType.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _db.child('users').child(widget.patientId).update({
        'first_name': _firstName.text.trim(),
        'last_name':  _lastName.text.trim(),
        'phone':      _phone.text.trim(),
        'email':      _email.text.trim(),
        'address':    _address.text.trim(),
        'birth_date': _birthDate.text.trim(),
        'blood_type': _bloodType.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('Saved successfully', 'تم الحفظ بنجاح', 'Enregistré avec succès')),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: Colors.grey),
          label: Text(
              t('Back', 'رجوع', 'Retour'),
              style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: _saving
                ? const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF3B82F6))))
                : ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                        t('Save', 'حفظ', 'Enregistrer'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    t('Edit Profile', 'تعديل الملف الشخصي', 'Modifier le profil'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C))),
                const SizedBox(height: 6),
                Text(
                    t('Update patient information below.',
                        'قم بتحديث معلومات المريض أدناه.',
                        'Mettez à jour les informations du patient.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),

                // ── First & Last Name ──
                Row(children: [
                  Expanded(
                      child: _field(
                          _firstName,
                          t('First Name', 'الاسم', 'Prénom'),
                          Icons.person_outline)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _field(
                          _lastName,
                          t('Last Name', 'اللقب', 'Nom'),
                          Icons.person_outline)),
                ]),
                const SizedBox(height: 16),

                // ── Phone ──
                _field(
                    _phone,
                    t('Phone', 'الهاتف', 'Téléphone'),
                    Icons.phone_outlined),
                const SizedBox(height: 16),

                // ── Email ──
                _field(
                    _email,
                    t('Email', 'البريد الإلكتروني', 'Email'),
                    Icons.mail_outline),
                const SizedBox(height: 16),

                // ── Address ──
                _field(
                    _address,
                    t('Address', 'العنوان', 'Adresse'),
                    Icons.location_on_outlined),
                const SizedBox(height: 16),

                // ── Birth Date & Blood Type ──
                Row(children: [
                  Expanded(
                      child: _field(
                          _birthDate,
                          t('Birth Date', 'تاريخ الميلاد', 'Date de naissance'),
                          Icons.cake_outlined,
                          hint: 'DD-MM-YYYY')),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _field(
                          _bloodType,
                          t('Blood Type', 'فصيلة الدم', 'Groupe sanguin'),
                          Icons.water_drop_outlined,
                          hint: 'A+, B-, O+')),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    String? hint,
  }) {
    return TextFormField(
      controller: c,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A202C)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}