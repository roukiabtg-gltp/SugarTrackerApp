import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../doctor/doctor_main_layout.dart'; 
import 'signup_desktop.dart';

// ملاحظة: افترضنا وجود كلاس بسيط للترجمة اسمه AppLocalizations أو استعملنا خريطة نصوص بسيطة للتوضيح
class LoginDesktop extends StatefulWidget {
  const LoginDesktop({super.key});

  @override
  State<LoginDesktop> createState() => _LoginDesktopState();
}

class _LoginDesktopState extends State<LoginDesktop> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;

  // متغير للغة الحالية (الافتراضية العربية)
  String _currentLang = 'ar';

  // خريطة نصوص بسيطة للغات الثلاث (يمكنك لاحقاً نقلها لملفات JSON)
  final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'login': 'تسجيل الدخول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgot_pw': 'نسيت كلمة المرور؟',
      'btn_login': 'دخول',
      'no_account': 'ليس لديك حساب؟',
      'create_account': 'إنشاء حساب جديد',
      'app_desc': 'نظام إدارة ملفات المرضى المتكامل',
    },
    'fr': {
      'login': 'Connexion',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'forgot_pw': 'Mot de passe oublié ?',
      'btn_login': 'Se connecter',
      'no_account': "Vous n'avez pas de compte ?",
      'create_account': 'Créer un compte',
      'app_desc': 'Système intégré de gestion des dossiers patients',
    },
    'en': {
      'login': 'Login',
      'email': 'Email Address',
      'password': 'Password',
      'forgot_pw': 'Forgot Password?',
      'btn_login': 'Login',
      'no_account': "Don't have an account?",
      'create_account': 'Create New Account',
      'app_desc': 'Integrated Patient Records Management System',
    },
  };

  String _t(String key) => _localizedValues[_currentLang]![key]!;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError(_currentLang == 'ar' ? "يرجى إدخال البيانات" : "Please enter data");
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

        if (role == 'doctor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DoctorMainLayout()),
          );
        } else if (role == 'secretary') {
          _showError("واجهة السكرتيرة قيد التجهيز");
        }
      }
    } catch (e) {
      _showError(_currentLang == 'ar' ? "فشل الدخول: تأكد من البيانات" : "Login failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تحديد الاتجاه بناءً على اللغة
    TextDirection direction = _currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Stack(
          children: [
            Row(
              children: [
                // القسم الأيسر: واجهة ترحيبية
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0xFF0D47A1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.health_and_safety, size: 100, color: Colors.white),
                        const SizedBox(height: 20),
                        const Text(
                          "GlucoLink",
                          style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _t('app_desc'),
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // القسم الأيمن: نموذج الدخول
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Container(
                      width: 450,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('login'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 30),
                          
                          // Email Field
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: _t('email'),
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _isObscured,
                            decoration: InputDecoration(
                              labelText: _t('password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _isObscured = !_isObscured),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          
                          Align(
                            alignment: _currentLang == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {}, 
                              child: Text(_t('forgot_pw')),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(_t('btn_login'), style: const TextStyle(color: Colors.white, fontSize: 18)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // رابط إنشاء حساب جديد
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_t('no_account')),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                  );
                                },
                                child: Text(_t('create_account'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // زر تغيير اللغة في أعلى الزاوية (يتكيف مع الاتجاه)
            Positioned(
              top: 20,
              left: _currentLang == 'ar' ? 20 : null,
              right: _currentLang != 'ar' ? 20 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currentLang,
                    icon: const Icon(Icons.language, color: Color(0xFF0D47A1)),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _currentLang = newValue;
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text("العربية")),
                      DropdownMenuItem(value: 'fr', child: Text("Français")),
                      DropdownMenuItem(value: 'en', child: Text("English")),
                    ],
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