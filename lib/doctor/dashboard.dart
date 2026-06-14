// ════════════════════════════════════════════════════════════════════════
// dashboard.dart — FIXED VERSION
// الإصلاحات:
//   1. يقرأ من doctors/{id}/alerts (نفس مصدر AlertsPage) بدل measurements
//   2. يستخدم نفس معايير التصنيف تماماً (0.54 / 0.70 / 1.80 / 2.50)
//   3. يتجاهل الإنذارات المحلولة (resolved == true)
//   4. يقرأ SOS من doctors/{id}/emergencies (نفس المصدر)
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fst;
import 'package:intl/intl.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});
  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final _db = FirebaseDatabase.instance.ref();
  final _fs = fst.FirebaseFirestore.instance;
  final String? _dId = FirebaseAuth.instance.currentUser?.uid;

  // ✅ نفس حدود AlertsPage تماماً
  static const double _lowCritical  = 0.54;
  static const double _lowWarning   = 0.70;
  static const double _highWarning  = 1.80;
  static const double _highCritical = 2.50;

  // ✅ نفس منطق التصنيف
  String _classifySeverity(double v) {
    if (v < _lowCritical || v > _highCritical) return 'critical';
    if (v < _lowWarning  || v > _highWarning)  return 'warning';
    return 'normal';
  }

  double _parseGlucose(dynamic val) {
    if (val == null) return 1.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 1.0;
  }

  _ApptStatus _apptStatus(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'confirme': case 'confirmé': case 'confirmed':
        return _ApptStatus.confirmed;
      case 'annule': case 'annulé': case 'cancelled': case 'canceled':
        return _ApptStatus.cancelled;
      default: return _ApptStatus.pending;
    }
  }

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
    final parts =
        name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_dId == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: StreamBuilder<DatabaseEvent>(
        // ── 1. قائمة المرضى ──────────────────────────────────────────
        stream: _db.child('users').orderByChild('doctorId').equalTo(_dId).onValue,
        builder: (_, usersSnap) {
          if (usersSnap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1882FF)));
          }
          final patientsMap = <String, Map<String, dynamic>>{};
          if (usersSnap.hasData && usersSnap.data!.snapshot.value != null) {
            (usersSnap.data!.snapshot.value as Map).forEach((k, v) {
              if (v is Map) patientsMap[k.toString()] = Map<String, dynamic>.from(v);
            });
          }
          final patientIds = patientsMap.keys.toList();

          return StreamBuilder<DatabaseEvent>(
            // ── 2. ✅ إنذارات السكر من نفس مصدر AlertsPage ──────────
            stream: _db.child('doctors/$_dId/alerts').onValue,
            builder: (_, alertsSnap) {
              int critCount = 0, warnCount = 0;

              if (alertsSnap.hasData &&
                  alertsSnap.data!.snapshot.value != null) {
                final rawAlerts = Map<dynamic, dynamic>.from(
                    alertsSnap.data!.snapshot.value as Map);

                for (final e in rawAlerts.entries) {
                  final data = Map<String, dynamic>.from(e.value);

                  // ✅ تجاهل المحلولة
                  if (data['resolved'] == true) continue;

                  final glucose = _parseGlucose(data['glucose']);
                  final severity = _classifySeverity(glucose);

                  if (severity == 'critical') critCount++;
                  else if (severity == 'warning') warnCount++;
                }
              }

              return StreamBuilder<DatabaseEvent>(
                // ── 3. ✅ SOS من نفس مصدر AlertsPage ────────────────
                stream: _db.child('doctors/$_dId/emergencies').onValue,
                builder: (_, sosSnap) {
                  int sosCount = 0;
                  if (sosSnap.hasData &&
                      sosSnap.data!.snapshot.value != null) {
                    final rawSos = Map<dynamic, dynamic>.from(
                        sosSnap.data!.snapshot.value as Map);
                    rawSos.forEach((_, v) {
                      if (v is Map && v['resolved'] != true) sosCount++;
                    });
                  }

                  return StreamBuilder<fst.QuerySnapshot>(
                    // ── 4. مواعيد اليوم ──────────────────────────────
                    stream: _fs
                        .collection('appointments')
                        .where('doctorId', isEqualTo: _dId)
                        .snapshots(),
                    builder: (_, apSnap) {
                      final todayDocs =
                          (apSnap.data?.docs ?? []).where((d) =>
                              (d.data() as Map)['date']
                                  ?.toString()
                                  .startsWith(todayStr) ==
                              true).toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header ───────────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Dashboard',
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A237E))),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('EEEE, MMMM d yyyy')
                                          .format(DateTime.now()),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                                _doctorCodeCard(),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // ── البطاقات الأربع ───────────────────────
                            Row(children: [
                              _statCard(
                                'Total Patients',
                                '${patientIds.length}',
                                Icons.people_alt_outlined,
                                const Color(0xFF3B82F6),
                                const Color(0xFFEFF6FF),
                              ),
                              const SizedBox(width: 20),
                              // ✅ Critical = إنذارات حرجة + SOS نشطة
                              _statCard(
                                'Critical Alerts',
                                '${critCount + sosCount}',
                                Icons.warning_amber_rounded,
                                const Color(0xFFEF4444),
                                const Color(0xFFFEF2F2),
                                blink: critCount + sosCount > 0,
                              ),
                              const SizedBox(width: 20),
                              // ✅ Warnings = إنذارات تحذيرية فقط
                              _statCard(
                                'Warnings',
                                '$warnCount',
                                Icons.info_outline_rounded,
                                const Color(0xFFF59E0B),
                                const Color(0xFFFFFBEB),
                              ),
                              const SizedBox(width: 20),
                              _statCard(
                                "Today's Appointments",
                                '${todayDocs.length}',
                                Icons.calendar_today_outlined,
                                const Color(0xFF10B981),
                                const Color(0xFFF0FFF4),
                              ),
                            ]),
                            const SizedBox(height: 28),

                            // ── Today's Appointments ─────────────────
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text("Today's Appointments",
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E293B))),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('EEEE, MMMM d yyyy')
                                                .format(DateTime.now()),
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.grey.shade200),
                                        ),
                                        child: const Text('View All',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF374151))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(
                                      color: Colors.grey.shade100, height: 20),
                                  todayDocs.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 32),
                                          child: Column(children: [
                                            Icon(
                                                Icons.event_available_outlined,
                                                size: 42,
                                                color: Colors.grey
                                                    .withOpacity(0.35)),
                                            const SizedBox(height: 12),
                                            const Text(
                                                'No appointments today',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13)),
                                          ]),
                                        )
                                      : Column(
                                          children: todayDocs.map((doc) {
                                            final d = doc.data()
                                                as Map<String, dynamic>;
                                            final st = _apptStatus(
                                                d['status']?.toString());
                                            final name =
                                                d['patientName']?.toString() ??
                                                    'Patient';
                                            final colors = _avatarColors(name);
                                            final time =
                                                d['time']?.toString() ?? '--';
                                            final type =
                                                d['type']?.toString() ?? '--';
                                            final loc = d['location']
                                                    ?.toString() ??
                                                d['room']?.toString() ??
                                                '--';
                                            final age = d['age'];
                                            final isVirtual = loc
                                                    .toLowerCase()
                                                    .contains('virtual') ||
                                                loc
                                                    .toLowerCase()
                                                    .contains('online');

                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 13),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                      color:
                                                          Colors.grey.shade100,
                                                      width: 0.8),
                                                ),
                                              ),
                                              child: Row(children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: colors[0],
                                                  child: Text(
                                                    _initials(name),
                                                    style: TextStyle(
                                                        color: colors[1],
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(name,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 13,
                                                              color: Color(
                                                                  0xFF111827))),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        age != null
                                                            ? '$type · Age $age'
                                                            : type,
                                                        style: const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(children: [
                                                  Icon(
                                                      Icons
                                                          .access_time_outlined,
                                                      size: 13,
                                                      color: Colors
                                                          .grey.shade500),
                                                  const SizedBox(width: 4),
                                                  Text(time,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey.shade600)),
                                                ]),
                                                const SizedBox(width: 16),
                                                Row(children: [
                                                  Icon(
                                                    isVirtual
                                                        ? Icons.videocam_outlined
                                                        : Icons
                                                            .meeting_room_outlined,
                                                    size: 13,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(loc,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey.shade600)),
                                                ]),
                                                const SizedBox(width: 16),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: st.bgColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    st.label,
                                                    style: TextStyle(
                                                        color: st.color,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold),
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
          const Text('Your doctor code',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
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
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _dId ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Code copied!'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
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
      ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color,
      Color bg, {bool blink = false}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              if (blink)
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.5),
                          blurRadius: 6)
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Text(value,
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
  String get label {
    switch (this) {
      case _ApptStatus.confirmed: return 'Confirmé';
      case _ApptStatus.cancelled: return 'Annulé';
      case _ApptStatus.pending:   return 'En attente';
    }
  }
}