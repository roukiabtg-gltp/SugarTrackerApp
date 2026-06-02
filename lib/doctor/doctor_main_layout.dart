import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dashboard.dart';
import 'patients.dart';
import 'alerts.dart';
import 'Appointment.dart';
import 'administration_page.dart';
import 'notes.dart';
import 'reports.dart';
import 'settings_page.dart';                   // ← جديد
import '../desktop/auth/login_desktop.dart';
import '../doctor_settings_notifier.dart';      // ← جديد

class DoctorMainLayout extends StatefulWidget {
  const DoctorMainLayout({super.key});
  @override
  State<DoctorMainLayout> createState() => _DoctorMainLayerState();
}

class _DoctorMainLayerState extends State<DoctorMainLayout> {
  int _selectedIndex = 0;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  final List<Widget> _pages = [
    const ProfessionalDashboard(),
    const PatientsPage(),
    AppointmentsPage(),
    const AlertsPage(),
    const NotesPage(),
    const ReportsPage(),
    const AdministrationPage(),
    const SettingsPage(),               // ← index 7
  ];

  // ── ترجمة بسيطة بدون package ─────────────────────────────
  String _t(String en, String ar, String fr) {
    final lang = doctorLocale.value.languageCode;
    if (lang == 'ar') return ar;
    if (lang == 'fr') return fr;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: doctorThemeMode,
      builder: (_, mode, __) {
        return ValueListenableBuilder<Locale>(
          valueListenable: doctorLocale,
          builder: (_, locale, __) {
            return ValueListenableBuilder<double>(
              valueListenable: doctorFontScale,
              builder: (_, scale, __) {
                final isDark = mode == ThemeMode.dark;
                final sidebarBg = isDark ? const Color(0xFF13151E) : Colors.white;
                final divColor  = isDark ? Colors.white12 : Colors.grey.shade200;

                return Scaffold(
                  body: Row(children: [

                    // ══ SIDEBAR ══════════════════════════════════════════
                    Container(
                      width: 260,
                      color: sidebarBg,
                      child: Column(children: [

                        // Logo
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: Row(children: [
                            Icon(Icons.monitor_heart,
                                color: const Color(0xFF1882FF), size: 32),
                            const SizedBox(width: 12),
                            Text('GlucoLink',
                                style: TextStyle(
                                  fontSize: 20 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                                )),
                          ]),
                        ),

                        const SizedBox(height: 16),

                        // ── Nav items (scrollable) ─────────────────
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(children: [
                              _item(0, Icons.grid_view_rounded,             _t('Dashboard',      'لوحة التحكم',   'Tableau de bord'), isDark, scale),
                              _item(1, Icons.people_outline_rounded,        _t('Patients',       'المرضى',        'Patients'),        isDark, scale),
                              _item(2, Icons.calendar_today_outlined,       _t('Appointments',   'المواعيد',      'Rendez-vous'),     isDark, scale),
                              _item(3, Icons.notifications_none_rounded,    _t('Alerts',         'التنبيهات',     'Alertes'),         isDark, scale),
                              _item(4, Icons.notes_outlined,                _t('Notes',          'الملاحظات',     'Notes'),           isDark, scale),
                              _item(5, Icons.bar_chart_outlined,            _t('Reports',        'التقارير',      'Rapports'),        isDark, scale),
                              _item(6, Icons.admin_panel_settings_outlined, _t('Administration', 'الإدارة',       'Administration'),  isDark, scale),
                              Divider(color: divColor, height: 24, indent: 16, endIndent: 16),
                              _item(7, Icons.settings_outlined,             _t('Settings',       'الإعدادات',     'Paramètres'),      isDark, scale),
                              const SizedBox(height: 12),
                            ]),
                          ),
                        ),

                        // Doctor profile
                        _buildDoctorProfile(isDark, scale),

                        // Logout
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            leading: const Icon(Icons.logout,
                                color: Colors.redAccent),
                            title: Text(
                              _t('Sign out', 'تسجيل الخروج', 'Déconnexion'),
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14 * scale),
                            ),
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginDesktop()),
                                  (_) => false,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ]),
                    ),

                    VerticalDivider(thickness: 1, width: 1, color: divColor),

                    // ══ CONTENT ══════════════════════════════════════════
                    Expanded(
                      child: ColoredBox(
                        color: isDark
                            ? const Color(0xFF0F1117)
                            : const Color(0xFFF8F9FE),
                        child: _pages[_selectedIndex],
                      ),
                    ),
                  ]),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Nav item ─────────────────────────────────────────────
  Widget _item(int idx, IconData icon, String label,
      bool isDark, double scale) {
    final bool sel = _selectedIndex == idx;
    final selBg  = isDark
        ? const Color(0xFF1882FF).withOpacity(0.15)
        : Colors.blue.shade50;
    final selCol = const Color(0xFF1882FF);
    final defCol = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: sel,
        selectedTileColor: selBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: sel ? selCol : defCol, size: 20),
        title: Text(label,
            style: TextStyle(
              fontSize: 13.5 * scale,
              color: sel ? selCol : (isDark ? Colors.white : Colors.grey.shade700),
              fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
            )),
        onTap: () => setState(() => _selectedIndex = idx),
      ),
    );
  }

  // ── Doctor profile (Realtime DB) ──────────────────────────
  Widget _buildDoctorProfile(bool isDark, double scale) {
    if (_uid == null) return const SizedBox();
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users/$_uid').onValue,
      builder: (_, snap) {
        String name = 'Doctor', specialty = 'Specialist';
        if (snap.hasData && snap.data!.snapshot.value != null) {
          final d = snap.data!.snapshot.value as Map;
          final fn = d['first_name']?.toString() ?? '';
          final ln = d['last_name']?.toString() ?? '';
          name      = '$fn $ln'.trim().isNotEmpty ? '$fn $ln'.trim() : 'Doctor';
          specialty = d['specialty']?.toString() ?? 'Specialist';
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1882FF).withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'D',
                  style: const TextStyle(
                      color: Color(0xFF1882FF), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13 * scale,
                          color: isDark ? Colors.white : const Color(0xFF0D1117))),
                  Text(specialty,
                      style: TextStyle(
                          color: Colors.grey, fontSize: 11 * scale)),
                ],
              )),
            ]),
          ),
        );
      },
    );
  }
}
