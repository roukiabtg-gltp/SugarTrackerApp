// lib/auth/signup_desktop.dart
// ═══════════════════════════════════════════════════════════
//  صفحة إنشاء حساب جديد — خاصة بالأطباء فقط (GlucoLink)
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specController = TextEditingController();
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePass = true;
  String _currentLang = 'ar'; // جعلت اللغة الافتراضية العربية لتطابق نظام اللوقين الداعم للـ RTL
  
  // الرتبة ثابتة دائماً "doctor" لأن السكرتيرة يتم تسجيلها من طرف الطبيب حصراً
  final String _selectedRole = 'doctor'; 

  // ── Animation controller (حركة الدخول للصفحة، بنفس روح login) ──
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final Map<String, Map<String, String>> _texts = {
    'fr': {
      'title': 'Créer un Compte',
      'sub': 'Rejoignez la plateforme GlucoLink en tant que médecin',
      'app_desc': 'La plateforme intégrée de suivi des patients diabétiques',
      'name': 'Nom complet',
      'email': 'Email professionnel',
      'spec': 'Spécialité médicale',
      'id': 'Numéro d\'Ordre National',
      'pass': 'Mot de passe',
      'btn': 'S\'inscrire maintenant',
      'have_acc': 'J\'ai déjà un compte',
      'have_acc_prefix': 'Vous avez déjà un compte ? ',
      'have_acc_action': 'Connexion',
      'required': 'Champ obligatoire',
    },
    'ar': {
      'title': 'إنشاء حساب طبيب',
      'sub': 'انضم إلى منصة GlucoLink الطبية كـمحترف صحي',
      'app_desc': 'المنصة المتكاملة لمتابعة مرضى السكري',
      'name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني المهني',
      'spec': 'التخصص الطبي',
      'id': 'رقم القيد في نقابة الأطباء',
      'pass': 'كلمة المرور',
      'btn': 'إنشاء الحساب',
      'have_acc': 'لديك حساب بالفعل؟ تسجيل الدخول',
      'have_acc_prefix': 'لديك حساب بالفعل؟ ',
      'have_acc_action': 'تسجيل الدخول',
      'required': 'هذا الحقل مطلوب',
    },
    'en': {
      'title': 'Create Doctor Account',
      'sub': 'Join the GlucoLink platform as a medical professional',
      'app_desc': 'The integrated platform for diabetes patient follow-up',
      'name': 'Full Name',
      'email': 'Professional Email',
      'spec': 'Medical Specialty',
      'id': 'Medical License Number',
      'pass': 'Password',
      'btn': 'Register Now',
      'have_acc': 'Already have an account? Login',
      'have_acc_prefix': 'Already have an account? ',
      'have_acc_action': 'Login',
      'required': 'Required field',
    }
  };

  // أسماء اللغات المعروضة في القائمة المنسدلة (نفس أسلوب login)
  final Map<String, String> _langNames = {
    'ar': 'العربية',
    'fr': 'Français',
    'en': 'English',
  };

  @override
  void initState() {
    super.initState();
    // نفس حركة الدخول (fade + slide) المستعملة في صفحة login
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specController.dispose();
    _idController.dispose();
    _passController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // تبديل اللغة الحالية
  void _changeLang(String lang) {
    if (lang == _currentLang) return;
    setState(() => _currentLang = lang);
  }

  // قائمة منسدلة أنيقة لاختيار اللغة، نفس أسلوب login بالضبط
  void _showLangMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      items: _langNames.entries.map((entry) {
        final isSelected = entry.key == _currentLang;
        return PopupMenuItem<String>(
          value: entry.key,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF3B82F6))
              else
                const SizedBox(width: 18),
              const SizedBox(width: 10),
              Text(
                entry.value,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) _changeLang(value);
    });
  }

  // زر تبديل اللغة (أيقونة 🌐 داخل دائرة)، نفس تصميم login بالضبط
  Widget _buildLanguageSwitcher() {
    return Builder(
      builder: (btnContext) => _HoverScale(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final RenderBox box = btnContext.findRenderObject() as RenderBox;
            final Offset position = box.localToGlobal(Offset(0, box.size.height));
            _showLangMenu(btnContext, position);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 6),
                Text(
                  _currentLang.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF3B82F6), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await AuthService().signUpUser(
      email: _emailController.text.trim(),
      password: _passController.text.trim(),
      name: _nameController.text.trim(),
      role: _selectedRole,
      specialty: _specController.text.trim(),
      idProf: _idController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    var t = _texts[_currentLang]!;
    bool isRtl = _currentLang == 'ar';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: isRtl
                  ? [
                      // بالعربي: زر اللغة على اليسار، زر الرجوع على اليمين
                      _buildLanguageSwitcher(),
                      const Spacer(),
                      BackButton(color: isDark ? Colors.white : Colors.black),
                    ]
                  : [
                      // بالفرنسي/الإنجليزي: زر الرجوع على اليسار، زر اللغة على اليمين
                      BackButton(color: isDark ? Colors.white : Colors.black),
                      const Spacer(),
                      _buildLanguageSwitcher(),
                    ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الشق الترحيبي (نفس بنية login بالضبط: Expanded يأخذ نصف العرض ويمتد لكامل الارتفاع)
                if (MediaQuery.of(context).size.width > 1000)
                  Expanded(
                    flex: 1,
                    child: _buildSideIllustration(),
                  ),

                // شق الفورم
                Expanded(
                  flex: 1,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Container(
                            width: 500,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30)],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Directionality(
                                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: Text(
                                        t['title']!,
                                        key: ValueKey('title_$_currentLang'),
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: Text(
                                        t['sub']!,
                                        key: ValueKey('sub_$_currentLang'),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(height: 35),

                                    // حقول إدخال البيانات الموحدة للطبيب مباشرة
                                    _buildField(t['name']!, Icons.person_outline, _nameController, t['required']!),
                                    const SizedBox(height: 18),
                                    _buildField(t['email']!, Icons.alternate_email, _emailController, t['required']!),
                                    const SizedBox(height: 18),
                                    _buildField(t['spec']!, Icons.stars_outlined, _specController, t['required']!),
                                    const SizedBox(height: 18),
                                    _buildField(t['id']!, Icons.badge_outlined, _idController, t['required']!),
                                    const SizedBox(height: 18),
                                    _buildField(t['pass']!, Icons.lock_outline, _passController, t['required']!, isPass: true),
                                    const SizedBox(height: 35),

                                    _isLoading 
                                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                                      : SizedBox(
                                          width: double.infinity,
                                          child: _HoverScale(
                                            child: ElevatedButton(
                                              onPressed: _handleSignUp,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF3B82F6),
                                                minimumSize: const Size(double.infinity, 55),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                elevation: 0,
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  t['btn']!,
                                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: _HoverScale(
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () => Navigator.pop(context),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            child: RichText(
                                              text: TextSpan(
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                children: [
                                                  TextSpan(
                                                    text: t['have_acc_prefix']!,
                                                    style: const TextStyle(color: Colors.black87),
                                                  ),
                                                  TextSpan(
                                                    text: t['have_acc_action']!,
                                                    style: const TextStyle(color: Color(0xFF3B82F6)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, String requiredText, {bool isPass = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? _obscurePass : false,
      validator: (v) => v == null || v.trim().isEmpty ? requiredText : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSideIllustration() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.monitor_heart_rounded, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            const Text("GlucoLink", style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _texts[_currentLang]!['app_desc']!,
                  key: ValueKey('app_desc_$_currentLang'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── ويدجت صغيرة لإضافة حركة "تكبير خفيف" عند المرور بالماوس (hover) على الزر، بنفس روح login ──
class _HoverScale extends StatefulWidget {
  final Widget child;
  const _HoverScale({required this.child});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}