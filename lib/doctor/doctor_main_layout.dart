import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'package:firebase_database/firebase_database.dart';


import 'package:firebase_database/firebase_database.dart';

class DoctorMainLayout extends StatefulWidget {
  const DoctorMainLayout({super.key});

  @override
  State<DoctorMainLayout> createState() => _DoctorMainLayerState();
}

class _DoctorMainLayerState extends State<DoctorMainLayout> {
  int _selectedIndex = 0;

  // القائمة التي تربط الأزرار بالصفحات
  final List<Widget> _pages = [
     const DashboardDoctor(),
    const Center(child: Text("Patients List")),
    const Center(child: Text("Alerts Page")),
    const Center(child: Text("Analysis Reports")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF1A237E), // لون طبي احترافي
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Colors.white, size: 30),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.grid_view), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Patients')),
              NavigationRailDestination(icon: Icon(Icons.warning_amber), label: Text('SOS')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Reports')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}