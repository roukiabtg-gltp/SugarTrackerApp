import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fst;
import 'package:firebase_database/firebase_database.dart';
import '../doctor_settings_notifier.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({super.key});
  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  String _section = 'Staff';
  final String? _dId = FirebaseAuth.instance.currentUser?.uid;
  final _db = FirebaseDatabase.instance.ref();
  final _fs = fst.FirebaseFirestore.instance;

  static const _blue   = Color(0xFF1882FF);
  static const _red    = Color(0xFFE53935);
  static const _bg     = Color(0xFFF5F7FB);
  static const _white  = Colors.white;
  static const _border = Color(0xFFE8ECF4);

  // ── Staff controllers ───────────────────────────
  final _sName  = TextEditingController();
  final _sEmail = TextEditingController();
  final _sPass  = TextEditingController();
  bool _sLoading  = false;
  bool _sPassVis  = false;

  // ── Patient controllers ─────────────────────────
  final _pFirst   = TextEditingController();
  final _pLast    = TextEditingController();
  final _pEmail   = TextEditingController();
  final _pPhone   = TextEditingController();
  final _pPass    = TextEditingController();
  String _pGender = 'Male';
  String _pBlood  = 'A+';
  bool _pLoading  = false;
  bool _pPassVis  = false;

  @override
  void dispose() {
    _sName.dispose(); _sEmail.dispose(); _sPass.dispose();
    _pFirst.dispose(); _pLast.dispose(); _pEmail.dispose();
    _pPhone.dispose(); _pPass.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? _red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('Administration','الإدارة','Administration'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1117))),
            const SizedBox(height: 6),
            Text(t('Manage staff and patients','إدارة الطاقم والمرضى','Gérer le personnel et les patients'),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 28),

            Expanded(child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sidebar(),
                const SizedBox(width: 24),
                Expanded(child: SingleChildScrollView(child: _content())),
              ],
            )),
          ],
        ),
      ),
    );
  }

  // ── Sidebar ─────────────────────────────────────
  Widget _sidebar() {
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _sItem(Icons.people_outline_rounded,        t('Staff Management','إدارة الطاقم','Gestion du personnel'), "Staff"),
          _sItem(Icons.person_add_outlined,           t('Create Patient','إنشاء مريض','Créer un patient'),   "Patient"),
          _sItem(Icons.manage_accounts_outlined,      t('Manage Data','إدارة البيانات','Gérer les données'),      "Data"),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sItem(IconData icon, String label, String key) {
    final sel = _section == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        selected: sel,
        selectedTileColor: _blue.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, size: 19, color: sel ? _blue : Colors.grey.shade500),
        title: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              color: sel ? _blue : Colors.grey.shade700,
            )),
        onTap: () => setState(() => _section = key),
      ),
    );
  }

  // ── Content Router ───────────────────────────────
  Widget _content() {
    switch (_section) {
      case "Staff":   return _staffSection();
      case "Patient": return _patientSection();
      case "Data":    return _dataSection();
      default:        return const SizedBox();
    }
  }

  // ════════════════════════════════════════════════
  //  STAFF MANAGEMENT
  // ════════════════════════════════════════════════
  Widget _staffSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secHeader(t('Current Staff','أعضاء الطاقم الحاليين','Personnel actuel'), Icons.badge_outlined, _blue),
            const SizedBox(height: 16),
            StreamBuilder<fst.QuerySnapshot>(
              stream: _fs.collection('users')
                  .where('doctorId', isEqualTo: _dId)
                  .where('role', isEqualTo: 'nurse')
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _empty(t('No staff accounts yet','لا توجد حسابات طاقم بعد','Aucun compte de personnel pour le moment'), Icons.person_off_outlined);
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final d = doc.data() as Map<String, dynamic>;
                    return _staffTile(
                      docId: doc.id,
                      name:  d['name']  ?? '--',
                      email: d['email'] ?? '--',
                      role:  d['specialty'] ?? 'Nurse',
                    );
                  },
                );
              },
            ),
          ],
        )),

        const SizedBox(height: 20),

        _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secHeader(t('Add New Staff Account','إضافة حساب طاقم جديد','Ajouter un compte de personnel'), Icons.person_add_outlined, _blue),
            const SizedBox(height: 6),
            Text(t('Creates a login account for your nurse or secretary.','ينشئ حساب تسجيل الدخول للممرضة أو السكرتيرة.','Crée un compte de connexion pour votre infirmière ou secrétaire.'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(child: _tf(t('Full Name','الاسم الكامل','Nom complet'), _sName, icon: Icons.badge_outlined)),
              const SizedBox(width: 14),
              Expanded(child: _tf(t('Email','البريد الإلكتروني','Email'), _sEmail, icon: Icons.email_outlined, keyboard: TextInputType.emailAddress)),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: 300,
              child: _tf(t('Initial Password','كلمة المرور الأولية','Mot de passe initial'), _sPass,
                  icon: Icons.lock_outline,
                  obscure: !_sPassVis,
                  suffix: IconButton(
                    icon: Icon(_sPassVis ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _sPassVis = !_sPassVis),
                  )),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _sLoading ? null : _createStaff,
              icon: _sLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(t('Create Staff Account','إنشاء حساب طاقم','Créer un compte de personnel'), style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _staffTile({required String docId, required String name, required String email, required String role}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: _blue.withOpacity(0.1),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
              style: const TextStyle(color: _blue, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(role, style: const TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: t('Remove staff account','إزالة حساب الطاقم','Supprimer le compte du personnel'),
          icon: const Icon(Icons.delete_outline_rounded, color: _red, size: 20),
          onPressed: () => _confirmDelete(
            title: "Remove $name?",
            sub: "This will delete their account from Firestore. Their Firebase Auth account remains active.",
            onConfirm: () async {
              await _fs.collection('users').doc(docId).delete();
              _snack("$name removed");
            },
          ),
        ),
      ]),
    );
  }

  // إنشاء حساب الطاقم بدون تسجيل خروج الطبيب الحركي
  Future<void> _createStaff() async {
    if (_sName.text.trim().isEmpty || _sEmail.text.trim().isEmpty || _sPass.text.trim().length < 6) {
      _snack(t('Fill all fields (password min 6 chars)','املأ جميع الحقول (كلمة المرور 6 أحرف على الأقل)','Remplissez tous les champs (mot de passe min 6 caractères)'), err: true);
      return;
    }
    setState(() => _sLoading = true);
    
    FirebaseApp? tempApp;
    try {
      // حل مشكلة تفادي تسجيل الخروج التلقائي للطبيب
      tempApp = await Firebase.initializeApp(
        name: 'SecondaryAppStaff',
        options: Firebase.app().options,
      );
      
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: _sEmail.text.trim(),
        password: _sPass.text.trim(),
      );

      await _fs.collection('users').doc(cred.user!.uid).set({
        'uid':       cred.user!.uid,
        'doctorId':  _dId,
        'name':      _sName.text.trim(),
        'email':     _sEmail.text.trim(),
        'role':      'nurse',
        'specialty': 'Nurse Assistant',
        'createdAt': fst.FieldValue.serverTimestamp(),
      });

      _sName.clear(); _sEmail.clear(); _sPass.clear();
      _snack(t('Staff account created ✅','تم إنشاء حساب الطاقم ✅','Compte du personnel créé ✅'));
    } catch (e) {
      _snack("Error: $e", err: true);
    } finally {
      if (tempApp != null) await tempApp.delete(); // إغلاق الاتصال المؤقت
      if (mounted) setState(() => _sLoading = false);
    }
  }

  // ════════════════════════════════════════════════
  //  CREATE PATIENT
  // ════════════════════════════════════════════════
  Widget _patientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secHeader(t('Linked Patients','المرضى المرتبطون','Patients liés'), Icons.people_outline_rounded, _blue),
            const SizedBox(height: 16),
            StreamBuilder<DatabaseEvent>(
              stream: _db.child('users').orderByChild('doctorId').equalTo(_dId).onValue,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.snapshot.value == null) {
                  return _empty("No patients linked yet", Icons.person_search_outlined);
                }
                final raw = snap.data!.snapshot.value as Map;
                final patients = raw.entries.toList();
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final e = patients[index];
                    final d = Map<String, dynamic>.from(e.value as Map);
                    final nm = '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim();
                    return _patientTile(
                      uid:   e.key.toString(),
                      name:  nm.isEmpty ? 'Patient' : nm,
                      email: d['email'] ?? '--',
                      phone: d['phone'] ?? '--',
                    );
                  },
                );
              },
            ),
          ],
        )),

        const SizedBox(height: 20),

        _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secHeader(t('Create Patient Account','إنشاء حساب مريض','Créer un compte patient'), Icons.person_add_alt_1_outlined, _blue),
            const SizedBox(height: 6),
            Text(t('Creates a mobile app account linked to you.','ينشئ حساب تطبيق جوال مرتبطًا بك.','Crée un compte d’application mobile lié à vous.'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(child: _tf(t('First Name','الاسم الأول','Prénom'), _pFirst, icon: Icons.person_outline)),
              const SizedBox(width: 14),
              Expanded(child: _tf(t('Last Name','اسم العائلة','Nom de famille'), _pLast, icon: Icons.person_outline)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _tf(t('Email','البريد الإلكتروني','Email'), _pEmail, icon: Icons.email_outlined, keyboard: TextInputType.emailAddress)),
              const SizedBox(width: 14),
              Expanded(child: _tf(t('Phone','الهاتف','Téléphone'), _pPhone, icon: Icons.phone_outlined, keyboard: TextInputType.phone)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _dropdown(
                label: t('Gender','الجنس','Genre'),
                value: _pGender,
                items: const ['Male', 'Female'],
                onChanged: (v) => setState(() => _pGender = v!),
              )),
              const SizedBox(width: 14),
              Expanded(child: _dropdown(
                label: t('Blood Type','فصيلة الدم','Groupe sanguin'),
                value: _pBlood,
                items: const ['A+','A-','B+','B-','AB+','AB-','O+','O-'],
                onChanged: (v) => setState(() => _pBlood = v!),
              )),
              const SizedBox(width: 14),
              Expanded(child: _tf(t('Password','كلمة المرور','Mot de passe'), _pPass,
                  icon: Icons.lock_outline,
                  obscure: !_pPassVis,
                  suffix: IconButton(
                    icon: Icon(_pPassVis ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _pPassVis = !_pPassVis),
                  ))),
            ]),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pLoading ? null : _createPatient,
              icon: _pLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(t('Create Patient Account','إنشاء حساب مريض','Créer un compte patient'), style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        )),
      ],
    );
  }

  Widget _patientTile({required String uid, required String name, required String email, required String phone}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text("$email  •  $phone", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        )),
        IconButton(
          tooltip: t('Remove patient link','إزالة رابط المريض','Supprimer le lien du patient'),
          icon: const Icon(Icons.link_off_rounded, color: _red, size: 20),
          onPressed: () => _confirmDelete(
            title: "Unlink $name?",
            sub: "This removes the doctor link. The patient account will not be deleted.",
            onConfirm: () async {
              await _db.child('users/$uid/doctorId').remove();
              _snack(t('$name unlinked','$name تم فك ارتباطه','$name dissocié'));
            },
          ),
        ),
      ]),
    );
  }

  // إنشاء حساب المريض بدون تسجيل خروج الطبيب
  Future<void> _createPatient() async {
    if (_pFirst.text.trim().isEmpty || _pEmail.text.trim().isEmpty || _pPass.text.trim().length < 6) {
      _snack(t('Fill required fields (password min 6)','املأ الحقول المطلوبة (كلمة المرور 6 أحرف على الأقل)','Remplissez les champs obligatoires (mot de passe min 6)'), err: true);
      return;
    }
    setState(() => _pLoading = true);
    
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'SecondaryAppPatient',
        options: Firebase.app().options,
      );
      
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: _pEmail.text.trim(),
        password: _pPass.text.trim(),
      );

      await _db.child('users/${cred.user!.uid}').set({
        'first_name': _pFirst.text.trim(),
        'last_name':  _pLast.text.trim(),
        'email':      _pEmail.text.trim(),
        'phone':      _pPhone.text.trim(),
        'gender':     _pGender,
        'blood_type': _pBlood,
        'role':       'patient',
        'doctorId':   _dId,
        'created_at': ServerValue.timestamp,
      });

      _pFirst.clear(); _pLast.clear(); _pEmail.clear(); _pPhone.clear(); _pPass.clear();
      _snack(t('Patient account created ✅','تم إنشاء حساب المريض ✅','Compte patient créé ✅'));
    } catch (e) {
      _snack("Error: $e", err: true);
    } finally {
      if (tempApp != null) await tempApp.delete();
      if (mounted) setState(() => _pLoading = false);
    }
  }

  // ════════════════════════════════════════════════
  //  MANAGE DATA
  // ════════════════════════════════════════════════
  Widget _dataSection() {
    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secHeader(t('Manage Data','إدارة البيانات','Gérer les données'), Icons.manage_accounts_outlined, _blue),
        const SizedBox(height: 16),

        StreamBuilder<DatabaseEvent>(
          stream: _db.child('users').orderByChild('doctorId').equalTo(_dId).onValue,
          builder: (_, snap) {
            int cnt = 0;
            if (snap.hasData && snap.data!.snapshot.value != null) {
              cnt = (snap.data!.snapshot.value as Map).length;
            }
            return _dataRow(Icons.people_outline_rounded, t('Total Patients','إجمالي المرضى','Total Patients'), "$cnt ${t('patients','مرضى','patients')}", Colors.blue);
          },
        ),
        const Divider(height: 20),

        StreamBuilder<fst.QuerySnapshot>(
          stream: _fs.collection('users').where('doctorId', isEqualTo: _dId).where('role', isEqualTo: 'nurse').snapshots(),
          builder: (_, snap) {
            final cnt = snap.data?.docs.length ?? 0;
            return _dataRow(Icons.badge_outlined, t('Staff Members','أعضاء الطاقم','Membres du personnel'), "$cnt ${t('accounts','حسابات','comptes')}", Colors.purple);
          },
        ),
        const Divider(height: 20),

        StreamBuilder<fst.QuerySnapshot>(
          stream: _fs.collection('appointments').where('doctorId', isEqualTo: _dId).snapshots(),
          builder: (_, snap) {
            final cnt = snap.data?.docs.length ?? 0;
            return _dataRow(Icons.calendar_today_outlined, t('Total Appointments','إجمالي المواعيد','Total des rendez-vous'), "$cnt ${t('appointments','مواعيد','rendez-vous')}", Colors.green);
          },
        ),
      ],
    ));
  }

  Widget _dataRow(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  // ════════════════════════════════════════════════
  //  Confirm Delete Dialog
  // ════════════════════════════════════════════════
  void _confirmDelete({required String title, required String sub, required Future<void> Function() onConfirm}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: _red, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        ]),
        content: Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Cancel','إلغاء','Annuler')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(t('Confirm','تأكيد','Confirmer'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Shared Widgets
  // ════════════════════════════════════════════════
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _secHeader(String title, IconData icon, Color color) => Row(children: [
    Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 17),
    ),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1117))),
  ]);

  Widget _empty(String msg, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Column(children: [
        Icon(icon, size: 36, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(msg, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    ),
  );

  Widget _tf(String label, TextEditingController ctrl, {IconData? icon, TextInputType? keyboard, bool obscure = false, Widget? suffix}) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    obscureText: obscure,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      prefixIcon: icon != null ? Icon(icon, size: 17, color: Colors.grey.shade400) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FE),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _blue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
  );

  Widget _dropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) => DropdownButtonFormField<String>(
    value: value,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      filled: true,
      fillColor: const Color(0xFFF8F9FE),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _blue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    items: items.map((e) => DropdownMenuItem(value: e, child: Text(_menuLabel(e), style: const TextStyle(fontSize: 13)))).toList(),
  );
}

String _menuLabel(String value) {
  switch (value) {
    case 'Male': return t('Male','ذكر','Homme');
    case 'Female': return t('Female','أنثى','Femme');
    default: return value;
  }
}