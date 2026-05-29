import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _db = FirebaseDatabase.instance.ref();
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedTag = 'General';
  bool _isAdding = false;

  final List<String> _tags = ['General', 'Urgent', 'Follow-up', 'Research', 'Administrative'];

  final Map<String, Color> _tagColors = {
    'General':        const Color(0xFF3B82F6),
    'Urgent':         const Color(0xFFE05C5C),
    'Follow-up':      const Color(0xFF10B981),
    'Research':       const Color(0xFF8B5CF6),
    'Administrative': const Color(0xFFF59E0B),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

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

  Future<void> _addNote() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) return;
    await _db.child('doctor_notes').child(doctorId!).push().set({
      'title':     _titleController.text.trim(),
      'content':   _contentController.text.trim(),
      'tag':       _selectedTag,
      'timestamp': ServerValue.timestamp,
    });
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _isAdding = false;
      _selectedTag = 'General';
    });
  }

  Future<void> _deleteNote(String key) async {
    await _db.child('doctor_notes').child(doctorId!).child(key).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Notes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    SizedBox(height: 4),
                    Text('Personal clinical notes', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isAdding = !_isAdding),
                  icon: Icon(_isAdding ? Icons.close : Icons.add, color: Colors.white),
                  label: Text(_isAdding ? 'Cancel' : 'New Note', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Add Form ────────────────────────────────────────────────
            if (_isAdding)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        prefixIcon: const Icon(Icons.title, color: Color(0xFF3B82F6)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.notes, color: Color(0xFF3B82F6)),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tag selector
                    Wrap(
                      spacing: 8,
                      children: _tags.map((tag) {
                        final color = _tagColors[tag]!;
                        final selected = _selectedTag == tag;
                        return ChoiceChip(
                          label: Text(tag),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedTag = tag),
                          selectedColor: color.withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: selected ? color : Colors.grey,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(color: selected ? color : Colors.grey.shade300),
                          backgroundColor: Colors.white,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Save Note', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Notes List ──────────────────────────────────────────────
            Expanded(
              child: StreamBuilder(
                stream: _db.child('doctor_notes').child(doctorId!).onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                  }
                  if (!snap.hasData || snap.data!.snapshot.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notes, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No notes yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          const Text('Click "New Note" to add your first note', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  final Map raw = snap.data!.snapshot.value as Map;
                  final entries = raw.entries.toList()
                    ..sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final key = entries[i].key;
                      final d   = entries[i].value;
                      final tag = d['tag']?.toString() ?? 'General';
                      final color = _tagColors[tag] ?? const Color(0xFF3B82F6);

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(tag, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _deleteNote(key),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              d['title'] ?? '',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                d['content'] ?? '',
                                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                                overflow: TextOverflow.fade,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _fmt(d['timestamp']),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
