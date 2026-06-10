// lib/secretary/secretary_settings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sucritere_settings_notifier.dart';

class SecretarySettingsPage extends StatefulWidget {
  const SecretarySettingsPage({super.key});
  @override
  State<SecretarySettingsPage> createState() => _SecretarySettingsPageState();
}

class _SecretarySettingsPageState extends State<SecretarySettingsPage> {

  static const _blue   = Color(0xFF2563EB);
  static const _border = Color(0xFFE8ECF4);

  // ── password controllers ───────────────────────────────────────────────
  final _oldCtrl  = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _oldVis    = false;
  bool _newVis    = false;
  bool _confVis   = false;
  bool _loadingPw = false;

  // ── forgot password ────────────────────────────────────────────────────
  bool _loadingReset = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  // ── changer mot de passe ───────────────────────────────────────────────
  Future<void> _changePassword() async {
    final old  = _oldCtrl.text.trim();
    final nw   = _newCtrl.text.trim();
    final conf = _confCtrl.text.trim();

    if (old.isEmpty || nw.isEmpty || conf.isEmpty) {
      _snack(ts('Fill all fields',
               'يرجى ملء جميع الحقول',
               'Remplissez tous les champs'), isError: true);
      return;
    }
    if (nw != conf) {
      _snack(ts('Passwords do not match',
               'كلمتا السر غير متطابقتين',
               'Les mots de passe ne correspondent pas'), isError: true);
      return;
    }
    if (nw.length < 6) {
      _snack(ts('Min 6 characters',
               'الحد الأدنى 6 أحرف',
               'Minimum 6 caractères'), isError: true);
      return;
    }

    setState(() => _loadingPw = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: old);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(nw);
      _oldCtrl.clear(); _newCtrl.clear(); _confCtrl.clear();
      _snack(ts('Password updated ✅',
               'تم تغيير كلمة السر ✅',
               'Mot de passe mis à jour ✅'));
    } on FirebaseAuthException catch (e) {
      _snack(
        e.code == 'wrong-password'
            ? ts('Wrong current password',
                 'كلمة السر الحالية غير صحيحة',
                 'Mot de passe actuel incorrect')
            : (e.message ?? 'Error'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loadingPw = false);
    }
  }

