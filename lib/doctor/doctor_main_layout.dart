import 'package:flutter/material.dart';
import 'dashboard.dart'; // تأكدي أن هذا هو ملف الـ Dashboard المعدل
import 'patients.dart'; // استدعاء ملف صفحة المرضى الذي أنشأناه سابقاً

class DoctorMainLayout extends StatefulWidget {
  const DoctorMainLayout({super.key});

  @override
  State<DoctorMainLayout> createState() => _DoctorMainLayerState();
}

class _DoctorMainLayerState extends State<DoctorMainLayout> {
  int _selectedIndex = 0;

  // القائمة المحدثة بالصفحات الحقيقية
  final List<Widget> _pages = [
    const DashboardDoctor(), // الصفحة الأولى: لوحة التحكم
    const PatientsPage(),    // الصفحة الثانية: قائمة المرضى الحقيقية (Realtime DB)
    const Center(child: Text("صفحة تنبيهات SOS")), // يمكنك استبدالها لاحقاً بصفحة مخصصة
    const Center(child: Text("تقارير التحليل الأسبوعية")), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // القائمة الجانبية بتصميمها الاحترافي
          NavigationRail(
            minWidth: 100, // زيادة العرض قليلاً لتناسب التصميم
            backgroundColor: const Color(0xFF1A237E), 
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Colors.white, size: 32),
            unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 28),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.grid_view_rounded), 
                label: Text('Dashboard')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_alt_rounded), 
                label: Text('Patients')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.emergency_share), 
                label: Text('SOS')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined), 
                label: Text('Reports')
              ),
            ],
          ),
          
          // خط فاصل بسيط بين القائمة والمحتوى
          VerticalDivider(thickness: 1, width: 1, color: Colors.grey.withOpacity(0.2)),
          
          // محتوى الصفحة المعروضة حالياً
       Expanded(
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: Container(
      key: ValueKey(_selectedIndex), // 🔥 هذا هو الحل
      child: _pages[_selectedIndex],
    ),
  ),
),
        ],
      ),
    );
  }
}