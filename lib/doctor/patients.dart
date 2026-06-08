import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_profile_pageee.dart';
import '../doctor_settings_notifier.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});
  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final _db = FirebaseDatabase.instance.ref();
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;
  String searchQuery = "", selectedStatus = "All Status";

  // ── Age ───────────────────────────────────────────────────────────────
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

  // ── Time Ago ──────────────────────────────────────────────────────────
  String _ago(dynamic raw) {
    if (raw == null) return "--";
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      Duration d = DateTime.now().difference(dt);
      if (d.inMinutes < 1) return t('Just now', 'الآن', 'À l\'instant');
      if (d.inMinutes < 60)
        return t('${d.inMinutes} min ago', 'قبل ${d.inMinutes} دق',
            'il y a ${d.inMinutes} min');
      if (d.inHours < 24)
        return t('${d.inHours} hr ago', 'قبل ${d.inHours} س',
            'il y a ${d.inHours} h');
      return t('${d.inDays} day(s) ago', 'قبل ${d.inDays} يوم',
          'il y a ${d.inDays} j');
    } catch (_) {
      return "--";
    }
  }

  // ── Status Helpers ────────────────────────────────────────────────────
  bool _isFasting(String tp) =>
      tp.contains("fasting") ||
      tp.contains("صائم") ||
      tp.contains("à jeun") ||
      tp.contains("jeun");

  bool _isPreMeal(String tp) =>
      tp.contains("pre-meal") ||
      tp.contains("pre meal") ||
      tp.contains("قبل الأكل") ||
      tp.contains("avant");

  bool _isPostMeal(String tp) =>
      tp.contains("post-meal") ||
      tp.contains("post meal") ||
      tp.contains("بعد الأكل") ||
      tp.contains("après") ||
      tp.contains("apres");

  bool _isGlucose(String tp) =>
      tp.isEmpty || // ← KEY FIX: no category = assume glucose
      tp.contains("glucose") ||
      tp.contains("سكر") ||
      tp.contains("glyc") ||
      tp.contains("random") ||
      tp.contains("عشوائي") ||
      _isFasting(tp) ||
      _isPreMeal(tp) ||
      _isPostMeal(tp);

  String _glucoseStatus(String tp, double v) {
    // Hypo / Hyper — common to all timings
    if (v < 0.70) return "Critical"; // Hypoglycemia
    if (v > 1.80) return "Critical"; // Hyperglycemia
    if (v >= 1.40) return "Warning"; // Borderline high

    // Below 1.40 — depends on timing
    if (_isFasting(tp) || _isPreMeal(tp)) {
      // Fasting normal: 0.70–1.00
      if (v > 1.00) return "Warning";
      return "Normal";
    }

    // Post-meal, unknown, or empty category → normal < 1.40
    return "Normal";
  }

  String _getStatus(String type, dynamic val) {
    // Safely parse value — trim spaces and handle comma decimal separator
    String raw = val?.toString().trim().replaceAll(',', '.') ?? "";
    double? v = double.tryParse(raw);
    if (v == null) return "Normal";

    String tp = type.toLowerCase().trim();

    if (_isGlucose(tp)) return _glucoseStatus(tp, v);

    if (tp.contains("pressure") || tp.contains("ضغط")) {
      if (v > 160) return "Critical";
      if (v > 130) return "Warning";
      return "Normal";
    }

    // Unknown type with a value → treat as glucose (device default)
    return _glucoseStatus(tp, v);
  }

  // ── Status Chip ───────────────────────────────────────────────────────
  Widget _chip(String status) {
    final Map<String, Map<String, Color>> theme = {
      "Critical": {
        "bg": const Color(0xFFFFE4E6),
        "fg": const Color(0xFFE11D48),
      },
      "Warning": {
        "bg": const Color(0xFFFEF9C3),
        "fg": const Color(0xFFCA8A04),
      },
      "Normal": {
        "bg": const Color(0xFFDCFCE7),
        "fg": const Color(0xFF16A34A),
      },
    };
    final colors = theme[status] ?? theme["Normal"]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: colors["bg"],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toLowerCase(),
        style: TextStyle(
          color: colors["fg"],
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── Status filter label ───────────────────────────────────────────────
  String _statusLabel(String value) {
    switch (value) {
      case 'All Status':
        return t('All Status', 'كل الحالات', 'Tous les statuts');
      case 'Critical':
        return t('Critical', 'حرج', 'Critique');
      case 'Warning':
        return t('Warning', 'تحذير', 'Avertissement');
      case 'Normal':
        return t('Normal', 'طبيعي', 'Normal');
      default:
        return value;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('Patients', 'المرضى', 'Patients'),
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 24),

            // ── Search + Filters ─────────────────────────────────────────
            Row(children: [
              Expanded(
                flex: 5,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.search,
                        color: Colors.grey.shade400, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => searchQuery = v.toLowerCase()),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: t(
                              'Search patients...',
                              'ابحث عن المرضى...',
                              'Rechercher des patients...'),
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF2D3142)),
                    items: ["All Status", "Critical", "Warning", "Normal"]
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(_statusLabel(e))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedStatus = v!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.tune,
                      color: Colors.grey.shade700, size: 18),
                  label: Text(
                    t('Filters', 'الفلاتر', 'Filtres'),
                    style: TextStyle(
                        color: Colors.grey.shade700, fontSize: 14),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Table card ───────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(children: [
                      _hCell(
                          t('Patient Name', 'اسم المريض', 'Nom du patient'),
                          flex: 3,
                          align: TextAlign.left),
                      _hCell(t('Age', 'العمر', 'Âge'),
                          flex: 1, align: TextAlign.center),
                      _hCell(t('Status', 'الحالة', 'Statut'),
                          flex: 2, align: TextAlign.center),
                      _hCell(
                          t('Condition', 'الحالة الصحية', 'Condition'),
                          flex: 2,
                          align: TextAlign.center),
                      _hCell(
                          t('Last Measurement', 'آخر قياس',
                              'Dernière mesure'),
                          flex: 2,
                          align: TextAlign.center),
                      _hCell(t('Value', 'القيمة', 'Valeur'),
                          flex: 2, align: TextAlign.center),
                      _hCell(t('Actions', 'إجراءات', 'Actions'),
                          flex: 2, align: TextAlign.right),
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

  Widget _hCell(String label,
      {required int flex, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(label,
          textAlign: align,
          style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 13)),
    );
  }

  // ── Patient list ──────────────────────────────────────────────────────
  Widget _buildList() {
    return StreamBuilder(
      stream: _db
          .child('users')
          .orderByChild('doctorId')
          .equalTo(doctorId)
          .onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6)));
        }
        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return Center(
              child: Text(
                  t('No patients found', 'لا يوجد مرضى',
                      'Aucun patient trouvé'),
                  style: const TextStyle(color: Colors.grey)));
        }

        Map users = snap.data!.snapshot.value as Map;
        var entries = users.entries.toList();

        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
          itemBuilder: (context, i) {
            String pid = entries[i].key.toString();
            Map p = Map.from(entries[i].value);
            String name =
                "${p['first_name'] ?? ''} ${p['last_name'] ?? ''}"
                    .trim();
            if (!name.toLowerCase().contains(searchQuery)) {
              return const SizedBox.shrink();
            }
            int age =
                int.tryParse(_age(p['birth_date']?.toString())) ?? 0;

            return StreamBuilder(
              stream:
                  _db.child('measurements').child(pid).onValue,
              builder: (ctx, AsyncSnapshot<DatabaseEvent> mSnap) {
                String lastTime = "--",
                    lastVal = "--",
                    status = "Normal";

                if (mSnap.hasData &&
                    mSnap.data!.snapshot.value != null) {
                  Map meas =
                      mSnap.data!.snapshot.value as Map;

                  // Sort descending by timestamp
                  var sorted = meas.entries.toList()
                    ..sort((a, b) {
                      int getMs(dynamic raw) {
                        if (raw == null) return 0;
                        if (raw is int) return raw;
                        int? v = int.tryParse(raw.toString());
                        if (v != null) return v;
                        try {
                          return DateTime.parse(raw.toString())
                              .millisecondsSinceEpoch;
                        } catch (_) {
                          return 0;
                        }
                      }

                      return getMs(b.value['timestamp'] ??
                              b.value['date'])
                          .compareTo(getMs(a.value['timestamp'] ??
                              a.value['date']));
                    });

                  // Skip زيارة entries
                  final realMeas = sorted.where((e) {
                    String tp = (e.value['type'] ??
                            e.value['category'] ??
                            "")
                        .toString()
                        .toLowerCase();
                    return !tp.contains("زيارة");
                  }).toList();

                  if (realMeas.isNotEmpty) {
                    var latest = realMeas.first.value;
                    dynamic timeRaw =
                        latest['timestamp'] ?? latest['date'];
                    lastTime = _ago(timeRaw);

                    String unit =
                        latest['unit']?.toString() ?? 'g/L';
                    lastVal =
                        "${latest['value'] ?? '--'} $unit";

                    // ← category أولاً، ثم type، ثم string فاضي
                    String type =
                        (latest['category']?.toString() ?? "")
                            .trim();
                    if (type.isEmpty) {
                      type =
                          (latest['type']?.toString() ?? "")
                              .trim();
                    }

                    status = _getStatus(type, latest['value']);
                  }
                }

                if (selectedStatus != "All Status" &&
                    status != selectedStatus) {
                  return const SizedBox.shrink();
                }

                return InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PatientProfilePage(
                              patientId: pid,
                              patientName: name))),
                  hoverColor: const Color(0xFFFAFAFF),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    child: Row(children: [
                      Expanded(
                        flex: 3,
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF2D3142))),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          age > 0 ? "$age" : "--",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF2D3142)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(child: _chip(status)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p['condition']?.toString() ?? "Diabetes",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2D3142)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          lastTime,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          lastVal,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PatientProfilePage(
                                        patientId: pid,
                                        patientName: name))),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero),
                            child: Text(
                              t('View Details >', 'عرض التفاصيل >',
                                  'Voir les détails >'),
                              style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ),
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