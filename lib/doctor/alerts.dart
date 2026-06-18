import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class AlertsPage extends StatefulWidget {
  final String doctorId;
  const AlertsPage({Key? key, required this.doctorId}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Les refs sont créées une seule fois dans initState
  // et non dans build() qui est appelé à chaque rendu
  late final DatabaseReference _alertsRef;
  late final DatabaseReference _emergenciesRef;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _alertsRef     = FirebaseDatabase.instance.ref("doctors/${widget.doctorId}/alerts");
    _emergenciesRef = FirebaseDatabase.instance.ref("doctors/${widget.doctorId}/emergencies");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gestion des Alertes & SOS',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
            Tab(icon: Icon(Icons.sos_rounded), text: "Appels SOS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AlertsTabKeepAlive(doctorId: widget.doctorId, ref: _alertsRef),
          _EmergenciesTabKeepAlive(doctorId: widget.doctorId, ref: _emergenciesRef),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Onglet des alertes glycémie
// ════════════════════════════════════════════════════════════════════════
class _AlertsTabKeepAlive extends StatefulWidget {
  final String doctorId;
  final DatabaseReference ref;
  const _AlertsTabKeepAlive({required this.doctorId, required this.ref});

  @override
  State<_AlertsTabKeepAlive> createState() => _AlertsTabKeepAliveState();
}

class _AlertsTabKeepAliveState extends State<_AlertsTabKeepAlive>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  String _filter = 'all';
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _prevCriticalCount = -1;

  late final Stream<DatabaseEvent> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.ref.onValue;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  static const double _lowCritical  = 0.54;
  static const double _lowWarning   = 0.70;
  static const double _highWarning  = 1.80;
  static const double _highCritical = 2.50;

  _GlucoseLevel _classify(double v) {
    if (v < _lowCritical) return const _GlucoseLevel(severity: 'critical',
      color: Color(0xFFC62828), bg: Color(0xFFFCEBEB), label: 'Hypoglycémie sévère');
    if (v < _lowWarning)  return const _GlucoseLevel(severity: 'warning',
      color: Color(0xFFEF6C00), bg: Color(0xFFFFF3E0), label: 'Glycémie basse');
    if (v > _highCritical) return const _GlucoseLevel(severity: 'critical',
      color: Color(0xFFB71C1C), bg: Color(0xFFFDE8E8), label: 'Hyperglycémie sévère');
    if (v > _highWarning)  return const _GlucoseLevel(severity: 'warning',
      color: Color(0xFFE65100), bg: Color(0xFFFFF3E0), label: 'Glycémie élevée');
    return const _GlucoseLevel(severity: 'normal',
      color: Color(0xFF0288D1), bg: Color(0xFFE1F5FE), label: 'Mesure normale');
  }

  double _parseG(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 1.0;
  }

  Future<void> _toggleResolve(String path, String key, bool cur) async {
    await FirebaseDatabase.instance.ref("$path/$key").update({'resolved': !cur});
  }

  Future<void> _notifyIfNew(int newCount) async {
    if (_prevCriticalCount >= 0 && newCount > _prevCriticalCount) {
      try { await _audioPlayer.play(AssetSource('sounds/alert.mp3')); } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
        backgroundColor: const Color(0xFFB71C1C),
        leading: const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
        content: Text('🚨 Nouvelle alerte ! ${newCount - _prevCriticalCount} cas critique(s)',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [TextButton(
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          child: const Text('Masquer', style: TextStyle(color: Colors.white70)),
        )],
      ));
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      });
    }
    _prevCriticalCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // requis avec keepAlive

    return StreamBuilder<DatabaseEvent>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final val = snapshot.data?.snapshot.value;
        if (val == null) {
          return const Center(child: Text('Aucune alerte enregistrée',
              style: TextStyle(color: Colors.grey, fontSize: 16)));
        }

        final raw = Map<dynamic, dynamic>.from(val as Map);
        final entries = <_AlertEntry>[];

        for (final e in raw.entries) {
          final data = Map<String, dynamic>.from(e.value);
          final level = _classify(_parseG(data['glucose']));
          final isResolved = data['resolved'] == true;

          if (_filter == 'unresolved' && isResolved) continue;
          if (_filter == 'resolved'   && !isResolved) continue;

          entries.add(_AlertEntry(
            key: e.key.toString(),
            data: data,
            path: "doctors/${widget.doctorId}/alerts",
            level: level,
          ));
        }

        entries.sort((a, b) =>
            (b.data['timestamp'] ?? 0).compareTo(a.data['timestamp'] ?? 0));

        final criticalUnresolved = entries
            .where((e) => e.level.severity == 'critical' && e.data['resolved'] != true)
            .length;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifyIfNew(criticalUnresolved);
        });

        return Column(children: [
          _filterBar(criticalUnresolved),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Aucune alerte correspondante',
                    style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _alertCard(entries[i]),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _filterBar(int criticalCount) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$criticalCount Non résolu(s)',
            style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      DropdownButton<String>(
        value: _filter,
        underline: const SizedBox(),
        style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
        items: const [
          DropdownMenuItem(value: 'all',        child: Text('Tous')),
          DropdownMenuItem(value: 'unresolved', child: Text('Non résolus')),
          DropdownMenuItem(value: 'resolved',   child: Text('Résolus')),
        ],
        onChanged: (v) => setState(() => _filter = v!),
      ),
    ]),
  );

  Widget _alertCard(_AlertEntry e) {
    final data = e.data;
    final isResolved = data['resolved'] == true;
    final timeStr = data['timestamp'] != null
        ? DateFormat('dd/MM HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(data['timestamp']))
        : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResolved ? Colors.grey.withOpacity(0.2) : e.level.color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 6, height: 60,
            decoration: BoxDecoration(
              color: isResolved ? Colors.grey : e.level.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(data['patientName'] ?? 'Patient inconnu',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
              const Spacer(),
              Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isResolved ? Colors.grey[200] : e.level.bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text("${e.level.label} : ${data['glucose']} g/L",
                  style: TextStyle(
                      color: isResolved ? Colors.grey[700] : e.level.color,
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ])),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isResolved ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isResolved ? Colors.green : e.level.color,
            ),
            onPressed: () => _toggleResolve(e.path, e.key, isResolved),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Onglet SOS
// ════════════════════════════════════════════════════════════════════════
class _EmergenciesTabKeepAlive extends StatefulWidget {
  final String doctorId;
  final DatabaseReference ref;
  const _EmergenciesTabKeepAlive({required this.doctorId, required this.ref});

  @override
  State<_EmergenciesTabKeepAlive> createState() => _EmergenciesTabKeepAliveState();
}

class _EmergenciesTabKeepAliveState extends State<_EmergenciesTabKeepAlive>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final AudioPlayer _audioPlayer = AudioPlayer();
  int _prevSosCount = -1;

  late final Stream<DatabaseEvent> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.ref.onValue;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleResolve(String path, String key, bool cur) async {
    await FirebaseDatabase.instance.ref("$path/$key").update({'resolved': !cur});
  }

  Future<void> _notifyIfNew(int newCount) async {
    if (_prevSosCount >= 0 && newCount > _prevSosCount) {
      try { await _audioPlayer.play(AssetSource('sounds/sos_alert.mp3')); } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
        backgroundColor: const Color(0xFF7F1D1D),
        leading: const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
        content: const Text('🆘 Nouvel appel SOS d\'un patient !',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        actions: [TextButton(
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          child: const Text('Masquer', style: TextStyle(color: Colors.white70)),
        )],
      ));
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      });
    }
    _prevSosCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<DatabaseEvent>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final val = snapshot.data?.snapshot.value;
        if (val == null) {
          return const Center(child: Text('Aucun appel SOS actif',
              style: TextStyle(color: Colors.grey, fontSize: 16)));
        }

        final raw = Map<dynamic, dynamic>.from(val as Map);
        final list = raw.entries
            .map((e) => {'key': e.key.toString(), ...Map<String, dynamic>.from(e.value as Map)})
            .toList()
          ..sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

        final activeCount = list.where((e) => e['resolved'] != true).length;
        WidgetsBinding.instance.addPostFrameCallback((_) => _notifyIfNew(activeCount));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final item = list[i];
            final isResolved = item['resolved'] == true;
            final phone = item['patientPhone']?.toString() ?? '';

            return Card(
              color: isResolved ? Colors.white : const Color(0xFFFEE2E2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _SosPulseIcon(resolved: isResolved),
                title: Text(item['patientName']?.toString() ?? 'Appel SOS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isResolved ? Colors.black87 : const Color(0xFF991B1B))),
                subtitle: Text("Contact: $phone"),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.blue),
                      onPressed: () => launchUrl(Uri.parse("tel:$phone")),
                    ),
                  IconButton(
                    icon: Icon(
                      isResolved ? Icons.check_circle : Icons.check_circle_outline,
                      color: isResolved ? Colors.green : Colors.red,
                    ),
                    onPressed: () => _toggleResolve(
                        "doctors/${widget.doctorId}/emergencies", item['key'], isResolved),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Classes utilitaires
// ════════════════════════════════════════════════════════════════════════

class _AlertEntry {
  final String key, path;
  final Map<String, dynamic> data;
  final _GlucoseLevel level;
  _AlertEntry({required this.key, required this.data, required this.path, required this.level});
}

class _GlucoseLevel {
  final String severity, label;
  final Color color, bg;
  const _GlucoseLevel({required this.severity, required this.color, required this.bg, required this.label});
}

class _SosPulseIcon extends StatefulWidget {
  final bool resolved;
  const _SosPulseIcon({required this.resolved});
  @override
  State<_SosPulseIcon> createState() => _SosPulseIconState();
}

class _SosPulseIconState extends State<_SosPulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.resolved) {
      return const Icon(Icons.check_circle_outline, size: 24, color: Colors.grey);
    }
    return ScaleTransition(
      scale: _anim,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withOpacity(0.2), shape: BoxShape.circle),
        child: const Icon(Icons.sos_rounded, size: 24, color: Color(0xFFD32F2F)),
      ),
    );
  }
}