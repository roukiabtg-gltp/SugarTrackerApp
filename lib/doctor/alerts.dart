import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fst;
import 'package:intl/intl.dart';
import 'patient_profile_page.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────
//  ALERTS PAGE  –  GlucoLink Doctor
//  مصادر البيانات:
//    • Firestore / measurements  ← قياسات critical من تطبيق المريض
//    • Realtime DB / sos/{patientId}/{sosId}  ← حالات SOS
// ─────────────────────────────────────────────

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  final _db  = FirebaseDatabase.instance.ref();
  final _fst = fst.FirebaseFirestore.instance;

  late final TabController _tabs;

  // ─── فلاتر ───
  String _filterType   = "All";   // All | critical | sos
  String _filterStatus = "All";   // All | unresolved | resolved

  // ─── ثوابت اللون ───
  static const _red    = Color(0xFFE53935);
  static const _orange = Color(0xFFFF6D00);
  static const _blue   = Color(0xFF1882FF);
  static const _bg     = Color(0xFFF5F7FB);
  static const _card   = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  أدوات مساعدة
  // ─────────────────────────────────────────────
  String _ago(dynamic raw) {
    if (raw == null) return "--";
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      Duration d = DateTime.now().difference(dt);
      if (d.inSeconds < 60)  return "Just now";
      if (d.inMinutes < 60)  return "${d.inMinutes}m ago";
      if (d.inHours   < 24)  return "${d.inHours}h ago";
      return "${d.inDays}d ago";
    } catch (_) { return "--"; }
  }

  String _fmtTime(dynamic raw) {
    if (raw == null) return "--";
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      return DateFormat("dd MMM · HH:mm").format(dt);
    } catch (_) { return "--"; }
  }

  double _glucoseVal(dynamic v) =>
      double.tryParse(v?.toString() ?? "") ?? 0.0;

  String _glucoseStatus(double v) {
    // القياس بـ g/L → 0.7–1.8 طبيعي
    // القياس بـ mg/dL → 70–180 طبيعي
    if (v < 10) {
      // على الأرجح g/L
      if (v < 0.7 || v > 1.8) return "critical";
      return "normal";
    } else {
      // على الأرجح mg/dL
      if (v < 70 || v > 180) return "critical";
      return "normal";
    }
  }

  String _glucoseLabel(double v) {
    if (v < 10) return "${v.toStringAsFixed(2)} g/L";
    return "${v.toStringAsFixed(0)} mg/dL";
  }

  String _thresholdLabel(double v) {
    if (v < 10) {
      if (v < 0.7) return "Below 0.7 g/L";
      return "Above 1.8 g/L";
    } else {
      if (v < 70) return "Below 70 mg/dL";
      return "Above 180 mg/dL";
    }
  }

  void _navigateToPatient(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientProfilePage(
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  حل التنبيه في Firestore
  // ─────────────────────────────────────────────
  Future<void> _resolveFirestoreAlert(String docId) async {
    await _fst.collection('measurements').doc(docId).update({
      'resolved': true,
      'resolvedAt': fst.FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  //  حل SOS في Realtime DB
  // ─────────────────────────────────────────────
  Future<void> _resolveSos(String patientId, String sosId) async {
    await _db.child('sos/$patientId/$sosId').update({
      'resolved': true,
      'resolvedAt': ServerValue.timestamp,
    });
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildStatsRow(),
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildCriticalMeasurementsTab(),
                _buildSosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Alerts",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1117))),
              const SizedBox(height: 2),
              Text("Real-time patient monitoring",
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
          const Spacer(),
          // ─ Badge الإشعارات ─
          StreamBuilder<fst.QuerySnapshot>(
            stream: _fst
                .collection('measurements')
                .where('status', isEqualTo: 'critical')
                .where('resolved', isEqualTo: false)
                .snapshots(),
            builder: (_, snap) {
              int cnt = snap.data?.docs.length ?? 0;
              return _bellBadge(cnt);
            },
          ),
        ],
      ),
    );
  }

  Widget _bellBadge(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: _blue, size: 22),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(10)),
              child: Text("$count",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  STATS ROW  –  3 بطاقات
  // ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // Critical Measurements
          Expanded(
            child: StreamBuilder<fst.QuerySnapshot>(
              stream: _fst
                  .collection('measurements')
                  .where('status', isEqualTo: 'critical')
                  .where('resolved', isEqualTo: false)
                  .snapshots(),
              builder: (_, snap) => _statCard(
                "Critical",
                snap.data?.docs.length ?? 0,
                Icons.warning_amber_rounded,
                _red,
                const Color(0xFFFFF0F0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // SOS Alerts
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _db.child('sos').onValue,
              builder: (_, snap) {
                int total = 0;
                if (snap.hasData && snap.data!.snapshot.value != null) {
                  Map sos = snap.data!.snapshot.value as Map;
                  for (var patient in sos.values) {
                    if (patient is Map) {
                      for (var s in patient.values) {
                        if (s is Map && s['resolved'] != true) total++;
                      }
                    }
                  }
                }
                return _statCard(
                  "SOS Alerts",
                  total,
                  Icons.sos_rounded,
                  _orange,
                  const Color(0xFFFFF5EC),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Total Patients
          Expanded(
            child: StreamBuilder<fst.QuerySnapshot>(
              stream: _fst.collection('users')
                  .where('role', isEqualTo: 'patient')
                  .snapshots(),
              builder: (_, snap) => _statCard(
                "Monitored",
                snap.data?.docs.length ?? 0,
                Icons.people_outline_rounded,
                _blue,
                const Color(0xFFEEF4FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, int value, IconData icon, Color col, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: col, size: 22),
          const SizedBox(height: 10),
          Text("$value",
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: col)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FILTER BAR  +  TABS
  // ─────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: _card,
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
          TabBar(
            controller: _tabs,
            labelColor: _blue,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: _blue,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13.5),
            tabs: const [
              Tab(text: "⚠️  Critical Measurements"),
              Tab(text: "🆘  SOS Calls"),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
          // ─ فلتر Resolved / Unresolved ─
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text("Show:",
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(width: 10),
                ...[
                  "All",
                  "Unresolved",
                  "Resolved",
                ].map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _filterChip(s, _filterStatus, (v) {
                        setState(() => _filterStatus = v);
                      }),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
      String label, String selected, ValueChanged<String> onTap) {
    final bool active = selected == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _blue : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade600,
                fontSize: 12.5,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB 1 : Critical Measurements  (Firestore)
  // ─────────────────────────────────────────────
  Widget _buildCriticalMeasurementsTab() {
    fst.Query<Map<String, dynamic>> query = _fst
        .collection('measurements')
        .where('status', isEqualTo: 'critical')
        .orderBy('timestamp', descending: true);

    return StreamBuilder<fst.QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _emptyState(
            Icons.check_circle_outline_rounded,
            Colors.green,
            "No critical alerts",
            "All patient readings are within normal range",
          );
        }

        List<fst.QueryDocumentSnapshot> docs = snap.data!.docs;

        // ─ تطبيق فلتر Resolved ─
        if (_filterStatus == "Unresolved") {
          docs = docs
              .where((d) =>
                  (d.data() as Map)['resolved'] != true)
              .toList();
        } else if (_filterStatus == "Resolved") {
          docs = docs
              .where((d) =>
                  (d.data() as Map)['resolved'] == true)
              .toList();
        }

        if (docs.isEmpty) {
          return _emptyState(
            Icons.filter_list_off_rounded,
            Colors.grey,
            "No alerts match this filter",
            "Try changing the filter above",
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final bool resolved = data['resolved'] == true;
            final double val = _glucoseVal(data['value']);
            final String pid   = data['patientId'] ?? "";
            final String pname = data['patientName'] ?? "Patient";

            return _measurementAlertCard(
              docId:      docs[i].id,
              patientId:  pid,
              patientName: pname,
              value:      val,
              category:   data['category'] ?? "Glucose",
              unit:       data['unit'] ?? "g/L",
              timestamp:  data['timestamp'],
              resolved:   resolved,
            );
          },
        );
      },
    );
  }

  Widget _measurementAlertCard({
    required String docId,
    required String patientId,
    required String patientName,
    required double value,
    required String category,
    required String unit,
    required dynamic timestamp,
    required bool resolved,
  }) {
    final bool isHigh   = value >= (unit == "g/L" ? 1.8 : 180);
    final Color accent  = resolved ? Colors.grey : _red;
    final Color bgColor = resolved
        ? const Color(0xFFF8F9FA)
        : const Color(0xFFFFF8F8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resolved
              ? const Color(0xFFE5E7EB)
              : _red.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ─ Header Row ─
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة الحالة
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    resolved
                        ? Icons.check_circle_rounded
                        : (isHigh
                            ? Icons.arrow_circle_up_rounded
                            : Icons.arrow_circle_down_rounded),
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // معلومات المريض
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(patientName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D1117))),
                          ),
                          const SizedBox(width: 8),
                          _typeBadge(
                              resolved ? "resolved" : "critical",
                              resolved ? Colors.grey : _red),
                          const SizedBox(width: 8),
                          _typeBadge(
                              isHigh ? "HIGH" : "LOW",
                              isHigh ? _orange : _blue),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$category • ${_fmtTime(timestamp != null ? (timestamp is fst.Timestamp ? timestamp.millisecondsSinceEpoch : timestamp) : null)}",
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // وقت منذ
                Text(
                  _ago(timestamp is fst.Timestamp
                      ? timestamp.millisecondsSinceEpoch
                      : timestamp),
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),

          // ─ Value Row ─
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                _valueBox("Measured",
                    "${value.toStringAsFixed(unit == 'g/L' ? 2 : 0)} $unit",
                    accent),
                const SizedBox(width: 10),
                _valueBox(
                  "Threshold",
                  isHigh
                      ? "Above ${unit == 'g/L' ? '1.8' : '180'} $unit"
                      : "Below ${unit == 'g/L' ? '0.7' : '70'} $unit",
                  Colors.grey.shade600,
                ),
                const Spacer(),
                // ─ Progress Bar (نسبة الخطر) ─
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Risk",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _riskLevel(value, unit),
                          backgroundColor: Colors.grey.shade100,
                          color: accent,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─ Action Row ─
          if (!resolved)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _resolveFirestoreAlert(docId),
                      icon: const Icon(Icons.check_rounded,
                          size: 16),
                      label: const Text("Mark Resolved"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(
                            color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _navigateToPatient(
                              patientId, patientName),
                      icon: const Icon(Icons.person_search_rounded,
                          size: 16, color: Colors.white),
                      label: const Text("View Patient",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text("Resolved",
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        _navigateToPatient(
                            patientId, patientName),
                    child: const Text("View Patient",
                        style: TextStyle(
                            fontSize: 12, color: _blue)),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _riskLevel(double v, String unit) {
    if (unit == "g/L") {
      if (v > 1.8) return ((v - 1.8) / 2.0).clamp(0.1, 1.0);
      if (v < 0.7) return ((0.7 - v) / 0.7).clamp(0.1, 1.0);
    } else {
      if (v > 180) return ((v - 180) / 400.0).clamp(0.1, 1.0);
      if (v < 70) return ((70 - v) / 70.0).clamp(0.1, 1.0);
    }
    return 0.1;
  }

  // ─────────────────────────────────────────────
  //  TAB 2 : SOS  (Realtime DB → sos/{uid}/{sosId})
  // ─────────────────────────────────────────────
  Widget _buildSosTab() {
    return StreamBuilder<DatabaseEvent>(
      stream: _db.child('sos').onValue,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return _emptyState(
            Icons.sos_rounded,
            Colors.orange,
            "No SOS alerts",
            "No emergency calls from patients",
          );
        }

        Map sosData = snap.data!.snapshot.value as Map;
        List<Map<String, dynamic>> items = [];

        sosData.forEach((patientId, patientSos) {
          if (patientSos is Map) {
            patientSos.forEach((sosId, sosVal) {
              if (sosVal is Map) {
                items.add({
                  'patientId': patientId.toString(),
                  'sosId':     sosId.toString(),
                  ...Map<String, dynamic>.from(sosVal),
                });
              }
            });
          }
        });

        // ترتيب من الأحدث للأقدم
        items.sort((a, b) {
          int ta = a['timestamp'] is int ? a['timestamp'] : 0;
          int tb = b['timestamp'] is int ? b['timestamp'] : 0;
          return tb.compareTo(ta);
        });

        // فلتر
        if (_filterStatus == "Unresolved") {
          items = items.where((m) => m['resolved'] != true).toList();
        } else if (_filterStatus == "Resolved") {
          items = items.where((m) => m['resolved'] == true).toList();
        }

        if (items.isEmpty) {
          return _emptyState(
            Icons.filter_list_off_rounded,
            Colors.grey,
            "No SOS alerts match this filter",
            "Try changing the filter above",
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _sosCard(items[i]),
        );
      },
    );
  }

  Widget _sosCard(Map<String, dynamic> data) {
    final bool resolved   = data['resolved'] == true;
    final String pid      = data['patientId'] ?? "";
    final String sosId    = data['sosId'] ?? "";
    final String pname    = data['patientName'] ?? "Patient";
    final String glucose  = data['glucose']?.toString() ?? "--";
    final String location = data['location'] ?? "";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: resolved
            ? const Color(0xFFF8F9FA)
            : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resolved
              ? const Color(0xFFE5E7EB)
              : _orange.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة SOS
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: resolved
                        ? Colors.grey.shade100
                        : _orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    resolved
                        ? Icons.check_circle_rounded
                        : Icons.sos_rounded,
                    color: resolved ? Colors.grey : _orange,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(pname,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D1117))),
                          ),
                          const SizedBox(width: 8),
                          _typeBadge(
                              resolved ? "resolved" : "SOS",
                              resolved ? Colors.grey : _orange),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtTime(data['timestamp']),
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  _ago(data['timestamp']),
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12),
                ),
              ],
            ),
          ),

          // ─ معلومات السكر والموقع ─
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                _valueBox("Glucose at SOS", "$glucose g/L",
                    resolved ? Colors.grey : _orange),
                if (location.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _locationChip(location),
                ],
              ],
            ),
          ),

          // ─ Buttons ─
          if (!resolved)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _resolveSos(pid, sosId),
                      icon: const Icon(Icons.check_rounded,
                          size: 16),
                      label: const Text("Resolve"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.grey.shade700,
                        side: BorderSide(
                            color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _navigateToPatient(pid, pname),
                      icon: const Icon(
                          Icons.person_search_rounded,
                          size: 16,
                          color: Colors.white),
                      label: const Text("View Patient",
                          style:
                              TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14,
                      color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text("Resolved",
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        _navigateToPatient(pid, pname),
                    child: const Text("View Patient",
                        style: TextStyle(
                            fontSize: 12, color: _blue)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS WIDGETS
  // ─────────────────────────────────────────────
  Widget _valueBox(String label, String value, Color col) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: col.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: col)),
        ],
      ),
    );
  }

  Widget _locationChip(String url) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              size: 14, color: _blue),
          const SizedBox(width: 4),
          Text("Location",
              style: const TextStyle(
                  fontSize: 12,
                  color: _blue,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _typeBadge(String label, Color col) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: col,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _emptyState(
      IconData icon, Color col, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: col.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: col),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
