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
  String _currentLang = 'fr';
  
  // المتغير الجديد لتحديد الرتبة
  String _selectedRole = 'doctor'; 

  final Map<String, Map<String, String>> _texts = {
    'fr': {
      'title': 'Créer un Compte',
      'sub': 'Rejoignez la plateforme GlucoLink',
      'name': 'Nom complet',
      'email': 'Email professionnel',
      'spec': 'Spécialité médicale',
      'id': 'Numéro d\'Ordre National',
      'pass': 'Mot de passe',
      'btn': 'S\'inscrire maintenant',
      'have_acc': 'J\'ai déjà un compte',
      'doctor': 'Médecin',
      'secretary': 'Secrétaire',
      'role_selection': 'Je suis un(e) :',
    },
    'ar': {
      'title': 'إنشاء حساب جديد',
      'sub': 'انضم إلى منصة GlucoLink الطبية',
      'name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'spec': 'التخصص الطبي',
      'id': 'رقم القيد في نقابة الأطباء',
      'pass': 'كلمة المرور',
      'btn': 'تسجيل الحساب',
      'have_acc': 'لديك حساب بالفعل؟',
      'doctor': 'طبيب',
      'secretary': 'سكرتير(ة)',
      'role_selection': 'أنا عبارة عن:',
    },
    'en': {
      'title': 'Create Account',
      'sub': 'Join the GlucoLink platform',
      'name': 'Full Name',
      'email': 'Professional Email',
      'spec': 'Medical Specialty',
      'id': 'Medical License Number',
      'pass': 'Password',
      'btn': 'Register Now',
      'have_acc': 'Already have an account?',
      'doctor': 'Doctor',
      'secretary': 'Secretary',
      'role_selection': 'I am a:',
    }
  };

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // ملاحظة: هنا نمرر الـ Role لخدمة الـ Firebase
    final success = await AuthService().signUpUser(
      email: _emailController.text.trim(),
      password: _passController.text.trim(),
      name: _nameController.text.trim(),
      role: _selectedRole,
      specialty: _selectedRole == 'doctor' ? _specController.text.trim() : null,
      idProf: _selectedRole == 'doctor' ? _idController.text.trim() : null,
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
                        Text(t['title']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        Text(t['sub']!, style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 30),

                        // --- اختيار الرتبة (Role Switcher) ---
                        Text(t['role_selection']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildRoleCard('doctor', t['doctor']!, Icons.medical_services_outlined),
                            const SizedBox(width: 15),
                            _buildRoleCard('secretary', t['secretary']!, Icons.person_search_outlined),
                          ],
                        ),
                        const SizedBox(height: 30),

                        _buildField(t['name']!, Icons.person_outline, _nameController),
                        const SizedBox(height: 15),
                        _buildField(t['email']!, Icons.alternate_email, _emailController),
                        const SizedBox(height: 15),

                        // حقول تظهر للطبيب فقط
                        if (_selectedRole == 'doctor') ...[
                          _buildField(t['spec']!, Icons.stars_outlined, _specController),
                          const SizedBox(height: 15),
                          _buildField(t['id']!, Icons.badge_outlined, _idController),
                          const SizedBox(height: 15),
                        ],

                        _buildField(t['pass']!, Icons.lock_outline, _passController, isPass: true),
                        const SizedBox(height: 30),

                        _isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(t['btn']!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                        
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(t['have_acc']!),
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

  // ودجت لاختيار الرتبة بطريقة عصرية
  Widget _buildRoleCard(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {bool isPass = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? _obscurePass : false,
      validator: (v) => v!.isEmpty ? "Obligatoire" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
        suffixIcon: isPass ? IconButton(
          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  Widget _buildSideIllustration() {
    return Container(
      width: 400,
      height: 700,
      decoration: const BoxDecoration(
        color: Color(0xFF0D47A1),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.health_and_safety, size: 100, color: Colors.white),
          SizedBox(height: 20),
          Text("GlucoLink", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text("Gestion intelligente pour les professionnels de santé.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildLangPicker() {
    return DropdownButton<String>(
      value: _currentLang,
      onChanged: (v) => setState(() => _currentLang = v!),
      items: const [
        DropdownMenuItem(value: 'ar', child: Text("AR")),
        DropdownMenuItem(value: 'fr', child: Text("FR")),
        DropdownMenuItem(value: 'en', child: Text("EN")),
      ],
    );
  }
}