import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../doctor_settings_notifier.dart';
import 'patient_profile_helpers.dart';

class MessagesTab extends StatefulWidget {
  final String patientId;

  const MessagesTab({super.key, required this.patientId});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final _db = FirebaseDatabase.instance.ref();
  final _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _db.child('messages').child(widget.patientId).push().set({
      'content': text,
      'sender': 'doctor',
      'timestamp': ServerValue.timestamp,
      'date': DateTime.now().toString().substring(0, 16),
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t('Messages', 'الرسائل', 'Messages'),
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142))),
      const SizedBox(height: 16),
      StreamBuilder(
        stream: _db.child('messages').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.snapshot.value == null) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text(
                        t('No messages yet', 'لا توجد رسائل حتى الآن',
                            'Aucun message pour le moment'),
                        style: const TextStyle(color: Colors.grey))));
          }
          final Map raw = snap.data!.snapshot.value as Map;
          final entries = raw.entries.toList()
            ..sort((a, b) => (a.value['timestamp'] ?? 0)
                .compareTo(b.value['timestamp'] ?? 0));
          return Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final d = entries[i].value;
                bool isDoctor = d['sender'] == 'doctor';
                return Align(
                  alignment: isDoctor
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: isDoctor
                          ? const Color(0xFF3B82F6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5)
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: isDoctor
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(d['content'] ?? '',
                              style: TextStyle(
                                  color: isDoctor
                                      ? Colors.white
                                      : const Color(0xFF2D3142),
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(fmtDate(d['timestamp']),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDoctor
                                      ? Colors.white70
                                      : Colors.grey)),
                        ]),
                  ),
                );
              },
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _msgController,
            decoration: InputDecoration(
              hintText: t('Write a message...', 'اكتب رسالة...',
                  'Écrivez un message...'),
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
        const SizedBox(width: 10),
        IconButton(
          style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.all(14)),
          icon: const Icon(Icons.send, color: Colors.white),
          onPressed: _sendMessage,
        ),
      ]),
    ]);
  }
}
