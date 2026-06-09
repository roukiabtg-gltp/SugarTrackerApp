

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

class _SignUpScreenState extends State<SignUpScreen> {
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

  final Map<String, Map<String, String>> _texts = {
    'fr': {
      'title': 'Créer un Compte',
      'sub': 'Rejoignez la plateforme GlucoLink en tant que médecin',
      'name': 'Nom complet',
      'email': 'Email professionnel',
      'spec': 'Spécialité médicale',
      'id': 'Numéro d\'Ordre National',
      'pass': 'Mot de passe',
      'btn': 'S\'inscrire maintenant',
      'have_acc': 'J\'ai déjà un compte',
      'required': 'Champ obligatoire',
    },
    'ar': {
      'title': 'إنشاء حساب طبيب',
      'sub': 'انضم إلى منصة GlucoLink الطبية كـمحترف صحي',
      'name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني المهني',
      'spec': 'التخصص الطبي',
      'id': 'رقم القيد في نقابة الأطباء',
      'pass': 'كلمة المرور',
      'btn': 'تسجيل الحساب البنكي',
      'have_acc': 'لديك حساب بالفعل؟ تسجيل الدخول',
      'required': 'هذا الحقل مطلوب',
    },
    'en': {
      'title': 'Create Doctor Account',
      'sub': 'Join the GlucoLink platform as a medical professional',
      'name': 'Full Name',
      'email': 'Professional Email',
      'spec': 'Medical Specialty',
      'id': 'Medical License Number',
      'pass': 'Password',
      'btn': 'Register Now',
      'have_acc': 'Already have an account? Login',
      'required': 'Required field',
    }
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specController.dispose();
    _idController.dispose();
    _passController.dispose();
    super.dispose();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        actions: [_buildLangPicker(), const SizedBox(width: 20)],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (MediaQuery.of(context).size.width > 1000) _buildSideIllustration(),
              Container(
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
                        Text(t['title']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                        const SizedBox(height: 4),
                        Text(t['sub']!, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
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
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
                          : ElevatedButton(
                              onPressed: _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(t['btn']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(t['have_acc']!, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSideIllustration() {
    return Container(
      width: 400,
      height: 730, // متناسق تماماً مع زيادة أبعاد حقول الطبيب الإجبارية
      decoration: const BoxDecoration(
        color: Color(0xFF0D47A1),
        borderRadius: BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.health_and_safety, size: 100, color: Colors.white),
          SizedBox(height: 20),
          Text("GlucoLink", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text("Gestion intelligente pour les professionnels de santé.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildLangPicker() {
    return DropdownButton<String>(
      value: _currentLang,
      underline: const SizedBox(),
      icon: const Icon(Icons.language, color: Color(0xFF0D47A1)),
      onChanged: (v) => setState(() => _currentLang = v!),
      items: const [
        DropdownMenuItem(value: 'ar', child: Text(" AR ", style: TextStyle(fontWeight: FontWeight.bold))),
        DropdownMenuItem(value: 'fr', child: Text(" FR ", style: TextStyle(fontWeight: FontWeight.bold))),
        DropdownMenuItem(value: 'en', child: Text(" EN ", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }
}
