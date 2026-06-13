import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'Rendez-vous.dart';
import 'Patients.dart';
import 'Liste d\'Attente.dart';
import 'facture.dart';
import '../desktop/auth/login_desktop.dart';
import 'secretary_profile_page.dart';
import 'secretary_settings_page.dart';

class NurseMainLayout extends StatefulWidget {
  const NurseMainLayout({super.key});
  @override
  State<NurseMainLayout> createState() => _NurseMainLayoutState();
}

class _NurseMainLayoutState extends State<NurseMainLayout> {
  int    _selectedIndex = 0;
  String _secretaryName = 'Secrétaire';
  String? doctorId;

  @override
  void initState() { super.initState(); _loadSecretaryInfo(); }

  Future<void> _loadSecretaryInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _secretaryName = doc['name'] ?? 'Secrétaire';
        doctorId       = doc['doctorId'];
      });
    }
  }

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home_outlined,          'label': 'Accueil'},
    {'icon': Icons.calendar_month_outlined,'label': 'Rendez-vous'},
    {'icon': Icons.access_time_outlined,   'label': "Liste d'Attente"},
    {'icon': Icons.people_outline,         'label': 'Patients'},
    {'icon': Icons.receipt_long_outlined,  'label': 'Facturation'},
    {'icon': Icons.settings_outlined,      'label': 'Paramètres'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(children: [
        _buildSidebar(),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: IndexedStack(index: _selectedIndex, children: [
            _SecretaryDashboardContent(
              doctorId:      doctorId,
              secretaryName: _secretaryName,
              onNavigate:    (i) => setState(() => _selectedIndex = i),
            ),
            const AppointmentPage(),
            const WaitingListPage(),
            const PatientsPage(),
            const FacturePage(),
            const SecretarySettingsPage(),
            const SecretaryProfilePage(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260, color: Colors.white,
      child: Column(children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.monitor_heart, color: Color(0xFF2563EB), size: 26),
            ),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('GlucoLink',       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              Text('Secrétaire Méd.', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ]),
        ),
        const SizedBox(height: 28),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _menuItems.length,
            itemBuilder: (_, i) => _sidebarItem(
              icon: _menuItems[i]['icon'], label: _menuItems[i]['label'],
              isSelected: _selectedIndex == i,
              onTap: () => setState(() => _selectedIndex = i),
            ),
          ),
        ),
        const Divider(height: 1),
        InkWell(
          onTap: () => setState(() => _selectedIndex = 6),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedIndex == 6
                  ? const Color(0xFF2563EB).withOpacity(0.06)
                  : Colors.transparent,
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: _selectedIndex == 6
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF2563EB).withOpacity(0.1),
                child: Text(
                  _secretaryName.isNotEmpty ? _secretaryName[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: _selectedIndex == 6 ? Colors.white : const Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_secretaryName, style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13,
                  overflow: TextOverflow.ellipsis,
                  color: _selectedIndex == 6 ? const Color(0xFF2563EB) : const Color(0xFF0D1117),
                )),
                const Text('Secrétaire', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ])),
              Icon(Icons.chevron_right_rounded, size: 18,
                  color: _selectedIndex == 6 ? const Color(0xFF2563EB) : Colors.grey.shade400),
            ]),
          ),
        ),
        _sidebarItem(
          icon: Icons.logout, label: 'Déconnexion',
          isSelected: false, isLogout: true,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginDesktop()), (_) => false);
            }
          },
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _sidebarItem({
    required IconData icon, required String label,
    required bool isSelected, required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final color = isLogout ? Colors.redAccent
        : isSelected ? const Color(0xFF2563EB) : Colors.grey[600]!;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: isSelected ? Colors.white : color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          )),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECRETARY DASHBOARD CONTENT
// ═══════════════════════════════════════════════════════════════════

class _SecretaryDashboardContent extends StatefulWidget {
  final String?   doctorId;
  final String    secretaryName;
  final void Function(int) onNavigate;
  const _SecretaryDashboardContent({
    required this.doctorId, required this.secretaryName, required this.onNavigate,
  });
  @override State<_SecretaryDashboardContent> createState() => _SecretaryDashboardContentState();
}

