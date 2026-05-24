import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'analytics_view.dart';

class PatientProfilePage extends StatefulWidget {
  final String patientId, patientName;
  const PatientProfilePage(
      {super.key, required this.patientId, required this.patientName});
  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final _db = FirebaseDatabase.instance.ref();
  int _tab = 0;
  String _type = "Glucose";
  final _ctrl = TextEditingController();
  final _msgController = TextEditingController();
  final _prescController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    _msgController.dispose();
    _prescController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<void> _deleteMeasurement(String measId) async {
    await _db
        .child('measurements')
        .child(widget.patientId)
        .child(measId)
        .remove();
  }

  String _age(String? s) {
    if (s == null || s.isEmpty) return "--";
    try {
      String c = s.trim().replaceAll('/', '-');
      List<String> p = c.split('-');
      if (p.length != 3) return "--";
      DateTime b = p[0].length < 4
          ? DateTime.parse(
              "${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}")
          : DateTime.parse(c);
      int age = DateTime.now().year - b.year;
      final now = DateTime.now();
      if (now.month < b.month ||
          (now.month == b.month && now.day < b.day)) age--;
      return age >= 0 ? age.toString() : "--";
    } catch (_) {
      return "--";
    }
  }

  String _fmt(dynamic raw) {
    if (raw == null) return "--";
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      String s = raw.toString();
      return s.length > 16 ? s.substring(0, 16) : s;
    }
  }

  String _ago(dynamic raw) {
    if (raw == null) return "--";
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      Duration d = DateTime.now().difference(dt);
      if (d.inMinutes < 1) return "Just now";
      if (d.inMinutes < 60) return "${d.inMinutes} min ago";
      if (d.inHours < 24) return "${d.inHours} hr ago";
      return "${d.inDays} day(s) ago";
    } catch (_) {
      return "--";
    }
  }

  String _getStatus(String type, dynamic val) {
    double? v = double.tryParse(val?.toString() ?? "");
    if (v == null) return "Normal";
    String t = type.toLowerCase();
    if (t.contains("glucose") || t.contains("سكر")) {
      if (v < 70) return "Warning";
      if (v > 200) return "Critical";
      if (v > 140) return "Warning";
      return "Normal";
    }
    if (t.contains("pressure") || t.contains("ضغط")) {
      if (v > 160) return "Critical";
      if (v > 130) return "Warning";
      return "Normal";
    }
    return "Normal";
  }

  String _worst(Map? m) {
    if (m == null || m.isEmpty) return "Normal";
    String w = "Normal";
    for (var e in m.values) {
      String type =
          e['category']?.toString() ?? e['type']?.toString() ?? "";
      String s = _getStatus(type, e['value']);
      if (s == "Critical") return "Critical";
      if (s == "Warning") w = "Warning";
    }
    return w;
  }

  List<MapEntry> _sorted(Map m) {
    var list = m.entries.toList();
    list.sort((a, b) {
      int ms(dynamic t) {
        if (t == null) return 0;
        if (t is int) return t;
        int? v = int.tryParse(t.toString());
        if (v != null) return v;
        try {
          return DateTime.parse(t.toString()).millisecondsSinceEpoch;
        } catch (_) {
          return 0;
        }
      }

      return ms(b.value['timestamp'] ?? b.value['date'])
          .compareTo(ms(a.value['timestamp'] ?? a.value['date']));
    });
    return list;
  }

  List<MapEntry> _filteredMeas(Map m) {
    return _sorted(m).where((e) {
      String type =
          (e.value['type'] ?? e.value['category'] ?? "").toString().toLowerCase();
      return !type.contains("زيارة");
    }).toList();
  }

  List<Color> _statusColors(String s) {
    return {
          "Critical": [const Color(0xFFFDE8E8), const Color(0xFFE05C5C)],
          "Warning": [const Color(0xFFFFF9C4), const Color(0xFFD4A017)],
          "Normal": [const Color(0xFFDFF5EC), const Color(0xFF4CAF81)],
        }[s] ??
        [const Color(0xFFDFF5EC), const Color(0xFF4CAF81)];
  }

  Widget _statusChip(String s) {
    final colors = {
      "critical": [const Color(0xFFFFE4E6), const Color(0xFFE11D48)],
      "warning": [const Color(0xFFFEF3C7), const Color(0xFFD97706)],
      "normal": [const Color(0xFFDCFCE7), const Color(0xFF16A34A)],
    };
    final c = colors[s.toLowerCase()] ?? colors["normal"]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(20)),
      child: Text(s.toLowerCase(),
          style: TextStyle(
              color: c[1], fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  void _sendData(String path, String text, TextEditingController ctrl) {
    if (text.trim().isEmpty) return;
    _db.child(path).child(widget.patientId).push().set({
      'content': text.trim(),
      'sender': 'doctor',
      'timestamp': ServerValue.timestamp,
      'date': DateTime.now().toString().substring(0, 16),
    });
    ctrl.clear();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: Colors.grey),
          label: const Text("Back to Patients",
              style: TextStyle(color: Colors.grey, fontSize: 15)),
        ),
      ),
      body: StreamBuilder(
        stream: _db.child('users').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> uSnap) {
          if (uSnap.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF3B82F6)));
          }

          Map<String, dynamic> p = {};
          if (uSnap.hasData && uSnap.data!.snapshot.value != null) {
            (uSnap.data!.snapshot.value as Map)
                .forEach((k, v) => p[k.toString()] = v);
          }

          String fn = p['first_name']?.toString() ?? '';
          String ln = p['last_name']?.toString() ?? '';
          String name =
              (fn.isEmpty && ln.isEmpty) ? widget.patientName : "$fn $ln".trim();
          String age = _age(p['birth_date']?.toString());
          String email = p['email']?.toString() ?? 'No email';
          String phone = p['phone']?.toString() ?? 'No phone';
          String blood = p['blood_type']?.toString() ?? 'Unknown';
          String address =
              p['address']?.toString() ?? 'Address not set yet';
          String? photo = p['profile_image']?.toString();
          String initials = name.trim().isNotEmpty
              ? name
                  .trim()
                  .split(' ')
                  .where((e) => e.isNotEmpty)
                  .map((e) => e[0])
                  .take(2)
                  .join()
                  .toUpperCase()
              : "?";

          return StreamBuilder(
            stream:
                _db.child('measurements').child(widget.patientId).onValue,
            builder:
                (context, AsyncSnapshot<DatabaseEvent> mSnap) {
              Map? meas;
              if (mSnap.hasData &&
                  mSnap.data!.snapshot.value != null) {
                meas = {};
                (mSnap.data!.snapshot.value as Map)
                    .forEach((k, v) => meas![k.toString()] = v);
              }

              String st = _worst(meas);
              List<Color> sc = _statusColors(st);

              String alertVal = "--",
                  alertType = "Glucose",
                  alertTime = "--";
              if (meas != null && meas.isNotEmpty) {
                var latest = _sorted(meas).first.value;
                alertVal = "${latest['value'] ?? '--'} mg/dL";
                alertType = latest['category']?.toString() ??
                    latest['type']?.toString() ??
                    "Glucose";
                alertTime =
                    _ago(latest['timestamp'] ?? latest['date']);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Card ──────────────────────────────
                    _buildHeaderCard(
                        name, age, blood, email, phone, address,
                        photo, initials, st, sc),

                    // ── Alert Banner ─────────────────────────────
                    if (st == "Critical" || st == "Warning") ...[
                      const SizedBox(height: 20),
                      _buildAlertBanner(
                          st, sc, alertType, alertVal, alertTime),
                    ],

                    const SizedBox(height: 20),

                    // ── Tabs Card ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(children: [
                        // Tab bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          child: Row(
                            children: [
                              "Measurements",
                              "Analytics",
                              "Notes",
                              "Prescription",
                              "Messages"
                            ].asMap().entries.map((e) {
                              bool active = _tab == e.key;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _tab = e.key),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      right: 24),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  decoration: BoxDecoration(
                                    border: active
                                        ? const Border(
                                            bottom: BorderSide(
                                                color: Color(0xFF3B82F6),
                                                width: 2.5))
                                        : null,
                                  ),
                                  child: Text(e.value,
                                      style: TextStyle(
                                        color: active
                                            ? const Color(0xFF3B82F6)
                                            : Colors.grey,
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      )),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(
                            height: 1,
                            color: Color(0xFFF0F0F0)),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: _tab == 0
                              ? _measTab(meas)
                              : _tab == 1
                                  ? AnalyticsView(
                                      patientId: widget.patientId,
                                      patientName: name)
                                  : _tab == 2
                                      ? _notesTab()
                                      : _tab == 3
                                          ? _prescriptionTab()
                                          : _messagesTab(),
                        ),
                      ]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Header Card ────────────────────────────────────────────────────────

  Widget _buildHeaderCard(
      String name, String age, String blood, String email,
      String phone, String address, String? photo,
      String initials, String st, List<Color> sc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: const Color(0xFFEEF2FF),
          backgroundImage: (photo != null && photo.isNotEmpty)
              ? NetworkImage(photo)
              : null,
          child: (photo == null || photo.isEmpty)
              ? Text(initials,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5)))
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C))),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                        color: sc[0],
                        borderRadius: BorderRadius.circular(30)),
                    child: Text(st,
                        style: TextStyle(
                            color: sc[1],
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text("Age: $age",
                      style: const TextStyle(
                          color: Colors.blueGrey, fontSize: 13)),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text("•",
                          style:
                              TextStyle(color: Colors.blueGrey))),
                  Text("Blood: $blood",
                      style: const TextStyle(
                          color: Colors.blueGrey, fontSize: 13)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.phone_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(phone,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 20),
                  const Icon(Icons.mail_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Flexible(
                      child: Text(email,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13))),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Flexible(
                      child: Text(address,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13))),
                ]),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
            ),
            child: const Text("Edit Profile",
                style: TextStyle(
                    color: Color(0xFF2D3142), fontSize: 13)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _showDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              elevation: 0,
            ),
            child: const Text("Add Measurement",
                style:
                    TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ]),
      ]),
    );
  }

  // ── Alert Banner ───────────────────────────────────────────────────────

  Widget _buildAlertBanner(String st, List<Color> sc,
      String alertType, String alertVal, String alertTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sc[0],
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: sc[1], width: 4)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: sc[1], size: 24),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                  "${st == "Critical" ? "Critical Alert" : "Warning"}: High $alertType Level",
                  style: TextStyle(
                      color: sc[1],
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text(
                  "Latest: $alertVal ($alertTime). ${st == "Critical" ? "Immediate review required." : "Monitor closely."}",
                  style:
                      TextStyle(color: sc[1], fontSize: 13)),
            ])),
      ]),
    );
  }

  // ── Measurements Tab ───────────────────────────────────────────────────

  Widget _measTab(Map? meas) {
    List<MapEntry> list =
        meas != null ? _filteredMeas(meas) : [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Recent Measurements",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142))),
        ElevatedButton(
          onPressed: () => _showDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            elevation: 0,
          ),
          child: const Text("Add Measurement",
              style:
                  TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ]),
      const SizedBox(height: 20),
      if (list.isEmpty)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(40),
                child: Text("No measurements yet",
                    style: TextStyle(color: Colors.grey))))
      else
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Table(
            border: TableBorder(
                horizontalInside:
                    BorderSide(color: Colors.grey.shade100)),
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.0),
              5: FlexColumnWidth(1.3),
            },
            children: [
              TableRow(
                decoration:
                    BoxDecoration(color: Colors.grey.shade50),
                children: [
                  "Date & Time",
                  "Type",
                  "Value",
                  "Status",
                  "Source",
                  "Actions"
                ]
                    .map((h) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          child: Text(h,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey)),
                        ))
                    .toList(),
              ),
              ...list.map((entry) {
                var v = entry.value;
                String type = v['category']?.toString() ??
                    v['type']?.toString() ??
                    "--";
                dynamic timeRaw =
                    v['timestamp'] ?? v['date'];
                String status = _getStatus(type, v['value']);
                bool isDoctor = v['doctor_added'] == true;

                return TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    child: Text(_fmt(timeRaw),
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A5568))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    child: Text(type,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3142))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    child: Text(
                        "${v['value'] ?? '--'} ${v['unit'] ?? 'mg/dL'}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2D3142))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Center(child: _statusChip(status)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDoctor
                            ? const Color(0xFFEEF2FF)
                            : const Color(0xFFF0FFF4),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                          isDoctor ? "Doctor" : "Device",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: isDoctor
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF38A169),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.blue),
                          onPressed: () => _showDialog(
                              measId: entry.key,
                              existingData: v),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red),
                          onPressed: () =>
                              _deleteMeasurement(entry.key),
                        ),
                      ],
                    ),
                  ),
                ]);
              }),
            ],
          ),
        ),
    ]);
  }

  // ── Add / Edit Dialog ─────────────────────────────────────────────────

  void _showDialog({String? measId, Map? existingData}) {
    if (existingData != null) {
      _ctrl.text = existingData['value']?.toString() ?? "";
      _type = existingData['type']?.toString() ??
          existingData['category']?.toString() ??
          "Glucose";
    } else {
      _ctrl.clear();
      _type = "Glucose";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
            measId == null ? "Add Measurement" : "Edit Measurement"),
        content: StatefulBuilder(
          builder: (_, dialogState) => SizedBox(
            width: 350,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: "Measurement Type",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  "Glucose",
                  "Blood Pressure",
                  "Heart Rate",
                  "Weight",
                  "Temperature"
                ]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) dialogState(() => _type = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Value",
                  suffixText: _type == "Glucose"
                      ? "mg/dL"
                      : _type == "Blood Pressure"
                          ? "mmHg"
                          : _type == "Heart Rate"
                              ? "bpm"
                              : _type == "Weight"
                                  ? "kg"
                                  : "°C",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () async {
              if (_ctrl.text.trim().isEmpty) return;
              final unit = {
                    "Glucose": "mg/dL",
                    "Blood Pressure": "mmHg",
                    "Heart Rate": "bpm",
                    "Weight": "kg",
                    "Temperature": "°C",
                  }[_type] ??
                  "mg/dL";
              final data = {
                'value': _ctrl.text.trim(),
                'type': _type,
                'category': _type,
                'unit': unit,
                'doctor_added': true,
                if (measId == null)
                  'timestamp': ServerValue.timestamp,
                if (measId == null)
                  'date': DateTime.now().toString().substring(0, 16),
              };
              if (measId == null) {
                await _db
                    .child('measurements')
                    .child(widget.patientId)
                    .push()
                    .set(data);
              } else {
                await _db
                    .child('measurements')
                    .child(widget.patientId)
                    .child(measId)
                    .update(data);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Save",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Notes Tab ─────────────────────────────────────────────────────────

  Widget _notesTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Clinical Notes",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142))),
      const SizedBox(height: 16),
      // Input
      Row(children: [
        Expanded(
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write a clinical note...",
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () =>
              _sendData('notes', _noteController.text, _noteController),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add Note",
              style: TextStyle(color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 20),
      // List
      StreamBuilder(
        stream: _db.child('notes').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text("No notes yet",
                        style: TextStyle(color: Colors.grey))));
          }
          final Map raw = snap.data!.snapshot.value as Map;
          final entries = raw.entries.toList()
            ..sort((a, b) => (b.value['timestamp'] ?? 0)
                .compareTo(a.value['timestamp'] ?? 0));
          return Column(
            children: entries.map((e) {
              final d = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.shade200)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_outlined,
                          color: Color(0xFF3B82F6), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(d['content'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D3142))),
                            const SizedBox(height: 4),
                            Text(_fmt(d['timestamp']),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey)),
                          ])),
                    ]),
              );
            }).toList(),
          );
        },
      ),
    ]);
  }

  // ── Prescription Tab ──────────────────────────────────────────────────

  Widget _prescriptionTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Prescriptions",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _prescController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write prescription details...",
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _sendData(
              'prescriptions', _prescController.text, _prescController),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.medical_services_outlined,
              color: Colors.white),
          label: const Text("Add",
              style: TextStyle(color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 20),
      StreamBuilder(
        stream: _db
            .child('prescriptions')
            .child(widget.patientId)
            .onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text("No prescriptions yet",
                        style: TextStyle(color: Colors.grey))));
          }
          final Map raw = snap.data!.snapshot.value as Map;
          final entries = raw.entries.toList()
            ..sort((a, b) => (b.value['timestamp'] ?? 0)
                .compareTo(a.value['timestamp'] ?? 0));
          return Column(
            children: entries.map((e) {
              final d = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            const Color(0xFF10B981).withOpacity(0.3))),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(d['content'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D3142))),
                            const SizedBox(height: 4),
                            Text(_fmt(d['timestamp']),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey)),
                          ])),
                    ]),
              );
            }).toList(),
          );
        },
      ),
    ]);
  }

  // ── Messages Tab ──────────────────────────────────────────────────────

  Widget _messagesTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Messages",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142))),
      const SizedBox(height: 16),
      // Messages list
      StreamBuilder(
        stream:
            _db.child('messages').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text("No messages yet",
                        style: TextStyle(color: Colors.grey))));
          }
          final Map raw = snap.data!.snapshot.value as Map;
          final entries = raw.entries.toList()
            ..sort((a, b) => (a.value['timestamp'] ?? 0)
                .compareTo(b.value['timestamp'] ?? 0));
          return Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final d = entries[i].value;
                bool isDoctor = d['sender'] == 'doctor';
                return Align(
                  alignment: isDoctor
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: isDoctor
                          ? const Color(0xFF3B82F6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5)
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: isDoctor
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(d['content'] ?? '',
                              style: TextStyle(
                                  color: isDoctor
                                      ? Colors.white
                                      : const Color(0xFF2D3142),
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(_fmt(d['timestamp']),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDoctor
                                      ? Colors.white70
                                      : Colors.grey)),
                        ]),
                  ),
                );
              },
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      // Input
      Row(children: [
        Expanded(
          child: TextField(
            controller: _msgController,
            decoration: InputDecoration(
              hintText: "Write a message...",
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.all(14)),
          icon: const Icon(Icons.send, color: Colors.white),
          onPressed: () =>
              _sendData('messages', _msgController.text, _msgController),
        ),
      ]),
    ]);
  }
}
