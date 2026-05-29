import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _db = FirebaseDatabase.instance.ref();
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', '24 Hours', '7 Days', '30 Days'];

  String _fmt(dynamic raw) {
    if (raw == null) return '--';
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      return DateFormat('dd MMM yyyy  HH:mm').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  bool _inRange(dynamic raw) {
    if (_selectedFilter == 'All') return true;
    if (raw == null) return false;
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      final now = DateTime.now();
      if (_selectedFilter == '24 Hours') return now.difference(dt).inHours <= 24;
      if (_selectedFilter == '7 Days')   return now.difference(dt).inDays <= 7;
      if (_selectedFilter == '30 Days')  return now.difference(dt).inDays <= 30;
    } catch (_) {}
    return false;
  }

  String _statusFor(String type, dynamic val) {
    double? v = double.tryParse(val?.toString() ?? '');
    if (v == null) return 'Normal';
    String t = type.toLowerCase();
    if (t.contains('glucose') || t.contains('سكر')) {
      if (v < 70 || v > 200) return 'Critical';
      if (v > 140) return 'Warning';
      return 'Normal';
    }
    if (t.contains('pressure') || t.contains('ضغط')) {
      if (v > 160) return 'Critical';
      if (v > 130) return 'Warning';
      return 'Normal';
    }
    return 'Normal';
  }

  Color _statusColor(String s) {
    return {'Critical': const Color(0xFFE05C5C), 'Warning': const Color(0xFFD4A017)}[s] ?? const Color(0xFF10B981);
  }

  Color _statusBg(String s) {
    return {'Critical': const Color(0xFFFDE8E8), 'Warning': const Color(0xFFFFF9C4)}[s] ?? const Color(0xFFDFF5EC);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    SizedBox(height: 4),
                    Text('All patients measurements overview', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
                // Filter buttons
                Row(
                  children: _filters.map((f) {
                    final selected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedFilter = f),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected ? const Color(0xFF3B82F6) : Colors.white,
                          side: BorderSide(color: selected ? const Color(0xFF3B82F6) : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text(f, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.w500)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Content ────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder(
                stream: _db.child('users').orderByChild('doctorId').equalTo(doctorId).onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                  }
                  if (!snap.hasData || snap.data!.snapshot.value == null) {
                    return const Center(child: Text('No patients found', style: TextStyle(color: Colors.grey, fontSize: 16)));
                  }

                  final Map patientsRaw = snap.data!.snapshot.value as Map;
                  final patients = patientsRaw.entries.toList();

                  return StreamBuilder(
                    stream: _db.child('measurements').onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> mSnap) {
                      Map allMeas = {};
                      if (mSnap.hasData && mSnap.data!.snapshot.value != null) {
                        allMeas = mSnap.data!.snapshot.value as Map;
                      }

                      // Build rows
                      List<Map<String, dynamic>> rows = [];
                      for (var p in patients) {
                        final pid  = p.key.toString();
                        final info = p.value as Map;
                        final fn   = info['first_name']?.toString() ?? '';
                        final ln   = info['last_name']?.toString() ?? '';
                        final name = '$fn $ln'.trim().isEmpty ? 'Unknown' : '$fn $ln'.trim();

                        final measMap = allMeas[pid];
                        if (measMap == null) continue;

                        (measMap as Map).forEach((key, val) {
                          final ts = val['timestamp'] ?? val['date'];
                          if (!_inRange(ts)) return;
                          final type   = val['type']?.toString() ?? val['category']?.toString() ?? 'Glucose';
                          final value  = val['value']?.toString() ?? '--';
                          final status = _statusFor(type, val['value']);
                          rows.add({
                            'patient': name,
                            'type':    type,
                            'value':   value,
                            'unit':    val['unit']?.toString() ?? 'mg/dL',
                            'status':  status,
                            'time':    _fmt(ts),
                            'raw_ts':  ts is int ? ts : 0,
                          });
                        });
                      }

                      // Sort newest first
                      rows.sort((a, b) => (b['raw_ts'] as int).compareTo(a['raw_ts'] as int));

                      // Stats
                      int total    = rows.length;
                      int critical = rows.where((r) => r['status'] == 'Critical').length;
                      int warning  = rows.where((r) => r['status'] == 'Warning').length;
                      int normal   = rows.where((r) => r['status'] == 'Normal').length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary cards
                          Row(
                            children: [
                              _statCard('Total Readings', total.toString(), const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                              const SizedBox(width: 16),
                              _statCard('Critical', critical.toString(), const Color(0xFFE05C5C), const Color(0xFFFDE8E8)),
                              const SizedBox(width: 16),
                              _statCard('Warning', warning.toString(), const Color(0xFFD4A017), const Color(0xFFFFF9C4)),
                              const SizedBox(width: 16),
                              _statCard('Normal', normal.toString(), const Color(0xFF10B981), const Color(0xFFDFF5EC)),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Table
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: rows.isEmpty
                                  ? const Center(child: Text('No data in this period', style: TextStyle(color: Colors.grey, fontSize: 15)))
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SingleChildScrollView(
                                        child: Table(
                                          border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
                                          columnWidths: const {
                                            0: FlexColumnWidth(2.2),
                                            1: FlexColumnWidth(1.5),
                                            2: FlexColumnWidth(1.5),
                                            3: FlexColumnWidth(1.3),
                                            4: FlexColumnWidth(2.5),
                                          },
                                          children: [
                                            // Header
                                            TableRow(
                                              decoration: BoxDecoration(color: Colors.grey.shade50),
                                              children: ['Patient', 'Type', 'Value', 'Status', 'Date & Time']
                                                  .map((h) => Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                        child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                                                      ))
                                                  .toList(),
                                            ),
                                            // Rows
                                            ...rows.map((r) => TableRow(
                                                  children: [
                                                    _cell(r['patient']),
                                                    _cell(r['type']),
                                                    _cell('${r['value']} ${r['unit']}', bold: true),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _statusBg(r['status']),
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Text(
                                                          r['status'],
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(color: _statusColor(r['status']), fontSize: 12, fontWeight: FontWeight.w600),
                                                        ),
                                                      ),
                                                    ),
                                                    _cell(r['time'], muted: true),
                                                  ],
                                                )),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _cell(String text, {bool bold = false, bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: muted ? Colors.grey : const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
