import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'analytics_view.dart';

class PatientProfilePage extends StatefulWidget {
  final String patientId, patientName;
  const PatientProfilePage({super.key, required this.patientId, required this.patientName});
  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final _db = FirebaseDatabase.instance.ref();
  int _tab = 0;
  String _type = "Glucose", _timing = "Fasting";
  String _selectedFilter = '7 DAYS'; // للتحكم في الأزرار العلوية
  final _ctrl = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _prescController = TextEditingController();

  @override
  void dispose() { 
    _ctrl.dispose(); 
    _msgController.dispose();
    _prescController.dispose();
    super.dispose(); 
  }
  
  // دالة لحذف سجل القياس من قاعدة البيانات
  Future<void> _deleteMeasurement(String measId) async {
    await _db.child('measurements').child(widget.patientId).child(measId).remove();
  }

  String _age(String? s) {
    if (s == null || s.isEmpty) return "--";
    try {
      // 1. تنظيف النص وتبديل / بـ -
      String cleanDate = s.trim().replaceAll('/', '-');
      // 2. تقسيم التاريخ بناءً على الفاصل -
      List<String> parts = cleanDate.split('-');
      DateTime birthDate;
      // 3. التحقق من الترتيب: إذا كان الجزء الأول يتكون من رقمين أو رقم (يوم)
      if (parts.length == 3) {
        if (parts[0].length < 4) {
          // ترتيب البيانات القادمة من Firebase (7/12/2005) هو يوم/شهر/سنة
          // نحوله إلى سنة-شهر-يوم ليقبله DateTime.parse
          String year = parts[2];
          String month = parts[1].padLeft(2, '0');
          String day = parts[0].padLeft(2, '0');
          birthDate = DateTime.parse("$year-$month-$day");
        } else {
          // إذا كان مخزناً بالأصل سنة-شهر-يوم
          birthDate = DateTime.parse(cleanDate);
        }
      } else {
        return "--";
      }

      // 4. حساب الفرق بين الآن وتاريخ الميلاد
      DateTime now = DateTime.now();
      int age = now.year - birthDate.year;
      
      // تقليل السنة إذا لم يأتِ يوم ميلاده بعد في السنة الحالية
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      return age >= 0 ? age.toString() : "--";
    } catch (e) {
      debugPrint("خطأ نهائي في المعالجة: $s => $e");
      return "--";
    }
  }

  String _fmt(dynamic raw) {
    if (raw == null) return "--";
    try {
      DateTime dt;
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      if (ms != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(ms > 9999999999 ? ms : ms * 1000);
      } else {
        dt = DateTime.parse(raw.toString());
      }
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      String s = raw.toString();
      return s.length > 16 ? s.substring(0, 16) : s;
    }
  }

  String _ago(dynamic raw) {
    if (raw == null) return "--";
    try {
      DateTime dt;
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      if (ms != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(ms > 9999999999 ? ms : ms * 1000);
      } else {
        dt = DateTime.parse(raw.toString());
      }
      Duration d = DateTime.now().difference(dt);
      if (d.inMinutes < 1) return "Just now";
      if (d.inMinutes < 60) return "${d.inMinutes} min ago";
      if (d.inHours < 24) return "${d.inHours} hr ago";
      return "${d.inDays} day(s) ago";
    } catch (_) { return "--"; }
  }

 String getStatus(double value, String timing) {
  if (timing == "Fasting") {
    if (value < 0.7) return "Low";
    if (value >= 0.7 && value <= 1.1) return "Normal";
    return "Warning"; // أكبر من 1.1 صايم
  } else { // After Meal مثلاً
    if (value < 0.7) return "Low";
    if (value < 1.4) return "Normal";
    return "Warning"; // أكبر من 1.4 فاطر
  }
}

  // دالة تصفية القياسات لاستبعاد الزيارات والقيم الشاذة (0 أو 9500)
  List<MapEntry> _getFilteredMeasurements(Map m) {
    var list = m.entries.where((e) {
      String type = (e.value['type'] ?? e.value['category'] ?? "").toString().toLowerCase();
      
      if (type.contains("زيارة")) return false;
      
      double? val = double.tryParse(e.value['value']?.toString() ?? "");
      if (val != null) {
        if (type.contains("glucose") || type.contains("سكر") || type.contains("أكل")) {
          if (val <= 0 || val > 1000) return false;
        }
      }
      return true;
    }).toList();

    list.sort((a, b) {
      int getMs(dynamic t) {
        if (t == null) return 0;
        if (t is int) return t;
        return DateTime.tryParse(t.toString())?.millisecondsSinceEpoch ?? 0;
      }
      return getMs(b.value['timestamp'] ?? b.value['date'])
          .compareTo(getMs(a.value['timestamp'] ?? a.value['date']));
    });
    return list;
  }