class _SecretaryDashboardContentState extends State<_SecretaryDashboardContent> {

  void _showNewAppointmentDialog() {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    String type = 'Consultation';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouveau Rendez-vous', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nameCtrl, 'Nom du patient', Icons.person_outline),
          const SizedBox(height: 12),
          TextField(
            controller: dateCtrl, readOnly: true,
            decoration: InputDecoration(
              labelText: 'Date', prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
            ),
            onTap: () async {
              final d = await showDatePicker(context: ctx,
                  initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
              if (d != null) dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
            },
          ),
          const SizedBox(height: 12),
          _field(timeCtrl, 'Heure (ex: 09:30)', Icons.access_time_outlined),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: type,
            decoration: InputDecoration(labelText: 'Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: const Color(0xFFF8FAFC)),
            items: ['Consultation', 'Controle', 'Urgence']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setDlg(() => type = v!),
          ),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          _blueBtn('Enregistrer', () async {
            if (nameCtrl.text.isEmpty || dateCtrl.text.isEmpty) return;
            await FirebaseFirestore.instance.collection('appointments').add({
              'patientName': nameCtrl.text.trim(),
              'date':        dateCtrl.text,
              'time':        timeCtrl.text.trim(),
              'type':        type,
              'doctorId':    widget.doctorId,
              'status':      'en_attente',
              'createdAt':   FieldValue.serverTimestamp(),
            });
            if (mounted) Navigator.pop(ctx);
          }),
        ],
      )),
    );
  }

  void _showNewPatientDialog() {
    final firstCtrl = TextEditingController(); final lastCtrl    = TextEditingController();
    final emailCtrl = TextEditingController(); final phoneCtrl   = TextEditingController();
    final birthCtrl = TextEditingController(); final addressCtrl = TextEditingController();
    String blood = 'A+'; String gender = 'Homme'; bool loading = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouveau Patient', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: _field(firstCtrl, 'Prénom', Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _field(lastCtrl,  'Nom',    Icons.person_outline)),
          ]),
          const SizedBox(height: 12),
          _field(emailCtrl, 'Email', Icons.email_outlined),
          const SizedBox(height: 12),
          _field(phoneCtrl, 'Téléphone', Icons.phone_outlined),
          const SizedBox(height: 12),
          TextField(
            controller: birthCtrl, readOnly: true,
            decoration: InputDecoration(labelText: 'Date de naissance',
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: const Color(0xFFF8FAFC)),
            onTap: () async {
              final d = await showDatePicker(context: ctx,
                  initialDate: DateTime(1990), firstDate: DateTime(1930), lastDate: DateTime.now());
              if (d != null) birthCtrl.text = DateFormat('dd/MM/yyyy').format(d);
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: gender,
              decoration: InputDecoration(labelText: 'Genre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: const Color(0xFFF8FAFC)),
              items: ['Homme','Femme'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setDlg(() => gender = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              value: blood,
              decoration: InputDecoration(labelText: 'Groupe sanguin',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: const Color(0xFFF8FAFC)),
              items: ['A+','A-','B+','B-','AB+','AB-','O+','O-']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setDlg(() => blood = v!),
            )),
          ]),
          const SizedBox(height: 12),
          _field(addressCtrl, 'Adresse', Icons.location_on_outlined),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          if (loading)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator())
          else
            _blueBtn('Enregistrer', () async {
              if (firstCtrl.text.isEmpty || lastCtrl.text.isEmpty) return;
              setDlg(() => loading = true);
              await FirebaseDatabase.instance.ref('users').push().set({
                'first_name': firstCtrl.text.trim(), 'last_name': lastCtrl.text.trim(),
                'email': emailCtrl.text.trim(),       'phone': phoneCtrl.text.trim(),
                'birth_date': birthCtrl.text,         'gender': gender,
                'blood_type': blood,                  'address': addressCtrl.text.trim(),
                'role': 'patient',                    'doctorId': widget.doctorId,
                'createdAt': ServerValue.timestamp,
              });
              if (mounted) Navigator.pop(ctx);
            }),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greeting, ${widget.secretaryName} 👋',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ]),
        ]),
        const SizedBox(height: 32),
        const Text('Actions Rapides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Row(children: [
          _ParticleButton(label: 'Nouveau\nRendez-vous', icon: Icons.add_circle_outline,
              color: const Color(0xFF2563EB), onTap: _showNewAppointmentDialog),
          const SizedBox(width: 16),
          _ParticleButton(label: 'Nouveau Patient', icon: Icons.person_add_outlined,
              color: const Color(0xFF10B981), onTap: _showNewPatientDialog),
          const SizedBox(width: 16),
          _ParticleButton(label: "Liste d'Attente", icon: Icons.access_time_outlined,
              color: const Color(0xFFEA580C), onTap: () => widget.onNavigate(2)),
          const SizedBox(width: 16),
          _ParticleButton(label: 'Facturation', icon: Icons.receipt_long_outlined,
              color: const Color(0xFF7C3AED), onTap: () => widget.onNavigate(4)),
        ]),
        const SizedBox(height: 36),
        _StatsRow(doctorId: widget.doctorId),
        const SizedBox(height: 36),
        Row(children: [
          const Expanded(child: Text("Rendez-vous d'Aujourd'hui",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
          TextButton.icon(
            onPressed: () => widget.onNavigate(1),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Voir tout'),
          ),
        ]),
        const SizedBox(height: 12),
        _TodayAppointments(doctorId: widget.doctorId),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true, fillColor: const Color(0xFFF8FAFC),
    ),
  );

  Widget _blueBtn(String label, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2563EB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    child: Text(label, style: const TextStyle(color: Colors.white)),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  PARTICLE BUTTON
// ═══════════════════════════════════════════════════════════════════

class _ParticleButton extends StatefulWidget {
  final String label; final IconData icon;
  final Color color;  final VoidCallback onTap;
  const _ParticleButton({required this.label, required this.icon, required this.color, required this.onTap});
  @override State<_ParticleButton> createState() => _ParticleButtonState();
}

class _ParticleButtonState extends State<_ParticleButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  bool _showParticles = false;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _burst() {
    setState(() {
      _showParticles = true; _particles.clear();
      for (int i = 0; i < 8; i++) _particles.add(_Particle(color: widget.color, index: i));
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showParticles = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); _burst(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.color.withOpacity(0.18)),
                boxShadow: [BoxShadow(color: widget.color.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(widget.label, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: widget.color)),
              ]),
            ),
            if (_showParticles) ..._particles.map((p) => _ParticleWidget(particle: p)),
          ]),
        ),
      ),
    );
  }
}

