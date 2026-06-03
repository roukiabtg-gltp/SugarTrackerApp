// ════════════════════════════════════════════════════════════════════════
// DESKTOP ▸ lib/doctor/doctor_profile_page.dart  ✅ نسخة نهائية
// ════════════════════════════════════════════════════════════════════════
// - حُذف: Doctor Code Card  (موجود في Dashboard)
// - حُذف: Practice Overview (موجود في Dashboard)
// - صُلح: تحميل الصورة — يستخدم image_picker بدل file_picker
//         + عرض صورة الشبكة مع loading indicator
// - صُلح: save يستخدم set(merge:true) — يعمل حتى لو Document جديد
// - صُلح: حقول About Me و Clinic تظهر بشكل صحيح وتُحفظ
// ════════════════════════════════════════════════════════════════════════
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fst;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../doctor_settings_notifier.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});
  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _fs      = fst.FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final String?  _uid = FirebaseAuth.instance.currentUser?.uid;

  final _nameCtrl      = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _bioCtrl       = TextEditingController();
  final _idProfCtrl    = TextEditingController();
  final _clinicCtrl    = TextEditingController();
  final _cityCtrl      = TextEditingController();

  bool    _editing   = false;
  bool    _saving    = false;
  bool    _uploading = false;
  bool    _loading   = true;
  String? _photoUrl;

  static const _blue   = Color(0xFF1882FF);
  static const _border = Color(0xFFE8ECF4);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _specialtyCtrl, _phoneCtrl, _emailCtrl,
                     _bioCtrl, _idProfCtrl, _clinicCtrl, _cityCtrl]) c.dispose();
    super.dispose();
  }

  // ── Load ─────────────────────────────────────────────────────────────
  Future<void> _load() async {
    if (_uid == null) { setState(() => _loading = false); return; }
    try {
      final doc = await _fs.collection('users').doc(_uid).get();
      if (!mounted) return;
      if (doc.exists) {
        final d = doc.data()!;
        _nameCtrl.text      = d['name']?.toString()      ?? '';
        _specialtyCtrl.text = d['specialty']?.toString() ?? '';
        _phoneCtrl.text     = d['phone']?.toString()     ?? '';
        _emailCtrl.text     = d['email']?.toString()
            ?? FirebaseAuth.instance.currentUser?.email ?? '';
        _bioCtrl.text       = d['bio']?.toString()       ?? '';
        _idProfCtrl.text    = d['idProf']?.toString()    ?? '';
        _clinicCtrl.text    = d['clinic']?.toString()    ?? '';
        _cityCtrl.text      = d['city']?.toString()      ?? '';
        _photoUrl           = d['photoUrl']?.toString();
      } else {
        _emailCtrl.text = FirebaseAuth.instance.currentUser?.email ?? '';
      }
    } catch (e) {
      _snack('Error loading: $e', err: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Save ─────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_uid == null) return;
    setState(() => _saving = true);
    try {
      await _fs.collection('users').doc(_uid).set({
        'name'      : _nameCtrl.text.trim(),
        'specialty' : _specialtyCtrl.text.trim(),
        'phone'     : _phoneCtrl.text.trim(),
        'email'     : _emailCtrl.text.trim(),
        'bio'       : _bioCtrl.text.trim(),
        'idProf'    : _idProfCtrl.text.trim(),
        'clinic'    : _clinicCtrl.text.trim(),
        'city'      : _cityCtrl.text.trim(),
        'role'      : 'doctor',
        'updatedAt' : fst.FieldValue.serverTimestamp(),
      }, fst.SetOptions(merge: true));
      if (mounted) setState(() { _editing = false; _saving = false; });
      _snack('Profile saved ✅');
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _snack('Save error: $e', err: true);
    }
  }

  // ── Upload Photo ──────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    if (_uploading) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image, withData: true,
        dialogTitle: 'Select profile photo',
      );
      if (result == null || result.files.isEmpty) return;
      final Uint8List? bytes = result.files.first.bytes;
      if (bytes == null || bytes.isEmpty || !mounted) return;

      setState(() => _uploading = true);

      // ✅ رفع الصورة إلى Firebase Storage
      final ref = _storage.ref('doctor_photos/$_uid.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      // حفظ الـ URL في Firestore
      await _fs.collection('users').doc(_uid).set(
          {'photoUrl': url}, fst.SetOptions(merge: true));

      if (mounted) setState(() { _photoUrl = url; _uploading = false; });
      _snack('Photo updated ✅');
    } catch (e) {
      if (mounted) setState(() => _uploading = false);
      if (e.toString().contains('storage') || e.toString().contains('unauthorized')) {
        _snack('Enable Firebase Storage in console:\n storage.rules → allow read, write', err: true);
      } else {
        _snack('Photo error: $e', err: true);
      }
    }
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: err ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: err ? 4 : 2),
    ));
  }

  // ════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: doctorThemeMode,
      builder: (_, mode, __) => ValueListenableBuilder<double>(
        valueListenable: doctorFontScale,
        builder: (_, scale, __) {
          final dark = mode == ThemeMode.dark;
          return Scaffold(
            backgroundColor: dark ? const Color(0xFF0F1117) : const Color(0xFFF5F7FB),
            body: _loading
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // ── Header ──────────────────────────────────────
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('My Profile', style: TextStyle(
                          fontSize: 26 * scale, fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : const Color(0xFF0D1117))),
                        _editing
                            ? Row(children: [
                                _outBtn('Cancel', () {
                                  setState(() => _editing = false);
                                  _load();
                                }),
                                const SizedBox(width: 10),
                                _fillBtn(
                                  label: _saving ? 'Saving...' : 'Save Changes',
                                  icon: _saving
                                      ? const SizedBox(width: 15, height: 15,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.check, size: 16, color: Colors.white),
                                  onTap: _saving ? null : _save, scale: scale),
                              ])
                            : _fillBtn(
                                label: 'Edit Profile',
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                                onTap: () => setState(() => _editing = true),
                                scale: scale),
                      ]),
                      const SizedBox(height: 28),

                      // ── Body ────────────────────────────────────────
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        // ─ Left: Photo Card ────────────────────────────
                        SizedBox(width: 260, child: _photoCard(dark, scale)),

                        const SizedBox(width: 24),

                        // ─ Right: Info Cards ───────────────────────────
                        Expanded(child: Column(children: [
                          _infoCard(dark, scale),
                          const SizedBox(height: 16),
                          _bioCard(dark, scale),
                          const SizedBox(height: 16),
                          _clinicCard(dark, scale),
                        ])),
                      ]),
                    ]),
                  ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  //  Photo Card
  // ════════════════════════════════════════════════════════════════════
  Widget _photoCard(bool dark, double scale) {
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase() : 'D';

    return _card(dark, child: Column(children: [
      const SizedBox(height: 28),

      // ── Avatar + camera button ───────────────────────────────────
      Stack(alignment: Alignment.bottomRight, children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _blue.withOpacity(0.1),
            border: Border.all(color: _blue.withOpacity(0.25), width: 3),
          ),
          child: ClipOval(
            child: _photoUrl != null && _photoUrl!.isNotEmpty
                // ✅ صورة حقيقية مع loading + error fallback
                ? Image.network(
                    _photoUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                              : null,
                          color: _blue, strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(initial, style: TextStyle(
                          fontSize: 42 * scale, fontWeight: FontWeight.bold, color: _blue)),
                    ),
                  )
                : Center(
                    child: Text(initial, style: TextStyle(
                        fontSize: 42 * scale, fontWeight: FontWeight.bold, color: _blue)),
                  ),
          ),
        ),

        // زر الكاميرا
        GestureDetector(
          onTap: _uploading ? null : _pickPhoto,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _uploading ? Colors.grey.shade400 : _blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: _uploading
                ? const Padding(padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 17),
          ),
        ),
      ]),

      const SizedBox(height: 14),

      // الاسم والتخصص
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          _nameCtrl.text.isEmpty ? 'Doctor' : _nameCtrl.text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17 * scale, fontWeight: FontWeight.w700,
              color: dark ? Colors.white : const Color(0xFF0D1117))),
      ),
      const SizedBox(height: 4),
      Text(
        _specialtyCtrl.text.isEmpty ? 'Specialist' : _specialtyCtrl.text,
        style: TextStyle(fontSize: 13 * scale, color: Colors.grey)),

      // Professional ID badge
      if (_idProfCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: _blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Text('ID: ${_idProfCtrl.text}',
              style: TextStyle(fontSize: 11 * scale, color: _blue, fontWeight: FontWeight.w600))),
      ],

      const SizedBox(height: 12),
      const Divider(indent: 20, endIndent: 20),
      const SizedBox(height: 8),

      // Contact info
      if (_emailCtrl.text.isNotEmpty)
        _iconRow(Icons.email_outlined,          _emailCtrl.text,    scale),
      if (_phoneCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 5),
        _iconRow(Icons.phone_outlined,          _phoneCtrl.text,    scale),
      ],
      if (_clinicCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 5),
        _iconRow(Icons.local_hospital_outlined, _clinicCtrl.text,   scale),
      ],
      if (_cityCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 5),
        _iconRow(Icons.location_city_outlined,  _cityCtrl.text,     scale),
      ],

      const SizedBox(height: 22),
    ]));
  }

  Widget _iconRow(IconData icon, String text, double scale) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 13, color: Colors.grey.shade400),
      const SizedBox(width: 5),
      Flexible(child: Text(text, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11 * scale, color: Colors.grey))),
    ]),
  );

  // ════════════════════════════════════════════════════════════════════
  //  Info Card
  // ════════════════════════════════════════════════════════════════════
  Widget _infoCard(bool dark, double scale) => _card(dark, child: Padding(
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _cardTitle('Personal Information', Icons.person_outline_rounded, dark, scale),
      const SizedBox(height: 18),
      _editing
          ? Column(children: [
              Row(children: [
                Expanded(child: _field('Full Name',      _nameCtrl,      dark, scale, icon: Icons.badge_outlined)),
                const SizedBox(width: 14),
                Expanded(child: _field('Specialty',      _specialtyCtrl, dark, scale, icon: Icons.medical_services_outlined)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _field('Phone',           _phoneCtrl,    dark, scale, icon: Icons.phone_outlined, kb: TextInputType.phone)),
                const SizedBox(width: 14),
                Expanded(child: _field('Professional ID', _idProfCtrl,   dark, scale, icon: Icons.fingerprint_rounded)),
              ]),
            ])
          : Column(children: [
              Row(children: [
                Expanded(child: _tile('Full Name',      _nameCtrl.text.isEmpty      ? '--' : _nameCtrl.text,      Icons.badge_outlined,          dark, scale)),
                Expanded(child: _tile('Specialty',      _specialtyCtrl.text.isEmpty ? '--' : _specialtyCtrl.text, Icons.medical_services_outlined, dark, scale)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _tile('Phone',          _phoneCtrl.text.isEmpty     ? '--' : _phoneCtrl.text,     Icons.phone_outlined,           dark, scale)),
                Expanded(child: _tile('Professional ID',_idProfCtrl.text.isEmpty    ? '--' : _idProfCtrl.text,    Icons.fingerprint_rounded,      dark, scale)),
              ]),
            ]),
    ]),
  ));

  // ════════════════════════════════════════════════════════════════════
  //  Bio Card
  // ════════════════════════════════════════════════════════════════════
  Widget _bioCard(bool dark, double scale) => _card(dark, child: Padding(
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _cardTitle('About Me', Icons.notes_outlined, dark, scale),
      const SizedBox(height: 14),
      _editing
          ? TextField(
              controller: _bioCtrl, maxLines: 4,
              style: TextStyle(fontSize: 13 * scale,
                  color: dark ? Colors.white : const Color(0xFF0D1117)),
              decoration: _decor('Write a short bio...', dark))
          : Text(
              _bioCtrl.text.isEmpty
                  ? 'No bio yet. Tap Edit Profile to add one.'
                  : _bioCtrl.text,
              style: TextStyle(
                fontSize: 13 * scale, height: 1.65,
                color: _bioCtrl.text.isEmpty
                    ? Colors.grey.shade400
                    : (dark ? Colors.white70 : Colors.grey.shade700))),
    ]),
  ));

  // ════════════════════════════════════════════════════════════════════
  //  Clinic Card
  // ════════════════════════════════════════════════════════════════════
  Widget _clinicCard(bool dark, double scale) => _card(dark, child: Padding(
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _cardTitle('Clinic & Location', Icons.local_hospital_outlined, dark, scale),
      const SizedBox(height: 18),
      _editing
          ? Row(children: [
              Expanded(child: _field('Clinic / Hospital', _clinicCtrl, dark, scale, icon: Icons.business_outlined)),
              const SizedBox(width: 14),
              Expanded(child: _field('City',              _cityCtrl,   dark, scale, icon: Icons.location_city_outlined)),
            ])
          : Row(children: [
              Expanded(child: _tile('Clinic / Hospital',
                  _clinicCtrl.text.isEmpty ? '--' : _clinicCtrl.text,
                  Icons.business_outlined, dark, scale)),
              Expanded(child: _tile('City',
                  _cityCtrl.text.isEmpty ? '--' : _cityCtrl.text,
                  Icons.location_city_outlined, dark, scale)),
            ]),
    ]),
  ));

  // ════════════════════════════════════════════════════════════════════
  //  Shared Widgets
  // ════════════════════════════════════════════════════════════════════
  Widget _card(bool dark, {required Widget child}) => Container(
    width: double.infinity,
    margin: EdgeInsets.zero,
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF1E2130) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: dark ? Colors.white12 : _border),
      boxShadow: dark ? [] : [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
      ],
    ),
    child: child,
  );

  Widget _cardTitle(String title, IconData icon, bool dark, double scale) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: _blue, size: 17)),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w700,
            color: dark ? Colors.white : const Color(0xFF0D1117))),
      ]);

  Widget _tile(String label, String value, IconData icon, bool dark, double scale) =>
      Container(
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10 * scale, color: Colors.grey)),
            Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 13 * scale, fontWeight: FontWeight.w600,
                color: dark ? Colors.white : const Color(0xFF0D1117))),
          ])),
        ]),
      );

  Widget _field(String label, TextEditingController ctrl, bool dark, double scale,
      {IconData? icon, TextInputType? kb}) =>
      TextField(
        controller: ctrl, keyboardType: kb,
        style: TextStyle(fontSize: 13 * scale,
            color: dark ? Colors.white : const Color(0xFF0D1117)),
        decoration: _decor(label, dark, icon: icon),
      );

  InputDecoration _decor(String label, bool dark, {IconData? icon}) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
    prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey.shade400) : null,
    filled: true,
    fillColor: dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FE),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white12 : _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _outBtn(String label, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.grey, side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
    child: Text(label),
  );

  Widget _fillBtn({required String label, required Widget icon,
      required VoidCallback? onTap, required double scale}) =>
      ElevatedButton.icon(
        onPressed: onTap, icon: icon,
        label: Text(label, style: TextStyle(color: Colors.white, fontSize: 13 * scale)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
}