  // ── mot de passe oublié (envoyer email reset) ──────────────────────────
  Future<void> _forgotPassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      _snack(ts('Email not found', 'البريد غير موجود', 'Email introuvable'),
          isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(ts('Reset Password',
                       'إعادة تعيين كلمة السر',
                       'Réinitialiser le mot de passe')),
        content: Text(
          ts('We will send a reset link to:\n$email',
             'سنرسل رابط إعادة التعيين إلى:\n$email',
             'Nous enverrons un lien à :\n$email'),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ts('Cancel', 'إلغاء', 'Annuler'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(ts('Send', 'إرسال', 'Envoyer'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loadingReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack(ts('Reset email sent ✅ Check your inbox',
               'تم إرسال رابط الإعادة ✅ تفقد بريدك',
               'Email envoyé ✅ Vérifiez votre boîte mail'));
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Error', isError: true);
    } finally {
      if (mounted) setState(() => _loadingReset = false);
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
            final lang   = locale.languageCode;
            final isRtl  = lang == 'ar';

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Titre ─────────────────────────────────────────
                    Text(ts('Settings', 'الإعدادات', 'Paramètres'),
                        style: TextStyle(
                          fontSize: 26 * scale,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0D1117),
                        )),
                    const SizedBox(height: 6),
                    Text(
                      ts('Customize your experience',
                         'خصّص تجربتك',
                         'Personnalisez votre expérience'),
                      style: TextStyle(fontSize: 13 * scale, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    // ══ 1. APPARENCE ═══════════════════════════════════
                    _sectionTitle(
                        ts('Appearance', 'المظهر', 'Apparence'),
                        Icons.palette_outlined, scale, isDark),
                    const SizedBox(height: 14),
                    _card(isDark, child: Column(children: [

                      // Dark mode
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: secThemeMode,
                        builder: (_, m, __) => SwitchListTile(
                          title: Text(ts('Dark Mode', 'الوضع الليلي', 'Mode Sombre'),
                              style: TextStyle(
                                  fontSize: 14 * scale,
                                  color: isDark ? Colors.white : const Color(0xFF0D1117))),
                          value: m == ThemeMode.dark,
                          onChanged: (v) =>
                              setSecTheme(v ? ThemeMode.dark : ThemeMode.light),
                          activeColor: _blue,
                          subtitle: Text(
                            m == ThemeMode.dark
                                ? ts('Dark theme active',
                                     'الوضع الداكن مفعّل',
                                     'Thème sombre activé')
                                : ts('Light theme active',
                                     'الوضع الفاتح مفعّل',
                                     'Thème clair activé'),
                            style: TextStyle(
                                fontSize: 11.5 * scale,
                                color: Colors.grey.shade500),
                          ),
                          secondary: Icon(
                            m == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: m == ThemeMode.dark
                                ? const Color(0xFF7C83FD)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),

                      Divider(
                          color: isDark ? Colors.white12 : _border, height: 1),

                      // Font size slider
                      _fontSlider(scale, isDark),
                    ])),

                    const SizedBox(height: 28),

                    // ══ 2. LANGUE ═══════════════════════════════════════
                    _sectionTitle(
                        ts('Language', 'اللغة', 'Langue'),
                        Icons.language_rounded, scale, isDark),
                    const SizedBox(height: 14),
                    _card(isDark, child: Column(children: [
                      _langOption('fr', '🇫🇷', 'Français', lang, scale, isDark),
                      Divider(color: isDark ? Colors.white12 : _border, height: 1),
                      _langOption('en', '🇬🇧', 'English',  lang, scale, isDark),
                      Divider(color: isDark ? Colors.white12 : _border, height: 1),
                      _langOption('ar', '🇩🇿', 'العربية',  lang, scale, isDark),
                    ])),

                    const SizedBox(height: 28),

                    // ══ 3. SÉCURITÉ ═════════════════════════════════════
                    _sectionTitle(
                        ts('Security', 'الأمان', 'Sécurité'),
                        Icons.lock_outline_rounded, scale, isDark),
                    const SizedBox(height: 14),
                    _card(isDark, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // sous-titre
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                          child: Text(
                            ts('Change Password',
                               'تغيير كلمة السر',
                               'Changer le mot de passe'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14 * scale,
                              color: isDark ? Colors.white : const Color(0xFF0D1117),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
                          child: Text(
                            ts('Enter your current password to confirm',
                               'أدخل كلمة سرك الحالية للتحقق من هويتك',
                               'Entrez votre mot de passe actuel pour confirmer'),
                            style: TextStyle(
                                fontSize: 12 * scale, color: Colors.grey),
                          ),
                        ),

                        _pwField(
                          ctrl:     _oldCtrl,
                          label:    ts('Current Password',
                                       'كلمة السر الحالية',
                                       'Mot de passe actuel'),
                          visible:  _oldVis,
                          onToggle: () => setState(() => _oldVis = !_oldVis),
                          isDark: isDark, scale: scale,
                        ),
                        _pwField(
                          ctrl:     _newCtrl,
                          label:    ts('New Password',
                                       'كلمة السر الجديدة',
                                       'Nouveau mot de passe'),
                          visible:  _newVis,
                          onToggle: () => setState(() => _newVis = !_newVis),
                          isDark: isDark, scale: scale,
                        ),
                        _pwField(
                          ctrl:     _confCtrl,
                          label:    ts('Confirm New Password',
                                       'تأكيد كلمة السر',
                                       'Confirmer le mot de passe'),
                          visible:  _confVis,
                          onToggle: () => setState(() => _confVis = !_confVis),
                          isDark: isDark, scale: scale,
                        ),

                        // bouton changer
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loadingPw ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _loadingPw
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : Text(
                                      ts('Update Password',
                                         'تحديث كلمة السر',
                                         'Mettre à jour'),
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),

                        Divider(
                            color: isDark ? Colors.white12 : _border,
                            height: 1),

                        // ── Mot de passe oublié ────────────────────────
                        InkWell(
                          onTap: _loadingReset ? null : _forgotPassword,
                          borderRadius: const BorderRadius.only(
                              bottomLeft:  Radius.circular(18),
                              bottomRight: Radius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: _loadingReset
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.orange))
                                    : const Icon(Icons.lock_reset_outlined,
                                        color: Colors.orange, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ts('Forgot Password?',
                                       'نسيت كلمة السر؟',
                                       'Mot de passe oublié ?'),
                                    style: TextStyle(
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0D1117),
                                    ),
                                  ),
                                  Text(
                                    ts('Send reset link to your email',
                                       'إرسال رابط الإعادة إلى بريدك',
                                       'Envoyer un lien de réinitialisation'),
                                    style: TextStyle(
                                        fontSize: 11.5 * scale,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              )),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Colors.grey.shade400),
                            ]),
                          ),
                        ),
                      ],
                    )),

