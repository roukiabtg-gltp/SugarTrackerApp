import 'package:flutter/material.dart';


class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // لون الخلفية الفاتح من الصورة
      body: Row(
        children: [
          // --- 1. الشريط الجانبي (Sidebar) فوتوكوبي ---
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "GlucoLink",
                        style: TextStyle(
                          color: const Color(0xFF2563EB),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Secrétaire Médicale",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.home_filled, "Accueil", 0),
                _buildMenuItem(Icons.calendar_month_outlined, "Rendez-vous", 1),
                _buildMenuItem(Icons.access_time, "Liste d'Attente", 2),
                _buildMenuItem(Icons.people_outline, "Patients", 3),
                _buildMenuItem(Icons.attach_money, "Facturation", 4),
                _buildMenuItem(Icons.description_outlined, "Certificats", 5),
              ],
            ),
          ),

          // --- 2. المحتوى الرئيسي (Accueil) فوتوكوبي ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الترحيب
                  Row(
                    children: [
                      const Text(
                        "Bonjour, Secrétaire",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 8),
                      const Text("👋", style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  const Text(
                    "Tableau de bord - Gestion du cabinet",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  // صف الكروت الثلاثة الكبيرة (Nouveau RDV, Patient, Liste)
                  Row(
                    children: [
                      _buildActionCard("Nouveau\nRendez-vous", "Planifier consultation", Icons.add, const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
                      const SizedBox(width: 24),
                      _buildActionCard("Nouveau\nPatient", "Créer dossier patient", Icons.person_add_alt_1_outlined, const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                      const SizedBox(width: 24),
                      _buildActionCard("Liste d'Attente", "3 aujourd'hui", Icons.access_time, const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // صف الإحصائيات الأربعة
                 // صف الإحصائيات الأربعة بتعديل مرن
Row(
  children: [
    Expanded(child: _buildSmallStat("Aujourd'hui", "3", "Rendez-vous", const Color(0xFF2563EB))),
    const SizedBox(width: 15), // مسافة بين الكروت
    Expanded(child: _buildSmallStat("Patients", "12", "Enregistrés", const Color(0xFF16A34A))),
    const SizedBox(width: 15),
    Expanded(child: _buildSmallStat("Impayées", "1", "Factures", Colors.redAccent)),
    const SizedBox(width: 15),
    Expanded(child: _buildSmallStat("Documents", "5", "Cette semaine", Colors.purple)),
  ],
),// صف الإحصائيات الأربعة بتعديل مرن
Row(
  children: [
    Expanded(child: _buildSmallStat("Aujourd'hui", "3", "Rendez-vous", const Color(0xFF2563EB))),
    const SizedBox(width: 15), // مسافة بين الكروت
    Expanded(child: _buildSmallStat("Patients", "12", "Enregistrés", const Color(0xFF16A34A))),
    const SizedBox(width: 15),
    Expanded(child: _buildSmallStat("Impayées", "1", "Factures", Colors.redAccent)),
    const SizedBox(width: 15),
    Expanded(child: _buildSmallStat("Documents", "5", "Cette semaine", Colors.purple)),
  ],
),
                  const SizedBox(height: 40),

                  // قائمة مواعيد اليوم (Container الأبيض الكبير)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Rendez-vous Aujourd'hui", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            TextButton(onPressed: () {}, child: const Text("Voir tout", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildPatientRow("Marie Dubois", "09:00 - consultation", "confirme", Colors.green),
                        _buildPatientRow("Jean Martin", "10:00 - controle", "en-attente", Colors.orange),
                        _buildPatientRow("Sophie Bernard", "11:00 - consultation", "confirme", Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- دوال بناء العناصر (نفس الأشكال في الصور) ---

  Widget _buildMenuItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String sub, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

 Widget _buildSmallStat(String label, String value, String sub, Color color) {
  return Container(
    // تم حذف width: 160 من هنا لكي لا يحدث اصطدام مع مساحة الشاشة
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE5E7EB)), // إضافة إطار خفيف لزيادة التناسق
    ),
    child: Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    ),
  );
}

  Widget _buildPatientRow(String name, String time, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}