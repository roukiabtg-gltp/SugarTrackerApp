import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_profile_page.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});
  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final _db = FirebaseDatabase.instance.ref();
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;
  String searchQuery = "", selectedStatus = "All Status";

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

  // 1. تحسين منطق الحالة (Status Logic) مع دعم الكلمات العربية من الصورة
String _getStatus(String type, dynamic val) {
  double? v = double.tryParse(val?.toString() ?? "");
  if (v == null) return "Normal";
  String t = type.toLowerCase();

  // فحص السكر (Glucose)
  if (t.contains("glucose") || t.contains("سكر") || t.contains("أكل")) {
    if (v < 70) return "Warning"; // انخفاض
    if (v > 200) return "Critical"; 
    if (v > 140) return "Warning";
    return "Normal";
  }
  // فحص الضغط (Pressure) - التعامل مع الضغط الانقباضي كمثال
  if (t.contains("pressure") || t.contains("ضغط")) {
    if (v > 160) return "Critical";
    if (v > 130) return "Warning";
    return "Normal";
  }
  return "Normal";
}

// 2. تحديث قائمة القياسات لاستبعاد الزيارات
List<MapEntry> _getFilteredMeasurements(Map m) {
  var list = m.entries.where((e) {
    String type = (e.value['type'] ?? e.value['category'] ?? "").toString().toLowerCase();
    return !type.contains("زيارة"); // حذف أي سجل يحتوي على كلمة زيارة
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

// 3. تحسين تصميم الـ Chip (Status Design)
Widget _statusChip(String s) {
  Color bg, txt;
  switch (s.toLowerCase()) {
    case 'critical':
      bg = const Color(0xFFFFE4E6); txt = const Color(0xFFE11D48);
      break;
    case 'warning':
      bg = const Color(0xFFFEF3C7); txt = const Color(0xFFD97706);
      break;
    default: // normal
      bg = const Color(0xFFDCFCE7); txt = const Color(0xFF16A34A);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      s.toLowerCase(),
      style: TextStyle(color: txt, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Patients", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                flex: 5,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(children: [
                    Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(
                      onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Search patients...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none, isDense: true,
                      ),
                    )),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
                    items: ["All Status", "Critical", "Warning", "Normal"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => selectedStatus = v!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.tune, color: Colors.grey.shade700, size: 18),
                  label: Text("Filters", style: TextStyle(color: Colors.grey.shade700)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(children: const [
                      Expanded(flex: 3, child: Text("Patient Name", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13))),
                      Expanded(flex: 1, child: Text("Age", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13))),
                      Expanded(flex: 2, child: Text("Status", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13))),
                      Expanded(flex: 2, child: Text("Condition", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13))),
                      Expanded(flex: 2, child: Text("Last Measurement", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13))),
                      Expanded(flex: 2, child: Text("Value", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13))),
                      Expanded(flex: 2, child: Text("Actions", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13))),
                    ]),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Expanded(child: _buildList()),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder(
      stream: _db.child('users').orderByChild('doctorId').equalTo(doctorId).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        }
        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return const Center(child: Text("No patients found", style: TextStyle(color: Colors.grey)));
        }
        Map users = snap.data!.snapshot.value as Map;
        var entries = users.entries.toList();

        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF5F5F5)),
          itemBuilder: (context, i) {
            String pid = entries[i].key.toString();
            Map p = Map.from(entries[i].value);
            String name = "${p['first_name'] ?? ''} ${p['last_name'] ?? ''}".trim();
            if (!name.toLowerCase().contains(searchQuery)) return const SizedBox.shrink();
            int age = int.tryParse(_age(p['birth_date']?.toString())) ?? 0;

            return StreamBuilder(
              stream: _db.child('measurements').child(pid).onValue,
              builder: (ctx, AsyncSnapshot<DatabaseEvent> mSnap) {
                String lastTime = "--", lastVal = "--", status = "Normal";
                if (mSnap.hasData && mSnap.data!.snapshot.value != null) {
                  Map meas = mSnap.data!.snapshot.value as Map;
                  var sorted = meas.entries.toList()..sort((a, b) {
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
                  var latest = sorted.first.value;
                  dynamic timeRaw = latest['timestamp'] ?? latest['date'];
                  lastTime = _ago(timeRaw);
                  lastVal = "${latest['value'] ?? '--'} mg/dL";
                  String type = latest['category']?.toString() ?? latest['type']?.toString() ?? "";
                  status = _getStatus(type, latest['value']);
                }
                if (selectedStatus != "All Status" && status != selectedStatus) return const SizedBox.shrink();

                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PatientProfilePage(patientId: pid, patientName: name))),
                  hoverColor: const Color(0xFFFAFAFF),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2D3142)))),
                      Expanded(flex: 1, child: Text(age > 0 ? "$age" : "--", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF2D3142)))),
                      Expanded(flex: 2, child: Center(child: _chip(status))),
                      Expanded(flex: 2, child: Text(p['condition']?.toString() ?? "Diabetes", textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)))),
                      Expanded(flex: 2, child: Text(lastTime, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey))),
                      Expanded(flex: 2, child: Text(lastVal, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)))),
                      Expanded(flex: 2, child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PatientProfilePage(patientId: pid, patientName: name))),
                          child: const Text("View Details >", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      )),
                    ]),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}