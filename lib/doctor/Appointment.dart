import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../doctor_settings_notifier.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  late Stream<QuerySnapshot> _appointmentsStream;

  @override
  void initState() {
    super.initState();
    _appointmentsStream = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  // دالة للتحقق من مطابقة تاريخ اليوم الحالي تماماً
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  DateTime? _parseRawDate(dynamic rawDate) {
    if (rawDate == null) return null;
    try {
      return DateTime.parse(rawDate.toString().trim());
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(dynamic rawDate) {
    final dt = _parseRawDate(rawDate);
    if (dt == null) return rawDate?.toString() ?? '--';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الهيدر العلوي البسيط بدون خانة البحث
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Today\'s appointments', 'مواعيد اليوم', 'Missions d\'aujourd\'hui'),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  t('Appointments for: ${DateFormat('dd MMMM yyyy', 'fr').format(now)}', 'قائمة المواعيد لـ: ${DateFormat('dd MMMM yyyy', 'fr').format(now)}', 'Liste des rendez-vous pour : ${DateFormat('dd MMMM yyyy', 'fr').format(now)}'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // قائمة عرض مواعيد اليوم
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _appointmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(t('Error: ${snapshot.error}', 'خطأ: ${snapshot.error}', 'Erreur : ${snapshot.error}')));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  List<Map<String, dynamic>> filteredList = [];

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final dateRaw = data['date'];
                    final appointmentDate = _parseRawDate(dateRaw);

                    // التصفية الصارمة للتاريخ فقط: مواعيد اليوم الحالي تلقائياً ومباشرة
                    if (appointmentDate == null || !_isToday(appointmentDate)) {
                      continue; 
                    }

                    // يتم جلب الموعد مهما كانت حالته (تم إلغاء فلاتر الحالة بناءً على طلبك)
                    filteredList.add({
                      'id': doc.id,
                      'patientName': data['patientName'] ?? 'Patient Inconnu',
                      'date': _fmtDate(dateRaw),
                      'time': data['time'] ?? '--:--',
                      'status': (data['status'] ?? 'en_attente').toString().trim().toLowerCase(),
                    });
                  }

                  // ترتيب المواعيد تصاعدياً حسب التوقيت الزمني (الساعة)
                  filteredList.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(t('No appointments for today.', 'لا توجد مواعيد لليوم.', 'Aucun rendez-vous pour aujourd\'hui.'), style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final String statusStr = item['status'];
                      final bool isConfirmed = statusStr == 'confirme';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: isDark ? theme.colorScheme.surface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.white10 : const Color(0xFF1E293B).withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: theme.colorScheme.primary, size: 22),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['patientName'],
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: theme.iconTheme.color?.withOpacity(0.7)),
                                      const SizedBox(width: 6),
                                      Text(
                                        item['date'],
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 20),
                                      Icon(Icons.access_time, size: 14, color: theme.iconTheme.color?.withOpacity(0.7)),
                                      const SizedBox(width: 6),
                                      Text(
                                        item['time'],
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            
                            // ويدجت الحالة التكيفي المظهر لتنسيق الواجهة الجمالي
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isConfirmed ? const Color(0xFFDFF5EC) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isConfirmed ? 'Confirmé' : 'En attente',
                                style: TextStyle(
                                  color: isConfirmed ? const Color(0xFF10B981) : const Color(0xFFFF9800),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
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