import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart'; 
import 'patients.dart'; 
import 'alerts.dart';
import 'Appointment.dart'; // 🔥 استيراد صفحة المواعيد
import 'administration_page.dart'; // 🔥 تأكدي من استيراد ملف صفحة الإدارة

class DoctorMainLayout extends StatefulWidget {
  const DoctorMainLayout({super.key});

  @override
  State<DoctorMainLayout> createState() => _DoctorMainLayerState();
}

class _DoctorMainLayerState extends State<DoctorMainLayout> {
  int _selectedIndex = 0;
  final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  // القائمة المحدثة بالصفحات
  final List<Widget> _pages = [   
    const ProfessionalDashboard(), 
    const PatientsPage(),          
    AppointmentsPage(),             // 🔥 صفحة المواعيد
    const AlertsPage(),            
    const AdministrationPage(),     // 🔥 صفحة الإدارة
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // القائمة الجانبية المخصصة (Sidebar)
          Container(
            width: 260, 
            color: Colors.white,
            child: Column(
              children: [
                // اللوجو (MediCare)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(Icons.monitor_heart, color: Colors.blue[600], size: 32),
                      const SizedBox(width: 12),
                      const Text("MediCare", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // عناصر القائمة
                _buildMenuItem(0, Icons.grid_view_rounded, "Dashboard"),
                _buildMenuItem(1, Icons.people_outline_rounded, "Patients"),
                _buildMenuItem(2, Icons.calendar_today_outlined, "Appointments"),     // 🔥 زر المواعيد الجديد
                _buildMenuItem(3, Icons.notifications_none_rounded, "Alerts"),
                _buildMenuItem(4, Icons.admin_panel_settings_outlined, "Administration"), // 🔥 زر الإدارة

                const Spacer(), 

                // قسم معلومات الطبيب (مجلوبة من Firestore)
                _buildDoctorProfile(),

                // زر تسجيل الخروج
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.grey),
                  title: const Text("Sign out", style: TextStyle(color: Colors.grey)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login'); 
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          const VerticalDivider(thickness: 1, width: 1),
          
          // عرض الصفحة المختارة
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FE),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Colors.blue[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600]),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildDoctorProfile() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        String name = data?['name'] ?? "Doctor";
        String specialty = data?['specialty'] ?? "Specialist";

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : "D", style: const TextStyle(color: Colors.blue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                    Text(specialty, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}