class _Particle {
  final Color color; final double angle, distance, size;
  _Particle({required Color color, required int index})
      : color = color, angle = (index / 8) * 2 * 3.14159,
        distance = 40 + (index % 3) * 15.0, size = 5 + (index % 3) * 3.0;
}

class _ParticleWidget extends StatefulWidget {
  final _Particle particle;
  const _ParticleWidget({required this.particle});
  @override State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _progress, _opacity;
  @override
  void initState() {
    super.initState();
    _ctrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _opacity  = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)));
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final dx = widget.particle.distance * _progress.value * math.cos(widget.particle.angle);
        final dy = widget.particle.distance * _progress.value * math.sin(widget.particle.angle);
        return Positioned(
          left: 0, right: 0, top: 0, bottom: 0,
          child: Align(alignment: Alignment.center,
            child: Transform.translate(offset: Offset(dx, dy),
              child: Opacity(opacity: _opacity.value.clamp(0.0, 1.0),
                child: Container(
                  width: widget.particle.size, height: widget.particle.size,
                  decoration: BoxDecoration(color: widget.particle.color.withOpacity(0.8), shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATS ROW
// ═══════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final String? doctorId;
  const _StatsRow({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    if (doctorId == null) {
      return Row(children: [
        _stat("Aujourd'hui", '—', 'Rendez-vous', const Color(0xFF2563EB)), const SizedBox(width: 14),
        _stat('Total',       '—', 'Rendez-vous', const Color(0xFF10B981)), const SizedBox(width: 14),
        _stat('En Attente',  '—', 'À confirmer', const Color(0xFFEA580C)), const SizedBox(width: 14),
        _stat('Patients',    '—', 'Enregistrés', const Color(0xFF7C3AED)),
      ]);
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return Row(children: [
            _stat("Aujourd'hui", '…', 'Rendez-vous', const Color(0xFF2563EB)), const SizedBox(width: 14),
            _stat('Total',       '…', 'Rendez-vous', const Color(0xFF10B981)), const SizedBox(width: 14),
            _stat('En Attente',  '…', 'À confirmer', const Color(0xFFEA580C)), const SizedBox(width: 14),
            _stat('Patients',    '—', 'Enregistrés', const Color(0xFF7C3AED)),
          ]);
        }
        final all      = snap.data?.docs ?? [];
        final total    = all.length;
        final todayRdv = all.where((d) => (d.data() as Map)['date']?.toString().startsWith(today) == true).length;
        final waiting  = all.where((d) {
          final s = ((d.data() as Map)['status'] ?? '').toString().toLowerCase();
          return s == 'en_attente' || s == 'en-attente' || s == 'pending';
        }).length;

        return Row(children: [
          _stat("Aujourd'hui", todayRdv.toString(), 'Rendez-vous', const Color(0xFF2563EB)), const SizedBox(width: 14),
          _stat('Total',       total.toString(),    'Rendez-vous', const Color(0xFF10B981)), const SizedBox(width: 14),
          _stat('En Attente',  waiting.toString(),  'À confirmer', const Color(0xFFEA580C)), const SizedBox(width: 14),
          _stat('Patients',    '—',                 'Enregistrés', const Color(0xFF7C3AED)),
        ]);
      },
    );
  }

  Widget _stat(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(sub,   style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TODAY APPOINTMENTS  ← الإصلاح الرئيسي
// ═══════════════════════════════════════════════════════════════════

class _TodayAppointments extends StatefulWidget {
  final String? doctorId;
  const _TodayAppointments({required this.doctorId});
  @override State<_TodayAppointments> createState() => _TodayAppointmentsState();
}

class _TodayAppointmentsState extends State<_TodayAppointments> {
  Stream<QuerySnapshot>? _stream;

  @override
  void initState() {
    super.initState();
    _loadStream();
  }

  Future<void> _loadStream() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final doctorId = doc.data()?['doctorId'] as String?;
    if (doctorId == null || doctorId.isEmpty) return;
    if (mounted) {
      setState(() {
        _stream = FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (_stream == null) return _box(child: const Center(child: Text("Chargement…", style: TextStyle(color: Colors.grey))));

    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (_, snap) {
        if (snap.hasError) return _box(child: const Center(child: Text("Erreur de chargement", style: TextStyle(color: Colors.red))));
        if (!snap.hasData) return _box(child: const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF2563EB)))));

        // فلترة اليوم + ترتيب محلي بالوقت
        final docs = snap.data!.docs.where((d) {
          return (d.data() as Map)['date']?.toString().startsWith(today) == true;
        }).toList()
          ..sort((a, b) {
            final ta = (a.data() as Map)['time']?.toString() ?? '';
            final tb = (b.data() as Map)['time']?.toString() ?? '';
            return ta.compareTo(tb);
          });

        if (docs.isEmpty) {
          return _box(child: const Center(child: Padding(padding: EdgeInsets.all(24),
              child: Text("Aucun rendez-vous aujourd'hui", style: TextStyle(color: Colors.grey)))));
        }

        return _box(child: Column(
          children: docs.map((doc) {
            final d      = doc.data() as Map<String, dynamic>;
            final status = (d['status'] ?? 'en_attente').toString();
            final color  = status == 'confirme' || status == 'confirmé'
                ? const Color(0xFF10B981)
                : status == 'annule' || status == 'annulé'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFEA580C);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(width: 4, height: 40,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['patientName'] ?? 'Inconnu',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${d['time'] ?? '--'}  •  ${d['type'] ?? '--'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ]),
            );
          }).toList(),
        ));
      },
    );
  }

  Widget _box({required Widget child}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: child,
  );
}