  // تحويل البيانات المصفاة إلى Map ممرر مباشرة لصفحة التحليلات
  Map _getFilteredMapForAnalytics(Map m) {
    var filteredList = _getFilteredMeasurements(m);
    Map result = {};
    for (var entry in filteredList) {
      result[entry.key] = entry.value;
    }
    return result;
  }

  Widget _statusChip(String s) {
    Color bg, txt;
    switch (s.toLowerCase()) {
      case 'critical':
        bg = const Color(0xFFFFE4E6);
        txt = const Color(0xFFE11D48);
        break;
      case 'warning':
        bg = const Color(0xFFFEF3C7); 
        txt = const Color(0xFFD97706);
        break;
      default:
        bg = const Color(0xFFDCFCE7); 
        txt = const Color(0xFF16A34A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(s.toLowerCase(), style: TextStyle(color: txt, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _worst(Map? m) {
    if (m == null || m.isEmpty) return "Normal";
    String w = "Normal";
    for (var e in m.values) {
      String type = e['category']?.toString() ?? e['type']?.toString() ?? "";
      double? value = double.tryParse(e['value']?.toString() ?? "");
      if (value == null) continue;
      String s = getStatus(value, type.toLowerCase().contains("صايم") || type.toLowerCase().contains("fasting") ? "Fasting" : "After Meal");
      if (s == "Critical") return "Critical";
      if (s == "Warning") w = "Warning";
    }
    return w;
  }

  List<MapEntry> _sorted(Map m) {
    var list = m.entries.toList();
    list.sort((a, b) {
      int getMs(dynamic t) {
        if (t == null) return 0;
        if (t is int) return t;
        int? ms = int.tryParse(t.toString());
        if (ms != null) return ms;
        try { return DateTime.parse(t.toString()).millisecondsSinceEpoch; } catch (_) { return 0; }
      }
      dynamic ta = a.value['timestamp'] ?? a.value['date'];
      dynamic tb = b.value['timestamp'] ?? b.value['date'];
      return getMs(tb).compareTo(getMs(ta));
    });
    return list;
  }

  Widget _chip(String s) {
    final Map<String, List<Color>> colors = {
      "Critical": [const Color(0xFFFDE8E8), const Color(0xFFE05C5C)],
      "Warning":  [const Color(0xFFFFF9C4), const Color(0xFFD4A017)],
      "Normal":   [const Color(0xFFDFF5EC), const Color(0xFF4CAF81)],
    };
    var c = colors[s] ?? colors["Normal"]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(30)),
      child: Text(s.toLowerCase(), style: TextStyle(color: c[1], fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  List<Color> _statusColors(String s) {
    final Map<String, List<Color>> colors = {
      "Critical": [const Color(0xFFFDE8E8), const Color(0xFFE05C5C)],
      "Warning":  [const Color(0xFFFFF9C4), const Color(0xFFD4A017)],
      "Normal":   [const Color(0xFFDFF5EC), const Color(0xFF4CAF81)],
    };
    return colors[s] ?? colors["Normal"]!;
  }

  void _sendData(String path, String text) {
    if (text.trim().isEmpty) return;
    _db.child(path).child(widget.patientId).push().set({
      'content': text.trim(),
      'sender': 'doctor',
      'timestamp': ServerValue.timestamp,
      'date': DateTime.now().toString().substring(0, 16),
    });
  }

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
          label: const Text("Back to Patients", style: TextStyle(color: Colors.grey, fontSize: 15)),
        ),
      ),
      body: StreamBuilder(
        stream: _db.child('users').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> uSnap) {
          if (uSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          }

          Map<String, dynamic> p = {};
          if (uSnap.hasData && uSnap.data!.snapshot.value != null) {
            (uSnap.data!.snapshot.value as Map).forEach((k, v) {
              p[k.toString()] = v;
            });
          }

          String fn      = p['first_name']?.toString() ?? '';
          String ln      = p['last_name']?.toString() ?? '';
          String name    = (fn.isEmpty && ln.isEmpty) ? widget.patientName : "$fn $ln".trim();
          String age     = _age(p['birth_date']?.toString());
          String email   = p['email']?.toString() ?? 'No email';
          String phone   = p['phone']?.toString() ?? 'No phone';
          String blood   = p['blood_type']?.toString() ?? 'Unknown';
          String address = p['address']?.toString() ?? 'Address not set yet';
          String? profileImageUrl = p['profile_image']?.toString();
          String initials = name.trim().isNotEmpty
              ? name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
              : "?";

          return StreamBuilder(
            stream: _db.child('measurements').child(widget.patientId).onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> mSnap) {
              Map? meas;
              if (mSnap.hasData && mSnap.data!.snapshot.value != null) {
                meas = {};
                (mSnap.data!.snapshot.value as Map).forEach((k, v) {
                  meas![k.toString()] = v;
                });
              }

              String st = _worst(meas);
              List<Color> sc = _statusColors(st);

              String alertVal = "--", alertType = "Glucose", alertTime = "--";
              if (meas != null && meas.isNotEmpty) {
                var latest = _getFilteredMeasurements(meas).isNotEmpty 
                    ? _getFilteredMeasurements(meas).first.value 
                    : _sorted(meas).first.value;
                alertVal  = "${latest['value'] ?? '--'} mg/dL";
                alertType = latest['category']?.toString() ?? latest['type']?.toString() ?? "Glucose";
                alertTime = _ago(latest['timestamp'] ?? latest['date']);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: const Color(0xFFEEF2FF),
                        backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: (profileImageUrl == null || profileImageUrl.isEmpty)
                            ? Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)))
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(color: sc[0], borderRadius: BorderRadius.circular(30)),
                              child: Text(st, style: TextStyle(color: sc[1], fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Text("Age: $age", style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text("•", style: TextStyle(color: Colors.blueGrey))),
                            Text("Blood Type: $blood", style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(width: 20),
                            const Icon(Icons.mail_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 5),
                            Flexible(child: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 5),
                            Flexible(child: Text(address, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                          ]),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          child: const Text("Edit Profile", style: TextStyle(color: Color(0xFF2D3142), fontSize: 13)),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _showDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            elevation: 0,
                          ),
                          child: const Text("Add Measurement", style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ]),
                    ]),
                  ),

                  // Alert Banner
                  if (st == "Critical" || st == "Warning") ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sc[0],
                        borderRadius: BorderRadius.circular(10),
                        border: Border(left: BorderSide(color: sc[1], width: 4)),
                      ),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded, color: sc[1], size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            "${st == "Critical" ? "Critical Alert" : "Warning"}: High $alertType Level",
                            style: TextStyle(color: sc[1], fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            "Latest: $alertVal ($alertTime). ${st == "Critical" ? "Immediate review required." : "Monitor closely."}",
                            style: TextStyle(color: sc[1], fontSize: 13),
                          ),
                        ])),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Tabs Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                    ),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: ["Measurements", "Analytics", "Notes", "Prescription", "Messages"]
                              .asMap().entries.map((e) {
                            bool active = _tab == e.key;
                            return GestureDetector(
                              onTap: () => setState(() => _tab = e.key),
                              child: Container(
                                margin: const EdgeInsets.only(right: 24),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  border: active ? const Border(bottom: BorderSide(color: Color(0xFF3B82F6), width: 2.5)) : null,
                                ),
                                child: Text(e.value, style: TextStyle(
                                  color: active ? const Color(0xFF3B82F6) : Colors.grey,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                )),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: _tab == 0
                            ? _measTab(meas)
                            // ربط الصفحة المحدثة مع تمرير الماب الحقيقي والمصفى بالكامل
                            : _tab == 1
                            ? AnalyticsView(measurements: meas != null ? _getFilteredMapForAnalytics(meas) : {})
                            : _tab == 2
                            ? _buildNotesTab()
                            : _tab == 3
                            ? _buildPrescriptionTab()
                            : _tab == 4
                            ? _buildMessagesTab()
                            : Center(child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Text(
                                  "${["Measurements","Analytics","Notes","Prescription","Messages"][_tab]} - Coming soon",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )),
                      ),
                    ]),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _measTab(Map? meas) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Recent Measurements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        ElevatedButton(
          onPressed: _showDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            elevation: 0,
          ),
          child: const Text("Add Measurement", style: TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ]),
      const SizedBox(height: 20),
      if (meas == null || meas.isEmpty)
        const Center(child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("No measurements yet", style: TextStyle(color: Colors.grey)),
        ))
      else
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Table(
            border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
            columnWidths: const {
              0: FlexColumnWidth(2.5), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.2), 4: FlexColumnWidth(1.0), 5: FlexColumnWidth(1.3),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: ["Date & Time", "Type", "Value", "Status", "Source", "Actions"].map((h) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                  )
                ).toList(),
              ),
              ..._getFilteredMeasurements(meas).map((entry) {
                var v = entry.value;
                String type     = v['category']?.toString() ?? v['type']?.toString() ?? "--";
                dynamic timeRaw = v['timestamp'] ?? v['date'];
                String status   = getStatus(double.tryParse(v['value']?.toString() ?? "") ?? 0, type);
                bool isDoctor   = v['doctor_added'] == true;
                return TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(_fmt(timeRaw), style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(type, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(
                      "${v['value'] ?? '--'} ${v['unit'] ?? 'mg/dL'}",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2D3142)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: _chip(status),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDoctor ? const Color(0xFFEEF2FF) : const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isDoctor ? "Doctor" : "Device",
                        style: TextStyle(
                          color: isDoctor ? const Color(0xFF4F46E5) : const Color(0xFF38A169),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                          onPressed: () => _showDialog(measId: entry.key, existingData: v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => _deleteMeasurement(entry.key),
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

  // التعديل الرئيسي تم هنا بالكامل لحفظ الحقول المناسبة للجدول والمنحنيات
  void _showDialog({String? measId, Map? existingData}) {
    if (existingData != null) {
      _ctrl.text = existingData['value']?.toString() ?? "";
      _type = existingData['type'] ?? "Glucose";
    } else {
      _ctrl.clear();
      _type = "Glucose";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(measId == null ? "إضافة قياس" : "تعديل القياس"),
        content: TextField(controller: _ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (_ctrl.text.trim().isEmpty) return;

              // 1. إنشاء صيغة تاريخ كاملة للجدول والتحليل
              String formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
              // 2. إنشاء صيغة وقت ميلي-ثانية للترتيب والتصفيات
              int timestamp = DateTime.now().millisecondsSinceEpoch;

              // 3. توحيد بناء البيانات لتطابق تطبيق المريض والتحليل تماماً
              final data = {
                "value": _ctrl.text.trim(),
                "type": _type,
                "category": "السكر", // مضافة لدعم تصفية جدول التحليلات باللغة العربية
                "unit": "mg/dL",
                "date": formattedDate, // لتظهر بوضوح في حقول التاريخ والوقت
                "timestamp": timestamp, // للترتيب والفرز الزمني
                "doctor_added": true
              };

              if (measId == null) {
                await _db.child('measurements').child(widget.patientId).push().set(data);
              } else {
                await _db.child('measurements').child(widget.patientId).child(measId).update(data);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text("Notes - Coming soon", style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildPrescriptionTab() {
    return Container(
      height: 300,
      child: StreamBuilder(
        stream: _db.child('prescriptions').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No prescriptions yet'));
          }
          Map data = snapshot.data!.snapshot.value as Map;
          List<MapEntry> entries = data.entries.toList();
          entries.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              var item = entries[index].value;
              return ListTile(
                title: Text(item['content'] ?? ''),
                subtitle: Text(_fmt(item['timestamp'])),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        Container(
          height: 300,
          child: StreamBuilder(
            stream: _db.child('messages').child(widget.patientId).onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Center(child: Text('No messages yet'));
              }
              Map data = snapshot.data!.snapshot.value as Map;
              List<MapEntry> entries = data.entries.toList();
              entries.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  var item = entries[index].value;
                  return ListTile(
                    title: Text(item['content'] ?? ''),
                    subtitle: Text(_fmt(item['timestamp'])),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  decoration: InputDecoration(
                    hintText: "اكتب هنا...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF4F46E5)),
                onPressed: () {
                  _sendData('messages', _msgController.text);
                  _msgController.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}