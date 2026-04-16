import 'package:flutter/material.dart';
import 'Rendez-vous.dart';
import 'Patients.dart';
import 'Liste d\'Attente.dart';
import 'Facture.dart';
import 'Certificat.dart';

class NurseMainLayout extends StatefulWidget {
  const NurseMainLayout({super.key});

  @override
  State<NurseMainLayout> createState() => _NurseMainLayoutState();
}
 
class _NurseMainLayoutState extends State<NurseMainLayout> {
  int _selectedIndex = 0;

  // القائمة الجانبية
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home_filled, 'label': 'Accueil'},
    {'icon': Icons.calendar_month_outlined, 'label': 'Rendez-vous'},
    {'icon': Icons.access_time, 'label': "Liste d'Attente"},
    {'icon': Icons.people_outline, 'label': 'Patients'},
    {'icon': Icons.attach_money, 'label': 'Facturation'},
    {'icon': Icons.description_outlined, 'label': 'Certificats'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(
        children: [
          // --- 1. الشريط الجانبي (Sidebar) الثابت ---
          _buildSidebar(),

          // --- 2. عرض المحتوى المتغير (تم ربط جميع الصفحات هنا) ---
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildAccueilPage(),       // Index 0
                const AppointmentPage(),   // Index 1 (صفحة المواعيد)
                const WaitingListPage(),   // Index 2 (صفحة قائمة الانتظار)
                const PatientsPage(),      // Index 3 (صفحة المرضى)
                const FacturationPage(),   // Index 4 (صفحة الفواتير)
                const CertificatsPage(),   // Index 5 (صفحة الشهادات)
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- دالة بناء الشريط الجانبي ---
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 35),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("GlucoLink",
                    style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const Text("Secrétaire Médicale",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return _buildSidebarItem(
                  icon: _menuItems[index]['icon'],
                  label: _menuItems[index]['label'],
                  isSelected: _selectedIndex == index,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _buildSidebarItem(
            icon: Icons.logout,
            label: "Déconnexion",
            isSelected: false,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- 0. محتوى صفحة الاستقبال (Accueil) ---
  Widget _buildAccueilPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("Bonjour, Secrétaire 👋", "Tableau de bord - Gestion du cabinet"),
          const SizedBox(height: 40),
          Row(
            children: [
              _buildActionCard("Nouveau\nRendez-vous", "Planifier consultation", Icons.add, const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
              const SizedBox(width: 20),
              _buildActionCard("Nouveau\nPatient", "Créer dossier patient", Icons.person_add_alt_1_outlined, const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
              const SizedBox(width: 20),
              _buildActionCard("Liste d'Attente", "3 aujourd'hui", Icons.access_time, const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
            ],
          ),
          const SizedBox(height: 40),
          // تم استخدام Expanded هنا لحل مشكلة الخطوط الصفراء (Overflow)
          Row(
            children: [
              Expanded(child: _buildSmallStat("Aujourd'hui", "3", "Rendez-vous", const Color(0xFF2563EB))),
              const SizedBox(width: 15),
              Expanded(child: _buildSmallStat("Patients", "12", "Enregistrés", const Color(0xFF16A34A))),
              const SizedBox(width: 15),
              Expanded(child: _buildSmallStat("Impayées", "1", "Factures", Colors.redAccent)),
              const SizedBox(width: 15),
              Expanded(child: _buildSmallStat("Documents", "5", "Cette semaine", Colors.purple)),
            ],
          ),
          const SizedBox(height: 40),
          _buildAppointmentSection(),
        ],
      ),
    );
  }

  // --- دوال المساعدة (UI Helpers) ---
  Widget _buildHeader(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 16)),
    ]);
  }

  Widget _buildSidebarItem({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 22),
          const SizedBox(width: 15),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _buildActionCard(String title, String sub, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor)),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    );
  }

  Widget _buildAppointmentSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Rendez-vous Aujourd'hui", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: () {}, child: const Text("Voir tout")),
        ]),
        const SizedBox(height: 15),
        _buildPatientRow("Marie Dubois", "09:00 - consultation", "confirme", Colors.green),
        _buildPatientRow("Jean Martin", "10:00 - controle", "en-attente", Colors.orange),
      ]),
    );
  }

  Widget _buildPatientRow(String name, String details, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(details, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
      ]),
    );
  }
}