import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../services/auth_service.dart';
import '../../doctor/doctor_main_layout.dart'; 
import '../../secretary/nurse_main_layout.dart'; 
import 'signup_desktop.dart';

class LoginDesktop extends StatefulWidget {
  const LoginDesktop({super.key});

  @override
  State<LoginDesktop> createState() => _LoginDesktopState();
}

class _LoginDesktopState extends State<LoginDesktop> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController(); // متحكم خاص بنافذة استعادة كلمة المرور
  
  bool _isLoading = false;
  bool _isObscured = true;
  String _currentLang = 'ar';
  
  // المتغير المسؤول عن تحديد نوع المستخدم الحالي (doctor أو secretary)
  String _selectedRole = 'doctor'; 

  // ── Animation controllers (حركة الدخول للصفحة) ──
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'login': 'تسجيل الدخول',
      'welcome': 'مرحباً بك مجدداً',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'btn_login': 'دخول للنظام',
      'no_account': 'ليس لديك حساب طبيب؟',
      'signup': 'إنشاء حساب جديد',
      'app_desc': 'المنصة المتكاملة لمتابعة مرضى السكري',
      'forgot_password': 'نسيت كلمة المرور؟',
      'reset_link_sent': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني ✅',
      'enter_email': 'أدخل بريدك الإلكتروني لاستعادة الحساب',
      'send': 'إرسال الرابط',
      'cancel': 'إلغاء',
      'doctor': 'طبيب',
      'secretary': 'سكرتيرة / ممرض',
      'input_reset_email': 'البريد الإلكتروني المسجل للساب',
    },
    'fr': {
      'login': 'Connexion',
      'welcome': 'Bon retour parmi nous',
      'email': 'Adresse e-mail',
      'password': 'Mot de passe',
      'btn_login': 'Se connecter',
      'no_account': "Vous n'avez pas de compte ?",
      'signup': 'Créer un compte',
      'app_desc': 'La plateforme intégrée de suivi des patients diabétiques',
      'forgot_password': 'Mot de passe oublié ?',
      'reset_link_sent': 'Le lien de réinitialisation a été envoyé à votre e-mail ✅',
      'enter_email': 'Entrez votre e-mail pour récupérer votre compte',
      'send': 'Envoyer le lien',
      'cancel': 'Annuler',
      'doctor': 'Médecin',
      'secretary': 'Secrétaire / Infirmier',
      'input_reset_email': 'E-mail enregistré du compte',
    },
    'en': {
      'login': 'Login',
      'welcome': 'Welcome back',
      'email': 'Email address',
      'password': 'Password',
      'btn_login': 'Sign in',
      'no_account': "Don't have a doctor account?",
      'signup': 'Create new account',
      'app_desc': 'The integrated platform for diabetes patient follow-up',
      'forgot_password': 'Forgot password?',
      'reset_link_sent': 'The password reset link has been sent to your email ✅',
      'enter_email': 'Enter your email to recover your account',
      'send': 'Send link',
      'cancel': 'Cancel',
      'doctor': 'Doctor',
      'secretary': 'Secretary / Nurse',
      'input_reset_email': 'Registered account email',
    },
  };

  // أسماء اللغات المعروضة في القائمة المنسدلة
  final Map<String, String> _langNames = {
    'ar': 'العربية',
    'fr': 'Français',
    'en': 'English',
  };

  String _t(String key) => _localizedValues[_currentLang]?[key] ?? key;

  // اتجاه النص حسب اللغة المختارة
  TextDirection get _textDirection =>
      _currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    // إعداد حركة الدخول (fade + slide) عند فتح الصفحة
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
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // تبديل اللغة الحالية
  void _changeLang(String lang) {
    if (lang == _currentLang) return;
    setState(() => _currentLang = lang);
  }

  // قائمة منسدلة أنيقة لاختيار اللغة، تظهر أسفل الأيقونة
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

  // زر تبديل اللغة (أيقونة 🌐 داخل دائرة) مكان الدائرة الصفراء السابقة
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

  // ميزة "نسيت كلمة المرور" عبر نافذة منبثقة تفاعلية واحترافية
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: _textDirection,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(_t('forgot_password'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t('enter_email'), style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: _resetEmailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF3B82F6)),
                  hintText: 'example@email.com',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _resetEmailController.clear();
                Navigator.pop(context);
              },
              child: Text(_t('cancel'), style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                String email = _resetEmailController.text.trim();
                if (email.isEmpty) {
                  _showError("يرجى كتابة البريد الإلكتروني أولاً");
                  return;
                }
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (mounted) {
                    Navigator.pop(context);
                    _resetEmailController.clear();
                    _showSuccess(_t('reset_link_sent'));
                  }
                } catch (e) {
                  _showError("تأكد من صحة البريد الإلكتروني المكتوب أو اتصالك بالشبكة");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_t('send'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("يرجى ملء كافة الحقول");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        String role = await AuthService().getUserRole(user.uid);

        // التحقق الإضافي: التأكد من مطابقة دور الحساب مع الواجهة المختارة لزيادة الأمان
        if (role == 'doctor' && _selectedRole == 'doctor') {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const DoctorMainLayout())
          );
        } 
        else if ((role == 'nurse' || role == 'secretary') && _selectedRole == 'secretary') {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const NurseMainLayout())
          );
        } else {
          // إذا حاول الدخول بحساب سكرتيرة في واجهة الطبيب أو العكس
          _showError("عذراً، هذا الحساب غير مسجل كـ ${_t(_selectedRole)} في النظام");
          await FirebaseAuth.instance.signOut(); // تسجيل الخروج التلقائي للحماية
        }
      }
    } catch (e) {
       print("LOGIN PAGE ERROR: $e");
       _showError("خطأ في تسجيل الدخول: تأكد من بيانات الاعتماد الخاصة بك");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green),
    );
  }

  Widget _customTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _isObscured : false,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isObscured = !_isObscured),
            ) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // الشق الأيمن الترحيبي (الجمالي الملون للـ Desktop)
            Expanded(
              flex: 1,
              child: TweenAnimationBuilder<double>(
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _t('app_desc'),
                          key: ValueKey(_currentLang),
                          style: const TextStyle(color: Colors.white70, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // الشق الأيسر الخاص ببيانات تسجيل الدخول
            Expanded(
              flex: 1,
              child: Center(
                child: SingleChildScrollView(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        width: 450,
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── صف علوي: زر تبديل اللغة مكان الدائرة الصفراء ──
                            // بالعربي: يسار الشاشة | بالفرنسي/الإنجليزي: يمين الشاشة
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Align(
                                alignment: _currentLang == 'ar'
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Directionality(
                                  textDirection: _textDirection,
                                  child: _buildLanguageSwitcher(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _t('welcome'),
                                key: ValueKey('welcome_$_currentLang'),
                                style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _t('login'),
                                key: ValueKey('login_$_currentLang'),
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // ── أداة اختيار نوع الحساب المحترفة (Role Selector) ──
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => setState(() => _selectedRole = 'doctor'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeOut,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'doctor' ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: _selectedRole == 'doctor' ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                                        ),
                                        child: Center(
                                          child: AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 250),
                                            style: TextStyle(fontWeight: FontWeight.bold, color: _selectedRole == 'doctor' ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
                                            child: Text(_t('doctor')),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => setState(() => _selectedRole = 'secretary'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeOut,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'secretary' ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: _selectedRole == 'secretary' ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                                        ),
                                        child: Center(
                                          child: AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 250),
                                            style: TextStyle(fontWeight: FontWeight.bold, color: _selectedRole == 'secretary' ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
                                            child: Text(_t('secretary')),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            _customTextField(controller: _emailController, label: _t('email'), icon: Icons.email_outlined),
                            const SizedBox(height: 24),
                            _customTextField(controller: _passwordController, label: _t('password'), icon: Icons.lock_outline_rounded, isPassword: true),
                            
                            // رابط نسيت كلمة المرور لكلتا الفئتين
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: Text(_t('forgot_password'), style: const TextStyle(color: Color(0xFF64748B))),
                              ),
                            ),

                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: _HoverScale(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin, 
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isLoading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(_t('btn_login'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // إظهار خيار إنشاء حساب جديد فقط إذا كان المحدد هو الطبيب
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _selectedRole == 'doctor'
                                ? Wrap(
                                    key: const ValueKey('signup_row'),
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(_t('no_account'), style: const TextStyle(color: Color(0xFF64748B))),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                          );
                                        },
                                        child: Text(
                                          _t('signup'),
                                          style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox(key: ValueKey('empty_row'), height: 0),
                            ),
                          ],
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
    );
  }
}

// ── ويدجت صغيرة لإضافة حركة "تكبير خفيف" عند المرور بالماوس (hover) على الأزرار ──
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