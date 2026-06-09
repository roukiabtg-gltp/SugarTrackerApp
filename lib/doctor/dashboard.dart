                                                                                                           
// ════════════════════════════════════════════════════════════════════════
// DESKTOP ▸ lib/doctor/dashboard.dart
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fst;
import 'package:intl/intl.dart';
import '../doctor_settings_notifier.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final _db  = FirebaseDatabase.instance.ref();
  final _fs  = fst.FirebaseFirestore.instance;
  final String? _dId = FirebaseAuth.instance.currentUser?.uid;

  static const double _critHigh = 1.80;
  static const double _critLow  = 0.70;
  static const double _warnHigh = 1.40;

  bool   _isCritical(dynamic v) => _gl(v) > _critHigh || (_gl(v) < _critLow && _gl(v) > 0);
  bool   _isWarning (dynamic v) => !_isCritical(v) && _gl(v) > _warnHigh;
  double _gl(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  _ApptStatus _apptStatus(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'confirme': case 'confirmé': case 'confirmed': return _ApptStatus.confirmed;
      case 'annule': case 'annulé': case 'cancelled': case 'canceled': return _ApptStatus.cancelled;
      default: return _ApptStatus.pending;
    }
  }

  String _ago(dynamic raw) {
    if (raw == null) return '';
    try {
      int ms;
      if (raw is int)                { ms = raw > 9999999999 ? raw : raw * 1000; }
      else if (raw is fst.Timestamp) { ms = raw.millisecondsSinceEpoch; }
      else { ms = int.tryParse(raw.toString()) ?? 0; if (ms > 0 && ms < 9999999999) ms *= 1000; }
      final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
      if (d.inMinutes <  1) return t('Just now', 'الآن', 'À l\'instant');
      if (d.inMinutes < 60) return '${d.inMinutes}m ago';
      if (d.inHours   < 24) return '${d.inHours}h ago';
      return '${d.inDays}d ago';
    } catch (_) { return ''; }
  }

  // avatar color بناءً على أول حرف الاسم
  List<Color> _avatarColors(String name) {
    const palettes = [
      [Color(0xFFE0F2FE), Color(0xFF0369A1)],
      [Color(0xFFFEF3C7), Color(0xFFB45309)],
      [Color(0xFFF3E8FF), Color(0xFF7E22CE)],
      [Color(0xFFFCE7F3), Color(0xFFBE185D)],
      [Color(0xFFDCFCE7), Color(0xFF15803D)],
      [Color(0xFFFFEDD5), Color(0xFFEA580C)],
      [Color(0xFFE0E7FF), Color(0xFF4338CA)],
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % palettes.length : 0;
    return palettes[idx];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.child('users').orderByChild('doctorId').equalTo(_dId).onValue,
        builder: (_, usersSnap) {
          if (usersSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1882FF)));
          }

          final Map<String, Map<String, dynamic>> patientsMap = {};
          if (usersSnap.hasData && usersSnap.data!.snapshot.value != null) {
            (usersSnap.data!.snapshot.value as Map).forEach((k, v) {
              if (v is Map) patientsMap[k.toString()] = Map<String, dynamic>.from(v);
            });
          }
          final patientIds = patientsMap.keys.toList();

          return StreamBuilder<fst.QuerySnapshot>(
            stream: patientIds.isEmpty
                ? const Stream.empty()
                : _fs.collection('measurements')
                    .where('patientId', whereIn: patientIds.take(10).toList())
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
            builder: (_, measSnap) {
              int critCount = 0, warnCount = 0;
              final Set<String> seenCrit = {}, seenWarn = {};

              for (final doc in (measSnap.data?.docs ?? [])) {
                final d   = doc.data() as Map<String, dynamic>;
                final pid = d['patientId']?.toString() ?? '';
                if (pid.isEmpty) continue;
                final raw    = d['value'];
                final status = d['status']?.toString() ?? '';
                final isCrit = status == 'critical' || _isCritical(raw);
                final isWarn = !isCrit && _isWarning(raw);
                if (isCrit && !seenCrit.contains(pid)) { seenCrit.add(pid); critCount++; }
                else if (isWarn && !seenWarn.contains(pid)) { seenWarn.add(pid); warnCount++; }
              }

              return StreamBuilder<DatabaseEvent>(
                stream: _db.child('sos').onValue,
                builder: (_, sosSnap) {
                  int sosCount = 0;
                  if (sosSnap.hasData && sosSnap.data!.snapshot.value != null) {
                    final all = sosSnap.data!.snapshot.value as Map;
                    all.forEach((pid, patSos) {
                      if (!patientIds.contains(pid.toString())) return;
                      if (patSos is! Map) return;
                      patSos.forEach((_, sv) {
                        if (sv is Map && sv['resolved'] != true) sosCount++;
                      });
                    });
                  }

                  return StreamBuilder<fst.QuerySnapshot>(
                    stream: _fs.collection('appointments')
                        .where('doctorId', isEqualTo: _dId)
                        .snapshots(),
                    builder: (_, apSnap) {
                      final todayDocs = (apSnap.data?.docs ?? []).where((d) =>
                          (d.data() as Map)['date']?.toString().startsWith(todayStr) == true).toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Header ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t('Dashboard', 'لوحة التحكم', 'Tableau de bord'),
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('EEEE, MMMM d yyyy').format(DateTime.now()),
                                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                ]),
                                _doctorCodeCard(),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // ── البطاقات الأربع ──
                            Row(children: [
                              _statCard(
                                t('Total Patients', 'إجمالي المرضى', 'Total patients'),
                                '${patientIds.length}',
                                Icons.people_alt_outlined,
                                const Color(0xFF3B82F6),
                                const Color(0xFFEFF6FF),
                              ),
                              const SizedBox(width: 20),
                              _statCard(
                                t('Critical Alerts', 'تنبيهات حرجة', 'Alertes critiques'),
                                '${critCount + sosCount}',
                                Icons.warning_amber_rounded,
                                const Color(0xFFEF4444),
                                const Color(0xFFFEF2F2),
                                blink: critCount + sosCount > 0,
                              ),
                              const SizedBox(width: 20),
                              _statCard(
                                t('Warnings', 'تحذيرات', 'Alertes'),
                                '$warnCount',
                                Icons.info_outline_rounded,
                                const Color(0xFFF59E0B),
                                const Color(0xFFFFFBEB),
                              ),
                              const SizedBox(width: 20),
                              _statCard(
                                t("Today's Appointments", 'مواعيد اليوم', "Rendez-vous d'aujourd'hui"),
                                '${todayDocs.length}',
                                Icons.calendar_today_outlined,
                                const Color(0xFF10B981),
                                const Color(0xFFF0FFF4),
                              ),
                            ]),
                            const SizedBox(height: 28),

                            // ── Today's Appointments Section ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header السكشن
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(
                                          t("Today's Appointments", 'مواعيد اليوم', "Rendez-vous d'aujourd'hui"),
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('EEEE, MMMM d yyyy').format(DateTime.now()),
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ]),
                                      // View All button
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Text(
                                          t('View All', 'عرض الكل', 'Voir tout'),
                                          style: const TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(color: Colors.grey.shade100, height: 20),

                                  // قائمة المواعيد
                                  todayDocs.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 32),
                                          child: Column(children: [
                                            Icon(Icons.event_available_outlined,
                                                size: 42, color: Colors.grey.withOpacity(0.35)),
                                            const SizedBox(height: 12),
                                            Text(
                                              t('No appointments today', 'لا توجد مواعيد اليوم', 'Pas de rendez-vous'),
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ]),
                                        )
                                      : Column(
                                          children: todayDocs.map((doc) {
                                            final d    = doc.data() as Map<String, dynamic>;
                                            final st   = _apptStatus(d['status']?.toString());
                                            final name = d['patientName']?.toString() ?? t('Patient', 'مريض', 'Patient');
                                            final colors = _avatarColors(name);
                                            final time   = d['time']?.toString() ?? '--';
                                            final type   = d['type']?.toString() ?? '--';
                                            final loc    = d['location']?.toString() ?? d['room']?.toString() ?? '--';
                                            final age    = d['age'];
                                            final isVirtual = loc.toLowerCase().contains('virtual') ||
                                                              loc.toLowerCase().contains('online');

                                            return Container(
                                              padding: const EdgeInsets.symmetric(vertical: 13),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(color: Colors.grey.shade100, width: 0.8),
                                                ),
                                              ),
                                              child: Row(children: [
                                                // Avatar
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: colors[0],
                                                  child: Text(
                                                    _initials(name),
                                                    style: TextStyle(
                                                        color: colors[1],
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),

                                                // الاسم + النوع
                                                Expanded(child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(name,
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 13,
                                                            color: Color(0xFF111827))),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      age != null ? '$type · Age $age' : type,
                                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                    ),
                                                  ],
                                                )),

                                                // الوقت
                                                Row(children: [
                                                  Icon(Icons.access_time_outlined,
                                                      size: 13, color: Colors.grey.shade500),
                                                  const SizedBox(width: 4),
                                                  Text(time,
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                                ]),
                                                const SizedBox(width: 16),

                                                // الموقع
                                                Row(children: [
                                                  Icon(
                                                    isVirtual ? Icons.videocam_outlined : Icons.meeting_room_outlined,
                                                    size: 13,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(loc,
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                                ]),
                                                const SizedBox(width: 16),

                                                // Badge الحالة
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: st.bgColor,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    st.label(context),
                                                    style: TextStyle(
                                                        color: st.color,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ]),
                                            );
                                          }).toList(),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────

  Widget _doctorCodeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.qr_code_2, color: Color(0xFF3B82F6), size: 22),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('Your doctor code', 'رمز الطبيب الخاص بك', 'Votre code docteur'),
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 2),
          Text(_dId ?? '---',
              style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.3,
                  fontFamily: 'monospace')),
        ]),
        const SizedBox(width: 12),
        Tooltip(
          message: t('Copy code', 'نسخ الرمز', 'Copier le code'),
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _dId ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(t('✅ Code copied!', '✅ تم نسخ الرمز!', '✅ Code copié!')),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ));
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy, size: 16, color: Color(0xFF3B82F6)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color bg,
      {bool blink = false}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              if (blink)
                Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.5),
                        blurRadius: 6)],
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Text(value,
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      );
}

// ── Status Enum ──────────────────────────────────────────────────────────
enum _ApptStatus { confirmed, pending, cancelled }

extension _ApptStatusExt on _ApptStatus {
  Color get color {
    switch (this) {
      case _ApptStatus.confirmed: return const Color(0xFF10B981);
      case _ApptStatus.cancelled: return const Color(0xFFEF4444);
      case _ApptStatus.pending:   return const Color(0xFFF59E0B);
    }
  }
  Color get bgColor {
    switch (this) {
      case _ApptStatus.confirmed: return const Color(0xFFDCFCE7);
      case _ApptStatus.cancelled: return const Color(0xFFFEE2E2);
      case _ApptStatus.pending:   return const Color(0xFFFEF3C7);
    }
  }
  String label(BuildContext context) {
    switch (this) {
      case _ApptStatus.confirmed: return t('Confirmed', 'مؤكد', 'Confirmé');
      case _ApptStatus.cancelled: return t('Cancelled', 'ملغى', 'Annulé');
      case _ApptStatus.pending:   return t('Pending', 'قيد الانتظار', 'En attente');
    }
  }                      
}