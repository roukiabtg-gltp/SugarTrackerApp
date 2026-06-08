import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../doctor_settings_notifier.dart';
import 'patient_profile_helpers.dart';
import 'patient_profile_widgets.dart';

// ── Meal Timing Options ────────────────────────────────────────────────

class _TimingOption {
  final String value;
  final String label;
  const _TimingOption(this.value, this.label);
}

List<_TimingOption> _timingOptions() => [
      _TimingOption("Fasting", t("Fasting", "صائم", "À jeun")),
      _TimingOption("Pre-meal", t("Pre-meal", "قبل الأكل", "Avant repas")),
      _TimingOption("Post-meal", t("Post-meal", "بعد الأكل", "Après repas")),
      _TimingOption("Random", t("Random", "عشوائي", "Aléatoire")),
    ];

// ── Tab Widget ─────────────────────────────────────────────────────────

class MeasurementsTab extends StatefulWidget {
  final String patientId;
  final Map? measurements;

  const MeasurementsTab({
    super.key,
    required this.patientId,
    required this.measurements,
  });

  @override
  State<MeasurementsTab> createState() => _MeasurementsTabState();
}

class _MeasurementsTabState extends State<MeasurementsTab> {
  final _db = FirebaseDatabase.instance.ref();
  final _ctrl = TextEditingController();
  String _type = "Glucose";
  String _timing = "Fasting";

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _deleteMeasurement(String measId) async {
    await _db
        .child('measurements')
        .child(widget.patientId)
        .child(measId)
        .remove();
  }

