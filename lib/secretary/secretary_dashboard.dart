import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});
  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  int     _selectedIndex = 0;
  String? _doctorId;       // ← الحقل الصحيح اللي يُحفظ في appointments
  bool    _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  // ── نجيب doctorId من Firestore تاع السكرتيرة ─────────────────────────
  Future<void> _loadDoctorId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (mounted) {
      setState(() {
        _doctorId = doc.data()?['doctorId'];
        _loading  = false;
      });
    }
  }

  List<Color> _avatarColors(String name) {
    const palettes = [
      [Color(0xFFE0F2FE), Color(0xFF0369A1)],
      [Color(0xFFFEF3C7), Color(0xFFB45309)],
      [Color(0xFFF3E8FF), Color(0xFF7E22CE)],
      [Color(0xFFFCE7F3), Color(0xFFBE185D)],
      [Color(0xFFDCFCE7), Color(0xFF15803D)],
      [Color(0xFFFFEDD5), Color(0xFFEA580C)],
      [Color(0xFFE0E7FF), Color(0xFF4338CA)],
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % palettes.length : 0;
    return palettes[idx];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  _ApptStatus _apptStatus(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'confirme': case 'confirmé': case 'confirmed':
        return _ApptStatus.confirmed;
      case 'annule': case 'annulé': case 'cancelled': case 'canceled':
        return _ApptStatus.cancelled;
      default:
        return _ApptStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1882FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(children: [
        _buildSidebar(),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildAccueilContent(),
              _buildRendezVousPage(),
              const Center(child: Text("Liste d'Attente")),
              const Center(child: Text("Patients")),
              const Center(child: Text("Facturation")),
            ],
          ),
        ),
      ]),
    );
  }

  // ══ Accueil ══════════════════════════════════════════════════════════
  Widget _buildAccueilContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          _buildTodayAppointments(),
        ],
      ),
    );
  }

  // ══ Today's Appointments ═════════════════════════════════════════════
  Widget _buildTodayAppointments() {
    // ── doctorId مش متوفر ──
    if (_doctorId == null || _doctorId!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text(
          '⚠️ doctorId introuvable pour ce compte secrétaire.\nVérifiez que le champ "doctorId" existe dans Firestore → users → [uid].',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      // ← نفلتر بـ doctorId (نفس الحقل اللي يُحفظ عند إضافة موعد)
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: _doctorId)
          .where('date', isEqualTo: todayStr)
          .snapshots(),
      builder: (context, snapshot) {
        // ── خطأ Firestore (مثلاً index ناقص) ──
        if (snapshot.hasError) {
          // fallback: نجيب كل مواعيد الطبيب ونفلتر يدوياً
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('doctorId', isEqualTo: _doctorId)
                .snapshots(),
            builder: (context, snap2) {
              final todayDocs = (snap2.data?.docs ?? []).where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return d['date']?.toString().startsWith(todayStr) == true;
              }).toList()
                ..sort((a, b) {
                  final ta = (a.data() as Map)['time']?.toString() ?? '';
                  final tb = (b.data() as Map)['time']?.toString() ?? '';
                  return ta.compareTo(tb);
                });
              return _appointmentsList(todayDocs, snap2, todayStr);
            },
          );
        }

        // ── ترتيب حسب الوقت محلياً (نتجنب orderBy + where = index مركب) ──
        final todayDocs = (snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final ta = (a.data() as Map)['time']?.toString() ?? '';
            final tb = (b.data() as Map)['time']?.toString() ?? '';
            return ta.compareTo(tb);
          });

        return _appointmentsList(todayDocs, snapshot, todayStr);
      },
    );
  }

  Widget _appointmentsList(
    List<QueryDocumentSnapshot> todayDocs,
    AsyncSnapshot<QuerySnapshot> snapshot,
    String todayStr,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  "Rendez-vous d'aujourd'hui",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'fr').format(DateTime.now()),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ]),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151)),
                  ),
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade100, height: 24),

          // ── القائمة ──
          if (!snapshot.hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: Color(0xFF1882FF)),
              ),
            )
          else if (todayDocs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(children: [
                  Icon(Icons.event_available_outlined,
                      size: 42, color: Colors.grey.withOpacity(0.35)),
                  const SizedBox(height: 12),
                  const Text(
                    "Aucun rendez-vous aujourd'hui",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ]),
              ),
            )
          else
            Column(
              children: todayDocs.asMap().entries.map((entry) {
                final isLast = entry.key == todayDocs.length - 1;
                final d      = entry.value.data() as Map<String, dynamic>;
                final st     = _apptStatus(d['status']?.toString());
                final name   = d['patientName']?.toString() ?? 'Patient';
                final colors = _avatarColors(name);
                final time   = d['time']?.toString() ?? '--';
                final type   = d['type']?.toString() ?? '--';
                final loc    = d['location']?.toString() ??
                               d['room']?.toString() ?? '--';
                final age    = d['age'];
                final isVirtual =
                    loc.toLowerCase().contains('virtual') ||
                    loc.toLowerCase().contains('online') ||
                    loc.toLowerCase().contains('visio');

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade100, width: 0.8)),
                  ),
                  child: Row(children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colors[0],
                      child: Text(
                        _initials(name),
                        style: TextStyle(
                            color: colors[1],
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // الاسم + النوع
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF111827))),
                          const SizedBox(height: 2),
                          Text(
                            age != null ? '$type · Age $age' : type,
                            style:
                                const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    // وقت + موقع + badge
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_outlined,
                                size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(time,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVirtual
                                  ? Icons.videocam_outlined
                                  : Icons.meeting_room_outlined,
                              size: 13,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(loc,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: st.bgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            st.label,
                            style: TextStyle(
                                color: st.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ]),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ══ Rendez-vous page ═════════════════════════════════════════════════
  Widget _buildRendezVousPage() {
    if (_doctorId == null || _doctorId!.isEmpty) {
      return const Center(child: Text("doctorId introuvable."));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: _doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1882FF)));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Aucun rendez-vous."));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final rdv = docs[index].data() as Map<String, dynamic>;
            return _buildPatientRow(
              rdv['patientName'] ?? 'Patient',
              rdv['time'] ?? '--:--',
              rdv['status'] ?? 'en_attente',
            );
          },
        );
      },
    );
  }

  Widget _buildSidebar() => Container(width: 280, color: Colors.white);

  Widget _buildPatientRow(String name, String time, String status) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text("$time - $status"),
      ),
    );
  }
}

// ── Status Enum ───────────────────────────────────────────────────────────
enum _ApptStatus { confirmed, pending, cancelled }

extension _ApptStatusExt on _ApptStatus {
  Color get color {
    switch (this) {
      case _ApptStatus.confirmed: return const Color(0xFF10B981);
      case _ApptStatus.cancelled: return const Color(0xFFEF4444);
      case _ApptStatus.pending:   return const Color(0xFFF59E0B);
    }
  }

  Color get bgColor {
    switch (this) {
      case _ApptStatus.confirmed: return const Color(0xFFDCFCE7);
      case _ApptStatus.cancelled: return const Color(0xFFFEE2E2);
      case _ApptStatus.pending:   return const Color(0xFFFEF3C7);
    }
  }

  String get label {
    switch (this) {
      case _ApptStatus.confirmed: return 'Confirmé';
      case _ApptStatus.cancelled: return 'Annulé';
      case _ApptStatus.pending:   return 'En attente';
    }
  }
}
