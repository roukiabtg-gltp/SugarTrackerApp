import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../doctor_settings_notifier.dart';
import 'patient_profile_helpers.dart';

class NotesTab extends StatefulWidget {
  final String patientId;

  const NotesTab({super.key, required this.patientId});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final _db = FirebaseDatabase.instance.ref();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    _db.child('notes').child(widget.patientId).push().set({
      'content': text,
      'sender': 'doctor',
      'timestamp': ServerValue.timestamp,
      'date': DateTime.now().toString().substring(0, 16),
    });
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t('Clinical Notes', 'ملاحظات سريرية', 'Notes cliniques'),
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t('Write a clinical note...', 'اكتب ملاحظة سريرية...',
                  'Écrivez une note clinique...'),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _addNote,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(t('Add Note', 'إضافة ملاحظة', 'Ajouter une note'),
              style: const TextStyle(color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 20),
      StreamBuilder(
        stream: _db.child('notes').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text(
                        t('No notes yet', 'لا توجد ملاحظات حتى الآن',
                            'Aucune note pour le moment'),
                        style: const TextStyle(color: Colors.grey))));
          }
          final Map raw = snap.data!.snapshot.value as Map;
          final entries = raw.entries.toList()
            ..sort((a, b) => (b.value['timestamp'] ?? 0)
                .compareTo(a.value['timestamp'] ?? 0));
          return Column(
            children: entries.map((e) {
              final d = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_outlined,
                          color: Color(0xFF3B82F6), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(d['content'] ?? '',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D3142))),
                            const SizedBox(height: 4),
                            Text(fmtDate(d['timestamp']),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ])),
                    ]),
              );
            }).toList(),
          );
        },
      ),
    ]);
  }
}
