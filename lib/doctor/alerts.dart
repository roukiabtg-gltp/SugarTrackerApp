import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertsPage extends StatefulWidget {
  final String doctorId;
  const AlertsPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all'; // all / unresolved / resolved

  // معايير تصنيف مستويات السكر الافتراضية
  static const double _glucoseLowCritical = 0.54;
  static const double _glucoseLowWarning = 0.70;
  static const double _glucoseHighWarning = 1.80;
  static const double _glucoseHighCritical = 2.50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── دالة تصنيف مستوى السكر لتحديد شكل التنبيه ───────────────────────────────
 _GlucoseLevel _classifyGlucose(double value) {
    if (value < _glucoseLowCritical) {
      return const _GlucoseLevel(
        direction: 'LOW',
        severity: 'critical',
        color: Color(0xFFC62828),
        bg: Color(0xFFFCEBEB),
        label: 'Severe Hypoglycemia',
        labelAr: 'نقص سكر حاد',
      );
    } else if (value < _glucoseLowWarning) {
      return const _GlucoseLevel(
        direction: 'LOW',
        severity: 'warning',
        color: Color(0xFFEF6C00),
        bg: Color(0xFFFFF3E0),
        label: 'Hypoglycemia',
        labelAr: 'نقص في السكر',
      );
    } else if (value > _glucoseHighCritical) {
      return const _GlucoseLevel(
        direction: 'HIGH',
        severity: 'critical',
        color: Color(0xFFB71C1C),
        bg: Color(0xFFFDE8E8),
        label: 'Severe Hyperglycemia',
        labelAr: 'ارتفاع سكر حاد',
      );
    } else if (value > _glucoseHighWarning) {
      return const _GlucoseLevel(
        direction: 'HIGH',
        severity: 'warning',
        color: Color(0xFFE65100),
        bg: Color(0xFFFFF3E0),
        label: 'Hyperglycemia',
        labelAr: 'ارتفاع في السكر',
      );
    } else {
      // 💡 التعديل هنا: نغير الـ severity من 'normal' إلى 'warning' لكي يحتفظ بها الـ StreamBuilder ولا يحذفها عند إعادة بناء الصفحة
      return const _GlucoseLevel(
        direction: 'NORMAL',
        severity: 'warning', // 👈 تغيير هذه إلى warning يضمن بقاء القراءة في القائمة دائماً
        color: Color(0xFF0288D1),
        bg: Color(0xFFE1F5FE),
        label: 'Glucose Normale / Alerte',
        labelAr: 'قياس طبيعي / تحديث',
      );
    }
  }

  double? _parseGlucose(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  // دالة لتغيير حالة الإنذار (محلول / غير محلول) في الـ Realtime Database
  Future<void> _toggleResolve(String path, String key, bool currentStatus) async {
    final ref = FirebaseDatabase.instance.ref("$path/$key");
    await ref.update({'resolved': !currentStatus});
  }

  @override
  Widget build(BuildContext context) {
    final doctorAlertsRef = FirebaseDatabase.instance.ref("doctors/${widget.doctorId}/alerts");
    final doctorEmergenciesRef = FirebaseDatabase.instance.ref("doctors/${widget.doctorId}/emergencies");

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gestion des Alertes & SOS', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber_rounded), text: "Alertes Glycémie"),
            Tab(icon: Icon(Icons.sos_rounded), text: "Appels SOS الطوارئ"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 📊 القسم الأول: إنذارات قياسات السكر
          _buildAlertsTab(doctorAlertsRef),
          
          // 🚨 القسم الثاني: استغاثات الـ SOS المباشرة
          _buildEmergenciesTab(doctorEmergenciesRef),
        ],
      ),
    );
  }

