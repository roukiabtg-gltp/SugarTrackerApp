// lib/secretary/secretary_profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/sucritere_settings_notifier.dart';

class SecretaryProfilePage extends StatefulWidget {
  const SecretaryProfilePage({super.key});
  @override
  State<SecretaryProfilePage> createState() => _SecretaryProfilePageState();
}

class _SecretaryProfilePageState extends State<SecretaryProfilePage> {

  static const _blue = Color(0xFF2563EB);

  // ── données ────────────────────────────────────────────────────────────
  String _name    = '';
  String _email   = '';
  String _phone   = '';
  String _address = '';
  bool   _loading = true;
  bool   _saving  = false;

  // ── controllers édition ────────────────────────────────────────────────
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController();
    _phoneCtrl   = TextEditingController();
    _addressCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── charger profil ─────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!mounted) return;
    final data = doc.data() ?? {};
    setState(() {
      _name    = data['name']    ?? '';
      _email   = data['email']   ?? FirebaseAuth.instance.currentUser?.email ?? '';
      _phone   = data['phone']   ?? '';
      _address = data['address'] ?? '';
      _nameCtrl.text    = _name;
      _phoneCtrl.text   = _phone;
      _addressCtrl.text = _address;
      _loading = false;
    });
  }

  // ── sauvegarder ───────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name':    _nameCtrl.text.trim(),
        'phone':   _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      if (mounted) {
        setState(() {
          _name    = _nameCtrl.text.trim();
          _phone   = _phoneCtrl.text.trim();
          _address = _addressCtrl.text.trim();
        });
        _snack(ts('Profile updated ✅', 'تم تحديث الملف ✅', 'Profil mis à jour ✅'));
      }
    } catch (e) {
      _snack(ts('Error: $e', 'خطأ: $e', 'Erreur: $e'), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── initiales avatar ──────────────────────────────────────────────────
  String _initials(String name) {
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: secThemeMode,
      builder: (_, mode, __) => ValueListenableBuilder<Locale>(
        valueListenable: secLocale,
        builder: (_, locale, __) => ValueListenableBuilder<double>(
          valueListenable: secFontScale,
          builder: (_, scale, __) {
            final isDark = mode == ThemeMode.dark;
            final isRtl  = locale.languageCode == 'ar';

            if (_loading) {
              return Center(
                child: CircularProgressIndicator(color: _blue),
              );
            }

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Titre ───────────────────────────────────────────
                    Text(
                      ts('My Profile', 'ملفي الشخصي', 'Mon Profil'),
                      style: TextStyle(
                        fontSize: 26 * scale,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0D1117),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ts('Manage your personal information',
                         'إدارة معلوماتك الشخصية',
                         'Gérez vos informations personnelles'),
                      style: TextStyle(fontSize: 13 * scale, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    // ── Avatar + nom ─────────────────────────────────────
                    Center(
                      child: Column(children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _blue.withOpacity(0.15),
                            border: Border.all(color: _blue, width: 2.5),
                          ),
                          child: Center(
                            child: Text(
                              _initials(_name),
                              style: TextStyle(
                                fontSize: 32 * scale,
                                fontWeight: FontWeight.bold,
                                color: _blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _name.isEmpty
                              ? ts('Secretary', 'سكرتيرة', 'Secrétaire')
                              : _name,
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0D1117),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: _blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ts('Medical Secretary', 'سكرتيرة طبية', 'Secrétaire Médicale'),
                            style: TextStyle(
                              color: _blue,
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 36),

                    // ── Infos non-modifiables ────────────────────────────
                    _sectionTitle(
                      ts('Account Info', 'معلومات الحساب', 'Infos du compte'),
                      Icons.info_outline_rounded,
                      scale, isDark,
                    ),
                    const SizedBox(height: 14),
                    _infoCard(isDark, children: [
                      _infoRow(
                        icon: Icons.email_outlined,
                        iconColor: _blue,
                        label: ts('Email', 'البريد الإلكتروني', 'E-mail'),
                        value: _email,
                        scale: scale,
                        isDark: isDark,
                      ),
                      _divider(isDark),
                      _infoRow(
                        icon: Icons.badge_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        label: ts('Role', 'الدور', 'Rôle'),
                        value: ts('Medical Secretary', 'سكرتيرة طبية', 'Secrétaire Médicale'),
                        scale: scale,
                        isDark: isDark,
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // ── Infos modifiables ────────────────────────────────
                    _sectionTitle(
                      ts('Edit Information', 'تعديل المعلومات', 'Modifier les infos'),
                      Icons.edit_outlined,
                      scale, isDark,
                    ),
                    const SizedBox(height: 14),
                    _infoCard(isDark, children: [
                      _editField(
                        ctrl:    _nameCtrl,
                        label:   ts('Full Name', 'الاسم الكامل', 'Nom complet'),
                        icon:    Icons.person_outline,
                        isDark:  isDark,
                        scale:   scale,
                      ),
                      _editField(
                        ctrl:    _phoneCtrl,
                        label:   ts('Phone', 'الهاتف', 'Téléphone'),
                        icon:    Icons.phone_outlined,
                        isDark:  isDark,
                        scale:   scale,
                        keyboard: TextInputType.phone,
                      ),
                      _editField(
                        ctrl:    _addressCtrl,
                        label:   ts('Address', 'العنوان', 'Adresse'),
                        icon:    Icons.location_on_outlined,
                        isDark:  isDark,
                        scale:   scale,
                        isLast:  true,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Bouton sauvegarder ───────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                ts('Save Changes', 'حفظ التغييرات', 'Enregistrer'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Helpers
  // ══════════════════════════════════════════════════════════════════════

  Widget _sectionTitle(String title, IconData icon, double scale, bool isDark) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: _blue, size: 17),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          )),
    ]);
  }

  Widget _infoCard(bool isDark, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2130) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE8ECF4)),
        boxShadow: isDark
            ? []
            : [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(bool isDark) =>
      Divider(color: isDark ? Colors.white12 : const Color(0xFFE8ECF4), height: 1);

  Widget _infoRow({
    required IconData icon,
    required Color    iconColor,
    required String   label,
    required String   value,
    required double   scale,
    required bool     isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12 * scale,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0D1117))),
          ],
        )),
      ]),
    );
  }

  Widget _editField({
    required TextEditingController ctrl,
    required String   label,
    required IconData icon,
    required bool     isDark,
    required double   scale,
    TextInputType     keyboard = TextInputType.text,
    bool isLast = false,
  }) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: TextField(
          controller:  ctrl,
          keyboardType: keyboard,
          style: TextStyle(
            fontSize: 14 * scale,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
          decoration: InputDecoration(
            labelText:  label,
            labelStyle: TextStyle(fontSize: 13 * scale, color: Colors.grey),
            prefixIcon: Icon(icon, size: 20,
                color: isDark ? Colors.grey : Colors.grey.shade500),
            filled:    true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8F9FE),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8ECF4))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFE8ECF4))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _blue, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
      if (!isLast)
        Divider(
            color: isDark ? Colors.white12 : const Color(0xFFE8ECF4),
            height: 1),
    ]);
  }
}