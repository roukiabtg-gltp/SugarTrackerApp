import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../doctor_settings_notifier.dart';

// ── Age Calculator ─────────────────────────────────────────────────────

String calcAge(String? s) {
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

// ── Date Formatter ─────────────────────────────────────────────────────

String fmtDate(dynamic raw) {
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

// ── Time Ago ───────────────────────────────────────────────────────────

String timeAgo(dynamic raw) {
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
      return t('${d.inMinutes} min ago', 'قبل ${d.inMinutes} دقيقة',
          'il y a ${d.inMinutes} min');
    if (d.inHours < 24)
      return t('${d.inHours} hr ago', 'قبل ${d.inHours} ساعة',
          'il y a ${d.inHours} h');
    return t('${d.inDays} day(s) ago', 'قبل ${d.inDays} يوم',
        'il y a ${d.inDays} j');
  } catch (_) {
    return "--";
  }
}

// ── Status Helpers ─────────────────────────────────────────────────────

String getStatus(String type, dynamic val, {String? mealContext}) {
  final raw = val?.toString().trim().replaceAll(',', '.') ?? "";
  final double? v = double.tryParse(raw);

  if (v == null) return "Normal";

  final tp = type.toLowerCase().trim();

  // Blood Pressure
  if (tp.contains("pressure") || tp.contains("ضغط")) {
    if (v > 160) return "Critical";
    if (v > 130) return "Warning";
    return "Normal";
  }

  // Glucose
  if (v < 0.70) return "Critical";
  if (v > 1.80) return "Critical";

  if (v >= 1.40) return "Warning";

  // Fasting / Pre-meal
  if (tp.contains("fasting") ||
      tp.contains("pre-meal") ||
      tp.contains("pre meal") ||
      tp.contains("avant") ||
      tp.contains("صائم") ||
      tp.contains("قبل")) {
    if (v > 1.00) return "Warning";
  }

  return "Normal";
}

String getStatusLabel(String type, dynamic val, {String? mealContext}) {
  final raw = val?.toString().trim().replaceAll(',', '.') ?? "";
  final double? v = double.tryParse(raw);

  if (v == null) return "Glucose Alert";

  if (v < 0.70) {
    return "Hypoglycemia";
  }

  if (v > 1.80) {
    return "Hyperglycemia";
  }

  if (v >= 1.40) {
    return "Borderline High Glucose";
  }

  return "Normal Glucose";
}
String worstStatus(Map? m) {
  if (m == null || m.isEmpty) return "Normal";

  String result = "Normal";

  for (var e in m.values) {
    if (e is! Map) continue;

    String type =
        (e['category']?.toString() ??
                e['type']?.toString() ??
                "")
            .trim();

    String status = getStatus(type, e['value']);

    if (status == "Critical") {
      return "Critical";
    }

    if (status == "Warning") {
      result = "Warning";
    }
  }

  return result;
}
List<Color> statusColors(String s) {
  return {
    "Critical": [const Color(0xFFFDE8E8), const Color(0xFFDC2626)],
    "Warning":  [const Color(0xFFFFF9C4), const Color(0xFFD4A017)],
    "Normal":   [const Color(0xFFDFF5EC), const Color(0xFF4CAF81)],
  }[s] ?? [const Color(0xFFDFF5EC), const Color(0xFF4CAF81)];
}

// ── Sort / Filter Measurements ─────────────────────────────────────────

List<MapEntry> sortedMeasurements(Map m) {
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

List<MapEntry> filteredMeasurements(Map m) {
  return sortedMeasurements(m).where((e) {
    String type =
        (e.value['type'] ?? e.value['category'] ?? "").toString().toLowerCase();
    return !type.contains("زيارة");
  }).toList();
}