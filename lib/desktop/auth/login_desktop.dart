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

class _LoginDesktopState extends State<LoginDesktop> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController(); // متحكم خاص بنافذة استعادة كلمة المرور
  
  bool _isLoading = false;
  bool _isObscured = true;
  String _currentLang = 'ar';
  
  // المتغير المسؤول عن تحديد نوع المستخدم الحالي (doctor أو secretary)
  String _selectedRole = 'doctor'; 

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
  };

  String _t(String key) => _localizedValues[_currentLang]?[key] ?? key;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  // ميزة "نسيت كلمة المرور" عبر نافذة منبثقة تفاعلية واحترافية
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // الشق الأيمن الترحيبي (الجمالي الملون للـ Desktop)
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.monitor_heart_rounded, size: 80, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    const Text("GlucoLink", style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(_t('app_desc'), style: const TextStyle(color: Colors.white70, fontSize: 18)),
                  ],
                ),
              ),
            ),
            
            // الشق الأيسر الخاص ببيانات تسجيل الدخول
            Expanded(
              flex: 1,
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: 450,
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_t('welcome'), style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                        Text(_t('login'), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                                  onTap: () => setState(() => _selectedRole = 'doctor'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'doctor' ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _selectedRole == 'doctor' ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                                    ),
                                    child: Center(
                                      child: Text(_t('doctor'), style: TextStyle(fontWeight: FontWeight.bold, color: _selectedRole == 'doctor' ? const Color(0xFF3B82F6) : const Color(0xFF64748B))),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedRole = 'secretary'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'secretary' ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _selectedRole == 'secretary' ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                                    ),
                                    child: Center(
                                      child: Text(_t('secretary'), style: TextStyle(fontWeight: FontWeight.bold, color: _selectedRole == 'secretary' ? const Color(0xFF3B82F6) : const Color(0xFF64748B))),
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
                        
                        const SizedBox(height: 24),
                        
                        // إظهار خيار إنشاء حساب جديد فقط إذا كان المحدد هو الطبيب
                        if (_selectedRole == 'doctor')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                          ),
                      ],
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