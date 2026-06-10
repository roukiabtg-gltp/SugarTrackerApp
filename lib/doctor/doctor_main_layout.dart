import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fst;
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
import 'doctor_profile_page.dart';             // ← جديد

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
    AlertsPage(doctorId: FirebaseAuth.instance.currentUser!.uid),
    const NotesPage(),
    const ReportsPage(),
    const AdministrationPage(),
    const SettingsPage(),               // ← index 7
    const DoctorProfilePage(),          // ← index 8
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: doctorLocale,
      builder: (context, locale, _) {
        final isDark = doctorThemeMode.value == ThemeMode.dark;
        final scale = doctorFontScale.value;
        final sidebarBg = isDark ? const Color(0xFF13151E) : Colors.white;
        final divColor = isDark ? Colors.white12 : Colors.grey.shade200;
        final lang = locale.languageCode;
        final isRtl = lang == 'ar';

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(t('Dashboard', 'لوحة التحكم', 'Tableau de bord')),
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black,
              elevation: 0,
            ),
            drawer: Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE5E7EB),
                      ),
                      child: Text(
                        t('Menu', 'القائمة', 'Menu'),
                        style: TextStyle(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _item(0, Icons.grid_view_rounded, t('Dashboard', 'لوحة التحكم', 'Tableau de bord'), isDark, scale),
                          _item(1, Icons.people_outline_rounded, t('Patients', 'المرضى', 'Patients'), isDark, scale),
                          _item(2, Icons.calendar_today_outlined, t('Appointments', 'المواعيد', 'Rendez-vous'), isDark, scale),
                          _item(3, Icons.notifications_none_rounded, t('Alerts', 'التنبيهات', 'Alertes'), isDark, scale),
                          _item(4, Icons.notes_outlined, t('Notes', 'الملاحظات', 'Notes'), isDark, scale),
                          _item(5, Icons.bar_chart_outlined, t('Reports', 'التقارير', 'Rapports'), isDark, scale),
                          _item(6, Icons.admin_panel_settings_outlined, t('Administration', 'الإدارة', 'Administration'), isDark, scale),
                          _item(7, Icons.settings_outlined, t('Settings', 'الإعدادات', 'Paramètres'), isDark, scale),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      Text(t('GlucoLink','جلوكولينك','GlucoLink'),
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
                        _item(0, Icons.grid_view_rounded,             t('Dashboard',      'لوحة التحكم',   'Tableau de bord'), isDark, scale),
                        _item(1, Icons.people_outline_rounded,        t('Patients',       'المرضى',        'Patients'),        isDark, scale),
                        _item(2, Icons.calendar_today_outlined,       t('Appointments',   'المواعيد',      'Rendez-vous'),     isDark, scale),
                        _item(3, Icons.notifications_none_rounded,    t('Alerts',         'التنبيهات',     'Alertes'),         isDark, scale),
                        _item(4, Icons.notes_outlined,                t('Notes',          'الملاحظات',     'Notes'),           isDark, scale),
                        _item(5, Icons.bar_chart_outlined,            t('Reports',        'التقارير',      'Rapports'),        isDark, scale),
                        _item(6, Icons.admin_panel_settings_outlined, t('Administration', 'الإدارة',       'Administration'),  isDark, scale),
                        Divider(color: divColor, height: 24, indent: 16, endIndent: 16),
                        _item(7, Icons.settings_outlined,             t('Settings',       'الإعدادات',     'Paramètres'),      isDark, scale),
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
                        t('Sign out', 'تسجيل الخروج', 'Déconnexion'),
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
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ),
            ]),
          ),
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

  // ── Doctor profile (Firestore + Realtime DB) ──────────────
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
        // جلب الصورة من Firestore
        return FutureBuilder<fst.DocumentSnapshot>(
          future: fst.FirebaseFirestore.instance.collection('users').doc(_uid).get(),
          builder: (_, photoSnap) {
            String? photoUrl;
            if (photoSnap.hasData && photoSnap.data!.exists) {
              photoUrl = photoSnap.data!['photoUrl']?.toString();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = 8), // ← index 8 = Profile
                child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1882FF).withOpacity(0.15)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1882FF).withOpacity(0.2),
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl) : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'D',
                            style: const TextStyle(
                                color: Color(0xFF1882FF), fontWeight: FontWeight.bold),
                          )
                        : null,
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
              ),  // GestureDetector
            );
          },
        );
      },
    );
  }
}