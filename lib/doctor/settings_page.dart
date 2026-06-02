// lib/doctor/settings_page.dart
// ═══════════════════════════════════════════════════════════
//  صفحة الإعدادات — GlucoLink Doctor
//  • تغيير كلمة السر (Firebase)
//  • اللغة: عربية / فرنسية / إنجليزية
//  • الوضع: Dark / Light
//  • حجم الخط: Slider
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../doctor_settings_notifier.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  // ── ألوان ──────────────────────────────────────────────
  static const _blue   = Color(0xFF1882FF);
  static const _border = Color(0xFFE8ECF4);

  // ── تغيير كلمة السر ────────────────────────────────────
  final _oldPassCtrl  = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _oldVisible  = false;
  bool _newVisible  = false;
  bool _confVisible = false;
  bool _loadingPass = false;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  // ── ترجمة بسيطة ────────────────────────────────────────
  String _t(String en, String ar, String fr) {
    final lang = doctorLocale.value.languageCode;
    if (lang == 'ar') return ar;
    if (lang == 'fr') return fr;
    return en;
  }

  // ── تغيير كلمة السر ────────────────────────────────────
  Future<void> _changePassword() async {
    final old  = _oldPassCtrl.text.trim();
    final nw   = _newPassCtrl.text.trim();
    final conf = _confPassCtrl.text.trim();

    if (old.isEmpty || nw.isEmpty || conf.isEmpty) {
      _snack(_t('Fill all fields', 'يرجى ملء جميع الحقول', 'Remplissez tous les champs'), isError: true);
      return;
    }
    if (nw != conf) {
      _snack(_t('Passwords do not match', 'كلمتا السر غير متطابقتين', 'Les mots de passe ne correspondent pas'), isError: true);
      return;
    }
    if (nw.length < 6) {
      _snack(_t('Min 6 characters', 'الحد الأدنى 6 أحرف', 'Minimum 6 caractères'), isError: true);
      return;
    }

    setState(() => _loadingPass = true);
    try {
      final user  = FirebaseAuth.instance.currentUser!;
      final cred  = EmailAuthProvider.credential(email: user.email!, password: old);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(nw);
      _oldPassCtrl.clear(); _newPassCtrl.clear(); _confPassCtrl.clear();
      _snack(_t('Password updated ✅', 'تم تغيير كلمة السر ✅', 'Mot de passe mis à jour ✅'));
    } on FirebaseAuthException catch (e) {
      _snack(e.code == 'wrong-password'
          ? _t('Wrong current password', 'كلمة السر الحالية غير صحيحة', 'Mot de passe actuel incorrect')
          : e.message ?? 'Error',
          isError: true);
    } finally {
      if (mounted) setState(() => _loadingPass = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: doctorThemeMode,
      builder: (_, mode, __) {
        return ValueListenableBuilder<Locale>(
          valueListenable: doctorLocale,
          builder: (_, locale, __) {
            return ValueListenableBuilder<double>(
              valueListenable: doctorFontScale,
              builder: (_, scale, __) {
                final isDark = mode == ThemeMode.dark;
                final lang   = locale.languageCode;
                final isRtl  = lang == 'ar';

                return Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Page Title ─────────────────────────────
                        Text(
                          _t('Settings', 'الإعدادات', 'Paramètres'),
                          style: TextStyle(
                            fontSize: 26 * scale,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0D1117),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _t('Customize your experience', 'خصّص تجربتك', 'Personnalisez votre expérience'),
                          style: TextStyle(fontSize: 13 * scale, color: Colors.grey),
                        ),
                        const SizedBox(height: 32),

                        // ── SECTION 1: Appearance ──────────────────
                        _sectionTitle(_t('Appearance', 'المظهر', 'Apparence'), Icons.palette_outlined, scale, isDark),
                        const SizedBox(height: 14),
                        _card(isDark, child: Column(children: [

                          // Dark / Light toggle
                          _settingRow(
                            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            iconColor: isDark ? const Color(0xFF7C83FD) : const Color(0xFFF59E0B),
                            label: _t('Dark Mode', 'الوضع الداكن', 'Mode sombre'),
                            sub: isDark
                                ? _t('Dark theme active', 'الوضع الداكن مفعّل', 'Thème sombre activé')
                                : _t('Light theme active', 'الوضع الفاتح مفعّل', 'Thème clair activé'),
                            scale: scale,
                            isDark: isDark,
                            trailing: Switch(
                              value: isDark,
                              onChanged: (v) => setDoctorTheme(v ? ThemeMode.dark : ThemeMode.light),
                              activeColor: _blue,
                            ),
                          ),

                          Divider(color: isDark ? Colors.white12 : _border, height: 1),

                          // Font size slider
                          _fontSliderRow(scale, isDark),
                        ])),

                        const SizedBox(height: 28),

                        // ── SECTION 2: Language ────────────────────
                        _sectionTitle(_t('Language', 'اللغة', 'Langue'), Icons.language_rounded, scale, isDark),
                        const SizedBox(height: 14),
                        _card(isDark, child: Column(children: [
                          _langOption('en', '🇬🇧', 'English',  'English',  lang, scale, isDark),
                          Divider(color: isDark ? Colors.white12 : _border, height: 1),
                          _langOption('fr', '🇫🇷', 'Français', 'Français', lang, scale, isDark),
                          Divider(color: isDark ? Colors.white12 : _border, height: 1),
                          _langOption('ar', '🇩🇿', 'العربية',  'العربية',  lang, scale, isDark),
                        ])),

                        const SizedBox(height: 28),

                        // ── SECTION 3: Security ────────────────────
                        _sectionTitle(_t('Security', 'الأمان', 'Sécurité'), Icons.lock_outline_rounded, scale, isDark),
                        const SizedBox(height: 14),
                        _card(isDark, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                _t('Change Password', 'تغيير كلمة السر', 'Changer le mot de passe'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14 * scale,
                                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text(
                                _t('Enter your current password to confirm identity',
                                   'أدخل كلمة سرك الحالية للتحقق من هويتك',
                                   'Entrez votre mot de passe actuel pour confirmer votre identité'),
                                style: TextStyle(fontSize: 12 * scale, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Old password
                            _passField(
                              ctrl: _oldPassCtrl,
                              label: _t('Current Password', 'كلمة السر الحالية', 'Mot de passe actuel'),
                              visible: _oldVisible,
                              onToggle: () => setState(() => _oldVisible = !_oldVisible),
                              isDark: isDark, scale: scale,
                            ),

                            // New password
                            _passField(
                              ctrl: _newPassCtrl,
                              label: _t('New Password', 'كلمة السر الجديدة', 'Nouveau mot de passe'),
                              visible: _newVisible,
                              onToggle: () => setState(() => _newVisible = !_newVisible),
                              isDark: isDark, scale: scale,
                            ),

                            // Confirm
                            _passField(
                              ctrl: _confPassCtrl,
                              label: _t('Confirm New Password', 'تأكيد كلمة السر', 'Confirmer le mot de passe'),
                              visible: _confVisible,
                              onToggle: () => setState(() => _confVisible = !_confVisible),
                              isDark: isDark, scale: scale,
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loadingPass ? null : _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: _loadingPass
                                      ? const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white))
                                      : Text(
                                          _t('Update Password', 'تحديث كلمة السر', 'Mettre à jour'),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14 * scale,
                                              fontWeight: FontWeight.w600),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        )),

                        const SizedBox(height: 28),

                        // ── SECTION 4: Account info ────────────────
                        _sectionTitle(_t('Account', 'الحساب', 'Compte'), Icons.person_outline_rounded, scale, isDark),
                        const SizedBox(height: 14),
                        _card(isDark, child: _settingRow(
                          icon: Icons.email_outlined,
                          iconColor: _blue,
                          label: _t('Email', 'البريد الإلكتروني', 'E-mail'),
                          sub: FirebaseAuth.instance.currentUser?.email ?? '--',
                          scale: scale,
                          isDark: isDark,
                          trailing: const SizedBox.shrink(),
                        )),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  //  Widget helpers
  // ════════════════════════════════════════════════════════

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

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2130) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.white12 : _border),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _settingRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sub,
    required double scale,
    required bool isDark,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0D1117))),
            Text(sub,
                style: TextStyle(
                    fontSize: 11.5 * scale,
                    color: Colors.grey.shade500)),
          ],
        )),
        trailing,
      ]),
    );
  }

  Widget _fontSliderRow(double scale, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.text_fields_rounded,
                color: Colors.purple, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Font Size', 'حجم الخط', 'Taille du texte'),
                style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0D1117)),
              ),
              Text(
                _t('Adjust text size across the app',
                   'تحكم في حجم النص في التطبيق',
                   'Ajustez la taille du texte dans l\'app'),
                style: TextStyle(fontSize: 11.5 * scale, color: Colors.grey.shade500),
              ),
            ],
          )),
          // مؤشر الحجم الحالي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(scale * 100).round()}%',
              style: const TextStyle(
                  color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Text('A', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Slider(
              value: scale,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              activeColor: Colors.purple,
              inactiveColor: Colors.purple.withOpacity(0.15),
              onChanged: (v) => setDoctorFontScale(v),
            ),
          ),
          const Text('A', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ]),
        // مثال نصي
        Center(
          child: Text(
            _t('Preview text', 'نص تجريبي', 'Texte de prévisualisation'),
            style: TextStyle(
              fontSize: 14 * scale,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _langOption(String code, String flag, String nameEn,
      String nameLoc, String current, double scale, bool isDark) {
    final bool selected = current == code;
    return InkWell(
      onTap: () => setDoctorLocale(code),
      borderRadius: BorderRadius.circular(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(
            nameLoc,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? _blue : (isDark ? Colors.white : const Color(0xFF0D1117)),
            ),
          )),
          if (selected)
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: _blue, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            )
          else
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _passField({
    required TextEditingController ctrl,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required bool isDark,
    required double scale,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: ctrl,
        obscureText: !visible,
        style: TextStyle(
          fontSize: 14 * scale,
          color: isDark ? Colors.white : const Color(0xFF0D1117),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13 * scale, color: Colors.grey),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF8F9FE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? Colors.white12 : _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _blue, width: 1.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey, size: 20,
            ),
            onPressed: onToggle,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