                    const SizedBox(height: 28),

                    // ══ 4. COMPTE ══════════════════════════════════════
                    _sectionTitle(
                        ts('Account', 'الحساب', 'Compte'),
                        Icons.person_outline_rounded, scale, isDark),
                    const SizedBox(height: 14),
                    _card(isDark, child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.email_outlined,
                              color: _blue, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ts('Email', 'البريد الإلكتروني', 'E-mail'),
                                style: TextStyle(
                                    fontSize: 12 * scale,
                                    color: Colors.grey)),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? '--',
                              style: TextStyle(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0D1117)),
                            ),
                          ],
                        )),
                      ]),
                    )),

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

  Widget _sectionTitle(String t, IconData icon, double scale, bool isDark) {
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
      Text(t, style: TextStyle(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0D1117),
      )),
    ]);
  }

  Widget _card(bool isDark, {required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E2130) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? Colors.white12 : _border),
      boxShadow: isDark
          ? []
          : [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _fontSlider(double scale, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.text_fields_rounded,
                color: Colors.purple, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ts('Font Size', 'حجم الخط', 'Taille du texte'),
                  style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0D1117))),
              Text(ts('Adjust text size', 'تحكم في حجم النص', 'Ajustez la taille'),
                  style: TextStyle(
                      fontSize: 11.5 * scale, color: Colors.grey.shade500)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ValueListenableBuilder<double>(
              valueListenable: secFontScale,
              builder: (_, s, __) => Text(
                '${(s * 100).round()}%',
                style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Text('A', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: secFontScale,
              builder: (_, s, __) => Slider(
                value: s,
                min: 0.8, max: 1.5,
                divisions: 7,
                activeColor: Colors.purple,
                inactiveColor: Colors.purple.withOpacity(0.15),
                onChanged: setSecFontScale,
              ),
            ),
          ),
          const Text('A', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ]),
        Center(
          child: Text(
            ts('Preview text', 'نص تجريبي', 'Texte aperçu'),
            style: TextStyle(
              fontSize: 14 * scale,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _langOption(
      String code, String flag, String name,
      String current, double scale, bool isDark) {
    final selected = current == code;
    return InkWell(
      onTap: () => setSecLocale(code),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(child: Text(name,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected
                    ? _blue
                    : (isDark ? Colors.white : const Color(0xFF0D1117)),
              ))),
          if (selected)
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                  color: _blue, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            )
          else
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300)),
            ),
        ]),
      ),
    );
  }

  Widget _pwField({
    required TextEditingController ctrl,
    required String       label,
    required bool         visible,
    required VoidCallback onToggle,
    required bool         isDark,
    required double       scale,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      child: TextField(
        controller: ctrl,
        obscureText: !visible,
        style: TextStyle(
          fontSize: 14 * scale,
          color: isDark ? Colors.white : const Color(0xFF0D1117),
        ),
        decoration: InputDecoration(
          labelText:  label,
          labelStyle: TextStyle(fontSize: 13 * scale, color: Colors.grey),
          filled:     true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF8F9FE),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.white12 : _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.5)),
          suffixIcon: IconButton(
            icon: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
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