  void _showDialog({String? measId, Map? existingData}) {
    if (existingData != null) {
      _ctrl.text = existingData['value']?.toString() ?? "";
      _type = existingData['type']?.toString() ??
          existingData['category']?.toString() ??
          "Glucose";
      // إذا type مش من القائمة → Glucose
      if (!["Glucose","Blood Pressure","Heart Rate","Weight","Temperature"]
          .contains(_type)) {
        _type = "Glucose";
      }
      _timing = existingData['timing']?.toString() ?? "Fasting";
    } else {
      _ctrl.clear();
      _type = "Glucose";
      _timing = "Fasting";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(measId == null
            ? t('Add Measurement', 'إضافة قياس', 'Ajouter une mesure')
            : t('Edit Measurement', 'تعديل القياس', 'Modifier la mesure')),
        content: StatefulBuilder(
          builder: (_, dialogState) {
            final bool isGlucose = _type == "Glucose";
            return SizedBox(
              width: 350,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Measurement Type ──────────────────────────────
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: InputDecoration(
                        labelText: t('Measurement Type', 'نوع القياس',
                            'Type de mesure'),
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
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e == 'Glucose'
                                  ? t('Glucose', 'الجلوكوز', 'Glycémie')
                                  : e == 'Blood Pressure'
                                      ? t('Blood Pressure', 'ضغط الدم',
                                          'Pression artérielle')
                                      : e == 'Heart Rate'
                                          ? t('Heart Rate',
                                              'معدل ضربات القلب',
                                              'Fréquence cardiaque')
                                          : e == 'Weight'
                                              ? t('Weight', 'الوزن', 'Poids')
                                              : t('Temperature', 'درجة الحرارة',
                                                  'Température'))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          dialogState(() {
                            _type = v;
                            if (v != "Glucose") _timing = "Fasting";
                          });
                        }
                      },
                    ),

                    // ── Meal Timing ───────────────────────────────────
                    if (isGlucose) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _timing,
                        decoration: InputDecoration(
                          labelText: t('Measurement Timing', 'توقيت القياس',
                              'Moment de mesure'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _timingOptions()
                            .map((o) => DropdownMenuItem(
                                value: o.value, child: Text(o.label)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) dialogState(() => _timing = v);
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Value ─────────────────────────────────────────
                    TextField(
                      controller: _ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: t('Value', 'القيمة', 'Valeur'),
                        suffixText: _type == "Glucose"
                            ? "g/L"
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

                    // ── Reference info ────────────────────────────────
                    if (isGlucose) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _refRow("🟢",
                                t("Normal (fasting)", "طبيعي (صائم)",
                                    "Normal (à jeun)"),
                                "0.70 – 1.00 g/L"),
                            _refRow("🟢",
                                t("Normal (post-meal)", "طبيعي (بعد الأكل)",
                                    "Normal (après repas)"),
                                "< 1.40 g/L"),
                            _refRow("🟡",
                                t("Borderline high", "مرتفع نسبياً",
                                    "Limite haute"),
                                "1.40 – 1.80 g/L"),
                            _refRow("🔴",
                                t("Hypoglycemia", "نقص السكر",
                                    "Hypoglycémie"),
                                "< 0.70 g/L"),
                            _refRow("🔴",
                                t("Hyperglycemia", "ارتفاع السكر",
                                    "Hyperglycémie"),
                                "> 1.80 g/L"),
                          ],
                        ),
                      ),
                    ],
                  ]),
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('Cancel', 'إلغاء', 'Annuler'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () async {
              if (_ctrl.text.trim().isEmpty) return;
              final unit = {
                    "Glucose": "g/L",
                    "Blood Pressure": "mmHg",
                    "Heart Rate": "bpm",
                    "Weight": "kg",
                    "Temperature": "°C",
                  }[_type] ??
                  "g/L";

              final String categoryValue =
                  _type == "Glucose" ? _timing : _type;

              final data = {
                'value': _ctrl.text.trim(),
                'type': _type,
                'category': categoryValue,
                'unit': unit,
                'timing': _type == "Glucose" ? _timing : null,
                'doctor_added': true,
                if (measId == null) 'timestamp': ServerValue.timestamp,
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
            child: Text(t('Save', 'حفظ', 'Enregistrer'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _refRow(String icon, String label, String range) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF4A5568)))),
        Text(range,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry> list = widget.measurements != null
        ? filteredMeasurements(widget.measurements!)
        : [];

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    t('Recent Measurements', 'أحدث القياسات',
                        'Dernières mesures'),
                    style: const TextStyle(
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
                  child: Text(
                      t('Add Measurement', 'إضافة قياس',
                          'Ajouter une mesure'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                ),
              ]),
          const SizedBox(height: 20),
          if (list.isEmpty)
            Center(
                child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                        t('No measurements yet',
                            'لا توجد قياسات حتى الآن',
                            'Aucune mesure pour le moment'),
                        style: const TextStyle(color: Colors.grey))))
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Table(
                border: TableBorder(
                    horizontalInside:
                        BorderSide(color: Colors.grey.shade100)),
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(1.5),
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
                      t('Date & Time', 'التاريخ والوقت', 'Date et heure'),
                      t('Type', 'النوع', 'Type'),
                      t('Value', 'القيمة', 'Valeur'),
                      t('Status', 'الحالة', 'Statut'),
                      t('Source', 'المصدر', 'Source'),
                      t('Actions', 'الإجراءات', 'Actions'),
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
                    final v = entry.value;

                    String category =
                        (v['category']?.toString() ?? "").trim();
                    String baseType =
                        (v['type']?.toString() ?? "").trim();

                    // ── KEY FIX ──────────────────────────────────────
                    // نمرر category للـ getStatus باش يعرف التوقيت
                    // لكن إذا category = "Glucose" نمرر baseType
                    // وإذا فاضيين نمرر string فاضي (glucose افتراضي)
                    String statusKey = category.trim().isNotEmpty
                       ? category.trim()
                       : baseType.trim();

                    String status = getStatus(statusKey, v['value']);
                    print("TYPE=$statusKey VALUE=${v['value']} STATUS=$status");
                    // ─────────────────────────────────────────────────

                    bool isDoctor = v['doctor_added'] == true;
                    dynamic timeRaw = v['timestamp'] ?? v['date'];
                    String typeLabel =
                        _typeDisplayLabel(category, baseType);
                    String unit = v['unit']?.toString() ?? 'g/L';

                    return TableRow(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Text(fmtDate(timeRaw),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4A5568))),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Text(typeLabel,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2D3142))),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Text(
                            "${v['value'] ?? '--'} $unit",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF2D3142))),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Center(child: buildStatusChip(status)),
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                              isDoctor
                                  ? t('Doctor', 'الطبيب', 'Docteur')
                                  : t('Device', 'الجهاز', 'Appareil'),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: Colors.blue),
                              onPressed: () => _showDialog(
                                  measId: entry.key,
                                  existingData: Map.from(v)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
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

  String _typeDisplayLabel(String category, String baseType) {
    if (baseType == "Glucose" || baseType.isEmpty) {
      switch (category) {
        case "Fasting":
          return t("Glucose (Fasting)", "جلوكوز (صائم)",
              "Glycémie (à jeun)");
        case "Pre-meal":
          return t("Glucose (Pre-meal)", "جلوكوز (قبل الأكل)",
              "Glycémie (avant repas)");
        case "Post-meal":
          return t("Glucose (Post-meal)", "جلوكوز (بعد الأكل)",
              "Glycémie (après repas)");
        case "Random":
          return t("Glucose (Random)", "جلوكوز (عشوائي)",
              "Glycémie (aléatoire)");
        default:
          if (category.isNotEmpty) return category;
          return t("Glucose", "الجلوكوز", "Glycémie");
      }
    }
    return baseType.isNotEmpty ? baseType : category;
  }
}