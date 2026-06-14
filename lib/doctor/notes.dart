import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../doctor_settings_notifier.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseDatabase.instance.ref();
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  // Controllers
  final _titleController   = TextEditingController();
  final _contentController = TextEditingController();

  // Tab controller: 0 = Doctor notes, 1 = Secretary notes
  late TabController _tabController;

  // Form state
  String _selectedTag    = 'General';
  bool   _isAdding       = false;
  bool   _isSecretaryNote = false; // which section is the form for

  // ── Doctor personal tags (3 only) ───────────────────────────────────
  final List<String> _doctorTags = ['General', 'Administrative', 'Urgent'];

  final Map<String, Color> _tagColors = {
    'General':        const Color(0xFF3B82F6),
    'Administrative': const Color(0xFFF59E0B),
    'Urgent':         const Color(0xFFE05C5C),
  };

  final Map<String, IconData> _tagIcons = {
    'General':        Icons.notes_rounded,
    'Administrative': Icons.admin_panel_settings_outlined,
    'Urgent':         Icons.priority_high_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_isAdding) setState(() => _isAdding = false);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  String _fmt(dynamic raw) {
    if (raw == null) return '--';
    try {
      int? ms = raw is int ? raw : int.tryParse(raw.toString());
      DateTime dt = ms != null
          ? DateTime.fromMillisecondsSinceEpoch(ms > 9999999999 ? ms : ms * 1000)
          : DateTime.parse(raw.toString());
      return DateFormat('dd MMM yyyy  HH:mm').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  String t(String en, String ar, String fr) {
    // Replace with your actual localisation call
    return en;
  }

  // ── Firebase ops ─────────────────────────────────────────────────────

  /// Save a personal doctor note
  Future<void> _addDoctorNote() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) return;
    await _db.child('doctor_notes').child(doctorId!).push().set({
      'title':     _titleController.text.trim(),
      'content':   _contentController.text.trim(),
      'tag':       _selectedTag,
      'timestamp': ServerValue.timestamp,
    });
    _resetForm();
  }

  /// Send a note to the secretary node
  Future<void> _sendSecretaryNote() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) return;
    // Stored under secretary_notes/{doctorId}/ so the secretary
    // can read all notes sent by this doctor.
    await _db.child('secretary_notes').child(doctorId!).push().set({
      'title':     _titleController.text.trim(),
      'content':   _contentController.text.trim(),
      'doctorId':  doctorId,
      'timestamp': ServerValue.timestamp,
      'read':      false,
    });
    _resetForm();
  }

  Future<void> _deleteDoctorNote(String key) async {
    await _db.child('doctor_notes').child(doctorId!).child(key).remove();
  }

  Future<void> _deleteSecretaryNote(String key) async {
    await _db.child('secretary_notes').child(doctorId!).child(key).remove();
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _isAdding      = false;
      _selectedTag   = 'General';
      _isSecretaryNote = false;
    });
  }

  // ── UI helpers ───────────────────────────────────────────────────────

  void _openAddForm({required bool forSecretary}) {
    setState(() {
      _isAdding        = true;
      _isSecretaryNote = forSecretary;
      _selectedTag     = 'General';
      _titleController.clear();
      _contentController.clear();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Notes', 'الملاحظات', 'Notes'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('Personal clinical notes',
                              'ملاحظات سريرية شخصية',
                              'Notes cliniques personnelles'),
                            style: const TextStyle(
                              color: Colors.grey, fontSize: 15),
                          ),
                        ],
                      ),
                      // Cancel button (only when form is open)
                      if (_isAdding)
                        ElevatedButton.icon(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: Text(
                            t('Cancel', 'إلغاء', 'Annuler'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade500,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Tabs ─────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                      padding: const EdgeInsets.all(4),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_outline, size: 18),
                              const SizedBox(width: 6),
                              Text(t('My Notes', 'ملاحظاتي', 'Mes notes')),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_outlined, size: 18),
                              const SizedBox(width: 6),
                              Text(t('Secretary', 'للسكريتير', 'Secrétaire')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Add Form ─────────────────────────────────────────
                  if (_isAdding) _buildAddForm(),
                ],
              ),
            ),
          ),

          // ── Tab content ───────────────────────────────────────────────
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDoctorNotesTab(),
                _buildSecretaryNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Add note form ─────────────────────────────────────────────────────

  Widget _buildAddForm() {
    final isSecretary = _isSecretaryNote;
    final accentColor = isSecretary
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form header
          Row(
            children: [
              Icon(
                isSecretary ? Icons.send_rounded : Icons.note_add_outlined,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isSecretary
                    ? t('Send to Secretary', 'إرسال للسكريتير', 'Envoyer au secrétaire')
                    : t('Add New Note', 'أضف ملاحظة جديدة', 'Ajouter une note'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: t('Title', 'العنوان', 'Titre'),
              prefixIcon: Icon(Icons.title, color: accentColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accentColor)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 12),

          // Content
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: t('Content', 'المحتوى', 'Contenu'),
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 64),
                child: Icon(Icons.notes, color: accentColor),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accentColor)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),

          // Tag chips — only for doctor personal notes
          if (!isSecretary) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _doctorTags.map((tag) {
                final color    = _tagColors[tag]!;
                final selected = _selectedTag == tag;
                return ChoiceChip(
                  avatar: Icon(
                    _tagIcons[tag],
                    size: 14,
                    color: selected ? color : Colors.grey,
                  ),
                  label: Text(tag),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedTag = tag),
                  selectedColor: color.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected ? color : Colors.grey,
                    fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? color : Colors.grey.shade300),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Save / Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                isSecretary ? _sendSecretaryNote : _addDoctorNote,
              icon: Icon(
                isSecretary ? Icons.send_rounded : Icons.save_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                isSecretary
                    ? t('Send to Secretary',
                        'إرسال للسكريتير',
                        'Envoyer au secrétaire')
                    : t('Save Note', 'حفظ الملاحظة',
                        'Enregistrer la note'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1 : Doctor personal notes ────────────────────────────────────

  Widget _buildDoctorNotesTab() {
    return StreamBuilder<DatabaseEvent>(
      stream: _db.child('doctor_notes').child(doctorId!).onValue,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        }

        final isEmpty =
            !snap.hasData || snap.data!.snapshot.value == null;

        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add note button
              if (!_isAdding)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openAddForm(forSecretary: false),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      t('New Note', 'ملاحظة جديدة', 'Nouvelle note'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              if (isEmpty)
                _buildEmpty(
                  t('No personal notes yet',
                    'لا توجد ملاحظات شخصية بعد',
                    'Aucune note personnelle'),
                  Icons.notes_rounded,
                )
              else
                Expanded(child: _buildDoctorGrid(snap.data!)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoctorGrid(DatabaseEvent event) {
    final Map raw = event.snapshot.value as Map;
    final entries = raw.entries.toList()
      ..sort((a, b) =>
          (b.value['timestamp'] ?? 0)
              .compareTo(a.value['timestamp'] ?? 0));

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final key   = entries[i].key as String;
        final d     = Map<String, dynamic>.from(entries[i].value);
        final tag   = d['tag']?.toString() ?? 'General';
        final color = _tagColors[tag] ?? const Color(0xFF3B82F6);
        final icon  = _tagIcons[tag] ?? Icons.notes_rounded;

        return _NoteCard(
          title:     d['title']?.toString()   ?? '',
          content:   d['content']?.toString() ?? '',
          tag:       tag,
          tagColor:  color,
          tagIcon:   icon,
          timestamp: _fmt(d['timestamp']),
          onDelete:  () => _deleteDoctorNote(key),
        );
      },
    );
  }

  // ── Tab 2 : Secretary notes ──────────────────────────────────────────

  Widget _buildSecretaryNotesTab() {
    return StreamBuilder<DatabaseEvent>(
      stream:
          _db.child('secretary_notes').child(doctorId!).onValue,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B5CF6)));
        }

        final isEmpty =
            !snap.hasData || snap.data!.snapshot.value == null;

        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                      color: Color(0xFF8B5CF6), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t(
                          'Notes sent here will appear in the secretary\'s account.',
                          'الملاحظات المرسلة هنا ستظهر في حساب السكريتير.',
                          'Les notes envoyées ici apparaîtront dans le compte de la secrétaire.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Send note button
              if (!_isAdding)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openAddForm(forSecretary: true),
                    icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                    label: Text(
                      t('Send Note', 'إرسال ملاحظة', 'Envoyer une note'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              if (isEmpty)
                _buildEmpty(
                  t('No notes sent to secretary yet',
                    'لم ترسل أي ملاحظة للسكريتير بعد',
                    'Aucune note envoyée'),
                  Icons.send_outlined,
                )
              else
                Expanded(child: _buildSecretaryList(snap.data!)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecretaryList(DatabaseEvent event) {
    final Map raw = event.snapshot.value as Map;
    final entries = raw.entries.toList()
      ..sort((a, b) =>
          (b.value['timestamp'] ?? 0)
              .compareTo(a.value['timestamp'] ?? 0));

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final key     = entries[i].key as String;
        final d       = Map<String, dynamic>.from(entries[i].value);
        final isRead  = d['read'] == true;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead
                  ? Colors.grey.shade100
                  : const Color(0xFF8B5CF6).withOpacity(0.3),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5, right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRead
                      ? Colors.grey.shade300
                      : const Color(0xFF8B5CF6),
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            d['title']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isRead
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unread badge
                        if (!isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              t('Unread', 'غير مقروء', 'Non lu'),
                              style: const TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteSecretaryNote(key),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d['content']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fmt(d['timestamp']),
                      style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────

  Widget _buildEmpty(String message, IconData icon) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
              style: const TextStyle(
                color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// ── Reusable note card widget ─────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final String    title;
  final String    content;
  final String    tag;
  final Color     tagColor;
  final IconData  tagIcon;
  final String    timestamp;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.title,
    required this.content,
    required this.tag,
    required this.tagColor,
    required this.tagIcon,
    required this.timestamp,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag chip + delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tagIcon, size: 11, color: tagColor),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Content
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 12, color: Colors.grey, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // Timestamp
          Text(
            timestamp,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}