import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class SecretaryNotesPage extends StatefulWidget {
  const SecretaryNotesPage({super.key});
  @override
  State<SecretaryNotesPage> createState() => _SecretaryNotesPageState();
}

class _SecretaryNotesPageState extends State<SecretaryNotesPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref();
  String? _doctorId;
  bool    _loading = true;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadDoctorId();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _doctorId = doc.data()?['doctorId'];
        _loading  = false;
      });
    }
  }

  Future<void> _markAsRead(String key) async {
    if (_doctorId == null) return;
    await _db
        .child('secretary_notes')
        .child(_doctorId!)
        .child(key)
        .update({'read': true});
  }

  Future<void> _markAllRead(List<MapEntry<dynamic, dynamic>> entries) async {
    if (_doctorId == null) return;
    for (final e in entries) {
      final d = Map<String, dynamic>.from(e.value);
      if (d['read'] != true) {
        await _db
            .child('secretary_notes')
            .child(_doctorId!)
            .child(e.key.toString())
            .update({'read': true});
      }
    }
  }

  String _fmt(dynamic raw) {
    if (raw == null) return '--';
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      return DateFormat('dd MMM yyyy · HH:mm').format(dt);
    } catch (_) { return raw.toString(); }
  }

  void _openNote(BuildContext context, String key, Map<String, dynamic> data) {
    _markAsRead(key);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 480,
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.mark_email_read_outlined,
                                color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Note du Médecin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timestamp
                            Row(
                              children: [
                                Icon(Icons.access_time_outlined,
                                  size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 6),
                                Text(
                                  _fmt(data['timestamp']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F5FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.15)),
                              ),
                              child: Text(
                                data['content'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Fermer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }
    if (_doctorId == null) {
      return const Center(
        child: Text('Aucun médecin associé à ce compte.'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.child('secretary_notes').child(_doctorId!).onValue,
        builder: (context, snap) {
          // ── Loading ──
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
          }

          final isEmpty =
              !snap.hasData || snap.data!.snapshot.value == null;

          final List<MapEntry<dynamic, dynamic>> entries = isEmpty
              ? []
              : (snap.data!.snapshot.value as Map)
                  .entries
                  .toList()
                ..sort((a, b) =>
                    (b.value['timestamp'] ?? 0)
                        .compareTo(a.value['timestamp'] ?? 0));

          final unreadCount =
              entries.where((e) => (e.value['read'] ?? false) != true).length;

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + title
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.mail_outlined,
                          color: Color(0xFF8B5CF6), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Notes du Médecin',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$unreadCount non lue${unreadCount > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Messages envoyés par votre médecin',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Mark all read
                      if (unreadCount > 0)
                        TextButton.icon(
                          onPressed: () => _markAllRead(entries),
                          icon: const Icon(Icons.done_all,
                            color: Color(0xFF8B5CF6), size: 18),
                          label: const Text('Tout marquer lu',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Empty state ──────────────────────────────────────────
              if (isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.07),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mail_outline,
                            size: 48, color: Color(0xFF8B5CF6)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Aucune note reçue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Les notes envoyées par le médecin\napparaîtront ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // ── Notes list ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final key  = entries[i].key.toString();
                        final data = Map<String, dynamic>.from(entries[i].value);
                        final isUnread = (data['read'] ?? false) != true;

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 250 + i * 60),
                          curve: Curves.easeOut,
                          builder: (_, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - v)),
                              child: child,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => _openNote(context, key, data),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isUnread
                                      ? const Color(0xFF8B5CF6).withOpacity(0.4)
                                      : Colors.grey.shade100,
                                  width: isUnread ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isUnread
                                        ? const Color(0xFF8B5CF6).withOpacity(0.08)
                                        : Colors.black.withOpacity(0.03),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Unread indicator dot
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5, right: 12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isUnread
                                            ? const Color(0xFF8B5CF6)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isUnread
                                              ? const Color(0xFF8B5CF6)
                                              : Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                data['title'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  color: isUnread
                                                      ? const Color(0xFF1E293B)
                                                      : const Color(0xFF64748B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (isUnread)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF8B5CF6)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Text('Nouveau',
                                                  style: TextStyle(
                                                    color: Color(0xFF8B5CF6),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),

                                        // Preview
                                        Text(
                                          data['content'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),

                                        // Time + open hint
                                        Row(
                                          children: [
                                            Icon(Icons.access_time_outlined,
                                              size: 12,
                                              color: Colors.grey.shade400),
                                            const SizedBox(width: 4),
                                            Text(
                                              _fmt(data['timestamp']),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text('Appuyer pour lire →',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: const Color(0xFF8B5CF6)
                                                    .withOpacity(0.7),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
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
                      childCount: entries.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}