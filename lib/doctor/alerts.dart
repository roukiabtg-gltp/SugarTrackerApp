import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AlertsPage extends StatefulWidget {
  final String doctorId;
  const AlertsPage({super.key, required this.doctorId});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all'; // all / unresolved / resolved

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

  // ─── helpers ──────────────────────────────────────────────────────────────

  Color _borderColor(String type) {
    if (type == 'CRITICAL') return Colors.red;
    if (type == 'SOS') return Colors.red;
    return Colors.orange;
  }

  Color _iconColor(String type) {
    if (type == 'CRITICAL') return Colors.red;
    if (type == 'SOS') return Colors.red;
    return Colors.orange;
  }

  IconData _iconData(String type) {
    if (type == 'SOS') return Icons.sos_rounded;
    return Icons.warning_amber_rounded;
  }

  // ─── mark resolved ────────────────────────────────────────────────────────

  void _resolve(String patientId, Map data) {
    FirebaseDatabase.instance
        .ref("doctors/${widget.doctorId}/alerts/$patientId/status")
        .set("resolved");
  }

  void _dismiss(String patientId) {
    FirebaseDatabase.instance
        .ref("doctors/${widget.doctorId}/alerts/$patientId")
        .remove();
  }

  void _markAllRead(List<MapEntry> entries) {
    for (var e in entries) {
      FirebaseDatabase.instance
          .ref("doctors/${widget.doctorId}/alerts/${e.key}/isRead")
          .set(true);
    }
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref("doctors/${widget.doctorId}/alerts")
            .onValue,
        builder: (context, snap) {
          // ── loading ──
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── parse data ──
          Map<String, dynamic> allAlerts = {};
          if (snap.hasData && snap.data!.snapshot.value != null) {
            allAlerts = Map<String, dynamic>.from(
              snap.data!.snapshot.value as Map,
            );
          }

          final entries = allAlerts.entries.toList()
            ..sort((a, b) {
              int ta = (a.value['timestamp'] ?? 0) as int;
              int tb = (b.value['timestamp'] ?? 0) as int;
              return tb.compareTo(ta);
            });

          // ── counts ──
          int cntCritical = entries
              .where((e) =>
                  e.value['type'] == 'CRITICAL' &&
                  e.value['status'] != 'resolved')
              .length;
          int cntSos = entries
              .where((e) =>
                  e.value['type'] == 'SOS' &&
                  e.value['status'] != 'resolved')
              .length;
          int cntMonitored =
              entries.map((e) => e.key).toSet().length;

          // ── filter helper ──
          List<MapEntry<String, dynamic>> filtered(String tab) {
            return entries.where((e) {
              bool tabMatch = tab == 'critical'
                  ? e.value['type'] != 'SOS'
                  : e.value['type'] == 'SOS';
              bool filterMatch = _filter == 'all'
                  ? true
                  : _filter == 'resolved'
                      ? e.value['status'] == 'resolved'
                      : e.value['status'] != 'resolved';
              return tabMatch && filterMatch;
            }).toList();
          }

          return SafeArea(
            child: Column(
              children: [
                // ── header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Alerts",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Real-time patient monitoring",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _BellButton(hasUnread: entries
                          .any((e) => e.value['isRead'] == false)),
                    ],
                  ),
                ),

                // ── stat cards ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatCard(
                        icon: Icons.warning_amber_rounded,
                        iconBg: const Color(0xFFFCEBEB),
                        iconColor: const Color(0xFFA32D2D),
                        value: cntCritical,
                        label: "Critical",
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.sos_rounded,
                        iconBg: const Color(0xFFFAEEDA),
                        iconColor: const Color(0xFF854F0B),
                        value: cntSos,
                        label: "SOS Alerts",
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.people_outline_rounded,
                        iconBg: const Color(0xFFE6F1FB),
                        iconColor: const Color(0xFF185FA5),
                        value: cntMonitored,
                        label: "Monitored",
                      ),
                    ],
                  ),
                ),

                // ── tabs ─────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16, color: Colors.orange),
                            SizedBox(width: 6),
                            Text("Critical Measurements"),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sos_rounded,
                                size: 16, color: Colors.red),
                            SizedBox(width: 6),
                            Text("SOS Calls"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── filter row ───────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text("Show:",
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 8),
                      ..._buildFilters(),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _markAllRead(entries),
                        child: const Text(
                          "Mark all as read",
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF185FA5)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── list ─────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _AlertsList(
                        entries: filtered('critical'),
                        onResolve: _resolve,
                        onDismiss: _dismiss,
                        borderColor: _borderColor,
                        iconColor: _iconColor,
                        iconData: _iconData,
                      ),
                      _AlertsList(
                        entries: filtered('sos'),
                        onResolve: _resolve,
                        onDismiss: _dismiss,
                        borderColor: _borderColor,
                        iconColor: _iconColor,
                        iconData: _iconData,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFilters() {
    final filters = ['all', 'unresolved', 'resolved'];
    final labels = ['All', 'Unresolved', 'Resolved'];
    return List.generate(filters.length, (i) {
      bool active = _filter == filters[i];
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => setState(() => _filter = filters[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF185FA5) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? const Color(0xFF185FA5)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BellButton extends StatelessWidget {
  final bool hasUnread;
  const _BellButton({required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 20, color: Colors.grey),
        ),
        if (hasUnread)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFE24B4A),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final int value;
  final String label;
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              "$value",
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w500),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsList extends StatelessWidget {
  final List<MapEntry<String, dynamic>> entries;
  final Function(String, Map) onResolve;
  final Function(String) onDismiss;
  final Color Function(String) borderColor;
  final Color Function(String) iconColor;
  final IconData Function(String) iconData;

  const _AlertsList({
    required this.entries,
    required this.onResolve,
    required this.onDismiss,
    required this.borderColor,
    required this.iconColor,
    required this.iconData,
  });

  String _timeAgo(int? ts) {
    if (ts == null) return '';
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return DateFormat('dd/MM').format(DateTime.fromMillisecondsSinceEpoch(ts));
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text("No alerts",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = entries[i];
        final data = Map<String, dynamic>.from(e.value);
        final type = data['type']?.toString() ?? 'CRITICAL';
        final resolved = data['status'] == 'resolved';
        final unread = data['isRead'] == false;
        final ts = data['timestamp'] as int?;

        return Opacity(
          opacity: resolved ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: type == 'SOS'
                  ? const Color(0xFFFCEBEB)
                  : Colors.white,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(
                    color: resolved
                        ? Colors.grey.shade300
                        : borderColor(type),
                    width: 3),
                top: BorderSide(color: Colors.grey.shade200),
                right: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title row
                  Row(
                    children: [
                      Icon(iconData(type),
                          size: 18,
                          color: resolved
                              ? Colors.grey
                              : iconColor(type)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type == 'SOS'
                              ? "SOS emergency alert"
                              : type == 'CRITICAL'
                                  ? "Critical glucose level"
                                  : "Glucose warning",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(_timeAgo(ts),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          if (unread && !resolved) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE24B4A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // body
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      "Glucose: ${data['glucose']} g/L — "
                      "${type == 'SOS' ? 'Patient triggered SOS.' : type == 'CRITICAL' ? 'Immediate attention required.' : 'Monitor closely.'}",
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // footer
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Row(
                      children: [
                        _Tag(
                            label: data['patientName'] ?? 'Unknown',
                            bg: const Color(0xFFE6F1FB),
                            fg: const Color(0xFF0C447C)),
                        const SizedBox(width: 6),
                        _Tag(
                            label: type,
                            bg: type == 'SOS'
                                ? const Color(0xFFFCEBEB)
                                : const Color(0xFFFAEEDA),
                            fg: type == 'SOS'
                                ? const Color(0xFF791F1F)
                                : const Color(0xFF633806)),
                        const Spacer(),
                        if (!resolved)
                          GestureDetector(
                            onTap: () => onResolve(e.key, data),
                            child: const Text(
                              "Mark as resolved",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF185FA5)),
                            ),
                          ),
                        if (resolved)
                          const Icon(Icons.check_rounded,
                              size: 14, color: Colors.grey),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onDismiss(e.key),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _Tag({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}