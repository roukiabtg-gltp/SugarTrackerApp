import 'package:flutter/material.dart';
import '../doctor_settings_notifier.dart';

// ── Status Chip ────────────────────────────────────────────────────────

Widget buildStatusChip(String s) {
  final colors = {
    "critical": [const Color(0xFFFFE4E6), const Color(0xFFE11D48)],
    "warning": [const Color(0xFFFEF3C7), const Color(0xFFD97706)],
    "normal": [const Color(0xFFDCFCE7), const Color(0xFF16A34A)],
  };
  final c = colors[s.toLowerCase()] ?? colors["normal"]!;
  final label = s == "Critical"
      ? t('Critical', 'حرج', 'Critique')
      : s == "Warning"
          ? t('Warning', 'تحذير', 'Avertissement')
          : t('Normal', 'طبيعي', 'Normal');
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration:
        BoxDecoration(color: c[0], borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style:
            TextStyle(color: c[1], fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

// ── Alert Banner ───────────────────────────────────────────────────────

Widget buildAlertBanner(String st, List<Color> sc, String alertLabel,
    String alertVal, String alertTime) {
  final bool isCritical = st == "Critical";
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: sc[0],
      borderRadius: BorderRadius.circular(10),
      border: Border(left: BorderSide(color: sc[1], width: 4)),
    ),
    child: Row(children: [
      Icon(
        isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
        color: sc[1],
        size: 24,
      ),
      const SizedBox(width: 12),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
                "${isCritical ? "⚠ Critical Alert" : "⚡ Warning"}: $alertLabel",
                style: TextStyle(
                    color: sc[1],
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(
                "Latest: $alertVal  •  $alertTime  •  ${isCritical ? "Immediate review required." : "Monitor closely."}",
                style: TextStyle(color: sc[1], fontSize: 12)),
          ])),
    ]),
  );
}

// ── Header Card ────────────────────────────────────────────────────────

Widget buildHeaderCard({
  required String name,
  required String age,
  required String blood,
  required String email,
  required String phone,
  required String address,
  required String? photo,
  required String initials,
  required VoidCallback onEditProfile,
}) {
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
      // ── Avatar ──
      CircleAvatar(
        radius: 38,
        backgroundColor: const Color(0xFFEEF2FF),
        backgroundImage:
            (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
        child: (photo == null || photo.isEmpty)
            ? Text(initials,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5)))
            : null,
      ),
      const SizedBox(width: 20),

      // ── Info ──
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C))),
              const SizedBox(height: 8),
              Row(children: [
                Text("${t('Age', 'العمر', 'Âge')}: $age",
                    style:
                        const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text("•",
                        style: TextStyle(color: Colors.blueGrey))),
                Text("${t('Blood', 'الدم', 'Sang')}: $blood",
                    style:
                        const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(phone,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 20),
                const Icon(Icons.mail_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Flexible(
                    child: Text(email,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Flexible(
                    child: Text(address,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13))),
              ]),
            ]),
      ),

      // ── Edit Profile Button Only ──
      OutlinedButton(
        onPressed: onEditProfile,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
        child: Text(
            t('Edit Profile', 'تعديل الملف الشخصي', 'Modifier le profil'),
            style: const TextStyle(color: Color(0xFF2D3142), fontSize: 13)),
      ),
    ]),
  );
}