// ─── بناء واجهة إنذارات السكر (مصحح ومثبت للبيانات) ──────────────────────────────────────────
  Widget _buildAlertsTab(DatabaseReference ref) {
    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final dataSnapshot = snapshot.data?.snapshot;
        if (dataSnapshot == null || dataSnapshot.value == null) {
          return const Center(child: Text('Aucune alerte enregistrée', style: TextStyle(color: Colors.grey, fontSize: 16)));
        }

        final rawAlerts = Map<dynamic, dynamic>.from(dataSnapshot.value as Map);
        List<_AlertEntry> entries = [];

        for (var e in rawAlerts.entries) {
          final data = Map<String, dynamic>.from(e.value);
          final glucose = _parseGlucose(data['glucose']);
          final level = _classifyGlucose(glucose ?? 1.0); 

          final isResolved = data['resolved'] == true;

          // تطبيق الفلترة (الكل / تمت معالجته / لم تتم معالجته) فقط حسب زر الصح
          if (_filter == 'unresolved' && isResolved) continue;
          if (_filter == 'resolved' && !isResolved) continue;

          // 💡 حذفنا شرط الـ (continue) القديم الذي كان يتخلص من الحالات الطبيعية عند إعادة البناء
          entries.add(_AlertEntry(
            key: e.key.toString(),
            data: data,
            path: "doctors/${widget.doctorId}/alerts",
            // نعتبر القيمة حرجة فقط إذا كانت كذلك في التصنيف، وغير ذلك هي تنبيه عادي ليتم الاحتفاظ به بجميع الأحوال
            type: level.severity == 'critical' ? 'CRITICAL' : 'WARNING', 
            level: level,
          ));
        }

        // ترتيب الإنذارات بحيث تظهر الأحدث في الأعلى دائماً
        entries.sort((a, b) {
          final ta = a.data['timestamp'] ?? 0;
          final tb = b.data['timestamp'] ?? 0;
          return tb.compareTo(ta);
        });

        // حساب العداد بناءً على التنبيهات الحقيقية غير المحلولة فقط
        int criticalCount = entries.where((e) => e.level.severity == 'critical' && bIsUnresolved(e.data)).length;

        return Column(
          children: [
            // شريط الفلاتر والعداد العلوي
            _buildFilterHeader(criticalCount),
            
            // قائمة الإنذارات الثابتة
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('Aucune alerte correspondante'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      itemBuilder: (context, idx) => _buildAlertCard(entries[idx]),
                    ),
            ),
          ],
        );
      },
    );
  }

  bool bIsUnresolved(Map data) => data['resolved'] != true;

  Widget _buildFilterHeader(int criticalCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$criticalCount Non résolu(s)', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          DropdownButton<String>(
            value: _filter,
            underline: const SizedBox(),
            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous les alertes (الكل)')),
              DropdownMenuItem(value: 'unresolved', child: Text('Non résolus (غير معالجة)')),
              DropdownMenuItem(value: 'resolved', child: Text('Résolus (المعالجة)')),
            ],
            onChanged: (v) => setState(() => _filter = v!),
          )
        ],
      ),
    );
  }

  Widget _buildAlertCard(_AlertEntry entry) {
    final data = entry.data;
    final isResolved = data['resolved'] == true;
    final timeStr = data['timestamp'] != null
        ? DateFormat('dd/MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(data['timestamp']))
        : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isResolved ? Colors.grey.withOpacity(0.2) : entry.level.color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // عمود يساري ملون يعبر عن خطورة الإنذار
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(color: isResolved ? Colors.grey : entry.level.color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 16),
            
            // تفاصيل الإنذار والمريض
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data['patientName'] ?? 'Patient inconnu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                      const Spacer(),
                      Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: isResolved ? Colors.grey[200] : entry.level.bg, borderRadius: BorderRadius.circular(6)),
                        child: Text("${entry.level.labelAr} : ${data['glucose']} g/L", style: TextStyle(color: isResolved ? Colors.grey[700] : entry.level.color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // زر التبديل لحالة الإنذار (تمت المراجعة)
            IconButton(
              icon: Icon(isResolved ? Icons.check_circle : Icons.radio_button_unchecked, color: isResolved ? Colors.green : entry.level.color),
              onPressed: () => _toggleResolve(entry.path, entry.key, isResolved),
            )
          ],
        ),
      ),
    );
  }

  // ─── بناء واجهة استغاثات الـ SOS ────────────────────────────────────────────
  Widget _buildEmergenciesTab(DatabaseReference ref) {
    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final dataSnapshot = snapshot.data?.snapshot;
        if (dataSnapshot == null || dataSnapshot.value == null) {
          return const Center(child: Text('Aucun appel SOS actif', style: TextStyle(color: Colors.grey, fontSize: 16)));
        }

        final rawEmergencies = Map<dynamic, dynamic>.from(dataSnapshot.value as Map);
        List<Map<String, dynamic>> emergenciesList = [];

        rawEmergencies.forEach((k, v) {
          emergenciesList.add({'key': k.toString(), ...Map<String, dynamic>.from(v as Map)});
        });

        // ترتيب الاستغاثات حسب الأحدث
        emergenciesList.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: emergenciesList.length,
          itemBuilder: (context, idx) {
            final item = emergenciesList[idx];
            final isResolved = item['resolved'] == true;
            final phone = item['patientPhone'] ?? '';

            return Card(
              color: isResolved ? Colors.white : const Color(0xFFFEE2E2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _SosPulseIcon(resolved: isResolved),
                title: Text(item['patientName'] ?? 'Appel SOS الطوارئ', style: TextStyle(fontWeight: FontWeight.bold, color: isResolved ? Colors.black87 : const Color(0xFF991B1B))),
                subtitle: Text("Contact: $phone"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phone.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.blue),
                        onPressed: () => launchUrl(Uri.parse("tel:$phone")),
                      ),
                    IconButton(
                      icon: Icon(isResolved ? Icons.check_circle : Icons.check_circle_outline, color: isResolved ? Colors.green : Colors.red),
                      onPressed: () => _toggleResolve("doctors/${widget.doctorId}/emergencies", item['key'], isResolved),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── كلاسات مساعدة لهيكلة البيانات والـ Widgets الفرعية ──────────────────────────────

class _AlertEntry {
  final String key;
  final Map<String, dynamic> data;
  final String path;
  final String type;
  final _GlucoseLevel level;

  _AlertEntry({required this.key, required this.data, required this.path, required this.type, required this.level});
}

class _GlucoseLevel {
  final String direction;
  final String severity;
  final Color color;
  final Color bg;
  final String label;
  final String labelAr;

  const _GlucoseLevel({required this.direction, required this.severity, required this.color, required this.bg, required this.label, required this.labelAr});
}

class _SosPulseIcon extends StatefulWidget {
  final bool resolved;
  const _SosPulseIcon({required this.resolved});

  @override
  State<_SosPulseIcon> createState() => _SosPulseIconState();
}

class _SosPulseIconState extends State<_SosPulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resolved) {
      return const Icon(Icons.check_circle_outline, size: 24, color: Colors.grey);
    }
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.2), shape: BoxShape.circle),
        child: const Icon(Icons.sos_rounded, size: 24, color: Color(0xFFD32F2F)),
      ),
    );
  }
}