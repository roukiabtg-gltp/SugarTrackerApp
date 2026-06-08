// ════════════════════════════════════════════════════════════════════════
// DESKTOP ▸ lib/doctor/dashboard.dart
// المرضى  ← Realtime DB  (users/{uid}/doctorId)
// القياسات ← Firestore    (measurements/patientId+status)
// SOS      ← Realtime DB  (sos/{uid}/{sosId})
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fst;
import 'package:intl/intl.dart';
import 'patient_profile_pageee.dart';
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

  // عتبات السكري — g/L
  static const double _critHigh = 1.80;
  static const double _critLow  = 0.70;
  static const double _warnHigh = 1.40;

  bool   _isCritical(dynamic v) => _gl(v) > _critHigh || (_gl(v) < _critLow && _gl(v) > 0);
  bool   _isWarning (dynamic v) => !_isCritical(v) && _gl(v) > _warnHigh;
  double _gl(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  String _glucoseDesc(double gL) {
    if (gL > _critHigh) return t('High glucose — Hyperglycemia', 'ارتفاع السكر — فرط سكر الدم', 'Glycémie élevée — Hyperglycémie');
    if (gL < _critLow && gL > 0) return t('Low glucose — Hypoglycemia', 'انخفاض السكر — نقص سكر الدم', 'Glycémie basse — Hypoglycémie');
    if (gL > _warnHigh) return t('Borderline high', 'قريب من الحد الأعلى', 'Limite supérieure');
    return t('Normal range', 'نطاق طبيعي', 'Plage normale');
  }

  String _ago(dynamic raw) {
    if (raw == null) return '';
    try {
      int ms;
      if (raw is int)            { ms = raw > 9999999999 ? raw : raw * 1000; }
      else if (raw is fst.Timestamp) { ms = raw.millisecondsSinceEpoch; }
      else { ms = int.tryParse(raw.toString()) ?? 0; if (ms > 0 && ms < 9999999999) ms *= 1000; }
      final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
      if (d.inMinutes <  1) return t('Just now', 'الآن', 'À l\'instant');
      if (d.inMinutes < 60) return '${d.inMinutes}m ago';
      if (d.inHours   < 24) return '${d.inHours}h ago';
      return '${d.inDays}d ago';
    } catch (_) { return ''; }
  }

  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: StreamBuilder<DatabaseEvent>(
        // ① المرضى من Realtime DB
        stream: _db.child('users').orderByChild('doctorId').equalTo(_dId).onValue,
        builder: (_, usersSnap) {

          // ── Loading ─────────────────────────────────
          if (usersSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1882FF)),
            );
          }

          // ── بناء قائمة المرضى ──────────────────────
          final Map<String, Map<String, dynamic>> patientsMap = {};
          if (usersSnap.hasData && usersSnap.data!.snapshot.value != null) {
            final raw = usersSnap.data!.snapshot.value as Map;
            raw.forEach((k, v) {
              if (v is Map) {
                patientsMap[k.toString()] = Map<String, dynamic>.from(v);
              }
            });
          }

          final patientIds = patientsMap.keys.toList();

          return StreamBuilder<fst.QuerySnapshot>(
            // ② القياسات من Firestore — نجلب الكل إذا لا مرضى بعد
            stream: patientIds.isEmpty
                ? const Stream.empty()
                : _fs.collection('measurements')
                    .where('patientId', whereIn: patientIds.take(10).toList())
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
            builder: (_, measSnap) {

              // ── معالجة القياسات ─────────────────────
              final Map<String, Map<String, dynamic>> latestMeas = {};
              final List<_AlertItem> critAlerts = [];
              final List<_AlertItem> warnAlerts = [];
              final Set<String> seenCrit = {};
              final Set<String> seenWarn = {};

              for (final doc in (measSnap.data?.docs ?? [])) {
                final d   = doc.data() as Map<String, dynamic>;
                final pid = d['patientId']?.toString() ?? '';
                if (pid.isEmpty) continue;
                if (!latestMeas.containsKey(pid)) latestMeas[pid] = d;

                final raw    = d['value'];
                final status = d['status']?.toString() ?? '';
                final ts     = d['timestamp'];
                final pat    = patientsMap[pid] ?? {};
                final nm     = '${pat['first_name'] ?? ''} ${pat['last_name'] ?? ''}'.trim();

                final isCrit = status == 'critical' || _isCritical(raw);
                final isWarn = !isCrit && _isWarning(raw);
                final gL     = _gl(raw);

                  if (isCrit && !seenCrit.contains(pid)) {
                  seenCrit.add(pid);
                  critAlerts.add(_AlertItem(
                    patientId: pid, patientName: nm.isEmpty ? t('Patient','مريض','Patient') : nm,
                    reason: _glucoseDesc(gL),
                    value: '${raw ?? '--'} ${d['unit'] ?? 'g/L'}',
                    ts: ts, isCritical: true,
                  ));
                } else if (isWarn && !seenWarn.contains(pid)) {
                  seenWarn.add(pid);
                  warnAlerts.add(_AlertItem(
                    patientId: pid, patientName: nm.isEmpty ? t('Patient','مريض','Patient') : nm,
                    reason: 'Borderline high glucose',
                    value: '${raw ?? '--'} ${d['unit'] ?? 'g/L'}',
                    ts: ts, isCritical: false,
                  ));
                }
              }

              return StreamBuilder<DatabaseEvent>(
                // ③ SOS من Realtime DB
                stream: _db.child('sos').onValue,
                builder: (_, sosSnap) {

                  final List<_SosItem> sosList = [];
                  if (sosSnap.hasData && sosSnap.data!.snapshot.value != null) {
                    final all = sosSnap.data!.snapshot.value as Map;
                    all.forEach((pid, patSos) {
                      if (!patientIds.contains(pid.toString())) return;
                      if (patSos is! Map) return;
                      patSos.forEach((sosId, sv) {
                        if (sv is Map && sv['resolved'] != true) {
                          final pat = patientsMap[pid.toString()] ?? {};
                          final nm  = '${pat['first_name'] ?? ''} ${pat['last_name'] ?? ''}'.trim();
                          sosList.add(_SosItem(
                            patientId: pid.toString(), sosId: sosId.toString(),
                            patientName: sv['patientName'] ?? (nm.isEmpty ? t('Patient','مريض','Patient') : nm),
                            glucose: sv['glucose']?.toString() ?? '--',
                            timestamp: sv['timestamp'],
                          ));
                        }
                      });
                    });
                  }

                  // ═══════════════════════════════════════
                  //  UI
                  // ═══════════════════════════════════════
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Header ──────────────────────
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

                        // ── Stats Row ───────────────────
                        Row(children: [
                            _statCard(t('Total Patients', 'إجمالي المرضى', 'Total patients'), '${patientIds.length}',
                              Icons.people_alt_outlined, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                          const SizedBox(width: 20),
                            _statCard(t('Critical Alerts', 'تنبيهات حرجة', 'Alertes critiques'), '${critAlerts.length + sosList.length}',
                              Icons.warning_amber_rounded, const Color(0xFFEF4444), const Color(0xFFFEF2F2),
                              blink: critAlerts.isNotEmpty || sosList.isNotEmpty),
                          const SizedBox(width: 20),
                            _statCard(t('Warnings', 'تحذيرات', 'Alertes'), '${warnAlerts.length}',
                              Icons.info_outline_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                          const SizedBox(width: 20),
                          // مواعيد اليوم من Firestore
                          StreamBuilder<fst.QuerySnapshot>(
                            stream: _fs.collection('appointments')
                                .where('doctorId', isEqualTo: _dId).snapshots(),
                            builder: (_, apSnap) {
                              final cnt = (apSnap.data?.docs ?? []).where((d) =>
                                  (d.data() as Map)['date']?.toString().startsWith(todayStr) == true).length;
                                return _statCard(t("Today's Appointments", 'مواعيد اليوم', 'Rendez-vous d\'aujourd\'hui'), '$cnt',
                                  Icons.calendar_today_outlined, const Color(0xFF10B981), const Color(0xFFF0FFF4));
                            },
                          ),
                        ]),
                        const SizedBox(height: 32),

                        // ── Body: Left + Right ──────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Left ──
                            Expanded(
                              flex: 3,
                              child: Column(children: [

                                // SOS
                                if (sosList.isNotEmpty) ...[
                                  _sectionBox(
                                    title: 'SOS Emergency Calls',
                                    icon: Icons.sos_rounded,
                                    iconColor: const Color(0xFFFF6D00),
                                    badge: '${sosList.length}',
                                    badgeBg: const Color(0xFFFFF5EC),
                                    badgeColor: const Color(0xFFFF6D00),
                                    child: Column(children: sosList.map(_sosTile).toList()),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Critical Alerts
                                _sectionBox(
                                  title: 'Critical Alerts',
                                  icon: Icons.warning_amber_rounded,
                                  iconColor: const Color(0xFFEF4444),
                                  badge: critAlerts.isNotEmpty ? '${critAlerts.length}' : null,
                                  badgeBg: const Color(0xFFFEF2F2),
                                  badgeColor: const Color(0xFFEF4444),
                                  child: critAlerts.isEmpty
                                      ? _empty('No critical cases right now', Icons.check_circle_outline, Colors.green)
                                      : Column(children: critAlerts.map(_alertTile).toList()),
                                ),
                                const SizedBox(height: 20),

                                // Warnings
                                _sectionBox(
                                  title: 'Borderline Warnings',
                                  icon: Icons.info_outline,
                                  iconColor: const Color(0xFFF59E0B),
                                  badge: warnAlerts.isNotEmpty ? '${warnAlerts.length}' : null,
                                  badgeBg: const Color(0xFFFFFBEB),
                                  badgeColor: const Color(0xFFF59E0B),
                                  child: warnAlerts.isEmpty
                                      ? _empty('No borderline values', Icons.thumb_up_outlined, Colors.blue)
                                      : Column(children: warnAlerts.map(_alertTile).toList()),
                                ),
                                const SizedBox(height: 20),
                                _referenceCard(),
                              ]),
                            ),
                            const SizedBox(width: 24),

                            // ── Right ──
                            Expanded(
                              flex: 2,
                              child: Column(children: [

                                // Patient Status
                                _sectionBox(
                                  title: 'Patient Status',
                                  icon: Icons.people_outline,
                                  iconColor: const Color(0xFF3B82F6),
                                  child: patientIds.isEmpty
                                      ? _empty('No patients yet', Icons.person_add_outlined, Colors.grey)
                                      : Column(
                                          children: patientIds.take(6).map((pid) {
                                            final p    = patientsMap[pid] ?? {};
                                            final nm   = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
                                            final lm   = latestMeas[pid];
                                            final raw  = lm?['value'];
                                            final unit = lm?['unit']?.toString() ?? 'g/L';
                                            final ts   = lm?['timestamp'];
                                            final isCrit = lm?['status'] == 'critical' || _isCritical(raw);
                                            final isWarn = !isCrit && _isWarning(raw);
                                            final dot  = isCrit ? const Color(0xFFEF4444)
                                                       : isWarn ? const Color(0xFFF59E0B)
                                                       : const Color(0xFF10B981);
                                            final bg   = isCrit ? const Color(0xFFFEF2F2)
                                                       : isWarn ? const Color(0xFFFFFBEB)
                                                       : const Color(0xFFF8FAFC);
                                            return GestureDetector(
                                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => PatientProfilePage(
                                                  patientId: pid,
                                                  patientName: nm.isEmpty ? 'Patient' : nm))),
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 10),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: bg, borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: dot.withOpacity(0.22)),
                                                ),
                                                child: Row(children: [
                                                  CircleAvatar(radius: 5, backgroundColor: dot),
                                                  const SizedBox(width: 12),
                                                  Expanded(child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(nm.isEmpty ? 'Patient' : nm,
                                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                                      Text(
                                                        lm == null ? 'No data yet' : '${raw ?? '--'} $unit · ${_ago(ts)}',
                                                        style: TextStyle(color: lm == null ? Colors.grey : dot, fontSize: 11),
                                                      ),
                                                    ],
                                                  )),
                                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                                                ]),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                ),
                                const SizedBox(height: 20),

                                // Today's Schedule
                                StreamBuilder<fst.QuerySnapshot>(
                                  stream: _fs.collection('appointments')
                                      .where('doctorId', isEqualTo: _dId)
                                      .orderBy('createdAt').snapshots(),
                                  builder: (_, apSnap) {
                                    final docs = (apSnap.data?.docs ?? []).where((d) =>
                                        (d.data() as Map)['date']?.toString().startsWith(todayStr) == true).toList();
                                    return _sectionBox(
                                      title: "Today's Schedule",
                                      icon: Icons.event_note_outlined,
                                      iconColor: const Color(0xFF10B981),
                                      badge: docs.isNotEmpty ? '${docs.length}' : null,
                                      badgeBg: const Color(0xFFF0FFF4),
                                      badgeColor: const Color(0xFF10B981),
                                        child: docs.isEmpty
                                          ? _empty(t('No appointments today','لا توجد مواعيد اليوم','Pas de rendez-vous aujourd\'hui'), Icons.event_available_outlined, Colors.grey)
                                          : Column(children: docs.take(5).map((doc) {
                                              final d      = doc.data() as Map<String, dynamic>;
                                              final isConf = d['status']?.toString() == 'confirme';
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border(left: BorderSide(
                                                      color: isConf ? const Color(0xFF10B981) : const Color(0xFFF59E0B), width: 3)),
                                                ),
                                                child: Row(children: [
                                                  Expanded(child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Text(d['patientName'] ?? t('Patient','مريض','Patient'),
                                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                                        Text('${d['time'] ?? '--'} · ${d['type'] ?? '--'}',
                                                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                                    ],
                                                  )),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isConf ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(isConf ? t('Confirmed','مؤكد','Confirmé') : t('Pending','قيد الانتظار','En attente'),
                                                        style: TextStyle(
                                                            color: isConf ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                                            fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ),
                                                ]),
                                              );
                                            }).toList()),
                                    );
                                  },
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Widgets
  // ════════════════════════════════════════════════════════

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
          Text(t('Your doctor code', 'رمز الطبيب الخاص بك', 'Votre code docteur'), style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 2),
          Text(_dId ?? '---',
              style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold,
                  fontSize: 12, letterSpacing: 0.3, fontFamily: 'monospace')),
        ]),
        const SizedBox(width: 12),
        Tooltip(
          message: t('Copy code','نسخ الرمز','Copier le code'),
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _dId ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(t('✅ Code copied! Share with your patient','✅ تم نسخ الرمز! شاركه مع المريض','✅ Code copié! Partagez avec votre patient')),
                  behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.copy, size: 16, color: Color(0xFF3B82F6)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color bg, {bool blink = false}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22)),
              if (blink) Container(width: 9, height: 9,
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.5), blurRadius: 6)])),
            ]),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      );

  Widget _sectionBox({required String title, required IconData icon, required Color iconColor,
      required Widget child, String? badge, Color? badgeBg, Color? badgeColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: badgeBg ?? Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Text(badge, style: TextStyle(color: badgeColor ?? Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ]),
        Divider(color: Colors.grey.shade100, height: 20),
        child,
      ]),
    );
  }

  Widget _alertTile(_AlertItem a) {
    final color = a.isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final bg    = a.isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PatientProfilePage(patientId: a.patientId, patientName: a.patientName))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Container(width: 4, height: 46, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 3),
            Text(a.reason, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(a.value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 4),
            Text(_ago(a.ts), style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          const SizedBox(width: 10),
          Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_ios, size: 11, color: color)),
        ]),
      ),
    );
  }

  Widget _sosTile(_SosItem s) {
    const color = Color(0xFFFF6D00);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(children: [
        Container(width: 4, height: 46,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(s.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(5)),
              child: Text(t('SOS','نداء استغاثة','SOS'), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 3),
          Text('${t('Glucose','السكر','Glucose')}: ${s.glucose} g/L', style: const TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_ago(s.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          Row(children: [
            // Resolve
            GestureDetector(
              onTap: () async {
                await FirebaseDatabase.instance.ref()
                    .child('sos/${s.patientId}/${s.sosId}')
                    .update({'resolved': true, 'resolvedAt': ServerValue.timestamp});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFF5EC), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.4))),
                child: Text(t('Resolve','حل','Résoudre'), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 6),
            // View
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PatientProfilePage(patientId: s.patientId, patientName: s.patientName))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(8)),
                child: Text(t('View','عرض','Voir'), style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ]),
    );
  }

  Widget _referenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.science_outlined, color: Color(0xFF3B82F6), size: 18),
          const SizedBox(width: 8),
          Text(t('Glucose Reference Values','قيم مرجعية للسكر','Valeurs de référence du glucose'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(1.5)},
          children: [
            _refRow('Category', 'g/L', 'mg/dL', isHeader: true),
            _refRow('Normal (fasting)', '0.70 – 1.00', '70 – 100', color: Colors.green),
            _refRow('Normal (post-meal)', '< 1.40', '< 140', color: Colors.green),
            _refRow('⚠ Borderline high', '1.40 – 1.80', '140 – 180', color: Colors.orange),
            _refRow('🔴 Hypoglycemia', '< 0.70', '< 70', color: Colors.red),
            _refRow('🔴 Hyperglycemia', '> 1.80', '> 180', color: Colors.red),
          ],
        ),
      ]),
    );
  }

  TableRow _refRow(String cat, String gL, String mgDL, {bool isHeader = false, Color? color}) {
    final style = TextStyle(fontSize: isHeader ? 11 : 12,
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        color: color ?? (isHeader ? Colors.grey : const Color(0xFF2D3142)));
    return TableRow(
      decoration: isHeader ? BoxDecoration(color: Colors.grey.shade50) : null,
      children: [cat, gL, mgDL].map((t) =>
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text(t, style: style))).toList(),
    );
  }

  Widget _empty(String msg, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(children: [
      Icon(icon, size: 38, color: color.withOpacity(0.35)),
      const SizedBox(height: 10),
      Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════
//  Data Models
// ════════════════════════════════════════════════════════════════
class _AlertItem {
  final String patientId, patientName, reason, value;
  final dynamic ts;
  final bool isCritical;
  const _AlertItem({required this.patientId, required this.patientName,
      required this.reason, required this.value, required this.ts, required this.isCritical});
}

class _SosItem {
  final String patientId, sosId, patientName, glucose;
  final dynamic timestamp;
  const _SosItem({required this.patientId, required this.sosId,
      required this.patientName, required this.glucose, required this.timestamp});
}
