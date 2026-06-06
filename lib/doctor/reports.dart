import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../doctor_settings_notifier.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  late Stream<QuerySnapshot> _appointmentsStream;

  String? _selectedPatient;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appointmentsStream = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
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
    return DateFormat('dd MMM yyyy', 'en').format(dt);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          }

          if (snapshot.hasError) {
            return Center(child: Text(t('Connection error: ${snapshot.error}', 'خطأ في الاتصال: ${snapshot.error}', 'Erreur de connexion : ${snapshot.error}')));
          }

          Set<String> allPatientsSet = {};
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['patientName']?.toString().trim();
              if (name != null && name.isNotEmpty) {
                allPatientsSet.add(name);
              }
            }
          }
          List<String> patientList = allPatientsSet.toList()..sort();

          List<String> filteredPatients = patientList
              .where((p) => p.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          // تم إصلاح التعيين التلقائي هنا باستخدام WidgetsBinding لتجنب تعليق حلقة الرسم (Build Cycle) للويب
          if (filteredPatients.isNotEmpty) {
            if (_selectedPatient == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedPatient = filteredPatients.first);
              });
            } else if (!_filteredPatientsContainsSelected(filteredPatients, _selectedPatient)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedPatient = filteredPatients.first);
              });
            }
          }

          List<Map<String, dynamic>> patientVisits = [];
          Map<String, int> typeFrequency = {};
          String lastVisitStr = '--';

          if (snapshot.hasData && _selectedPatient != null) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final pName = data['patientName']?.toString().trim();

              if (pName == _selectedPatient) {
                final dateRaw = data['date'];
                final timeRaw = data['time'] ?? '--:--';
                final type = data['type']?.toString() ?? 'Consultation';
                final dt = _parseRawDate(dateRaw);

                typeFrequency[type] = (typeFrequency[type] ?? 0) + 1;

                patientVisits.add({
                  'patient': pName,
                  'type': type,
                  'time': timeRaw,
                  'dateFormatted': _fmtDate(dateRaw),
                  'rawDate': dt,
                });
              }
            }

            patientVisits.sort((a, b) {
              if (a['rawDate'] == null) return 1;
              if (b['rawDate'] == null) return -1;
              return (b['rawDate'] as DateTime).compareTo(a['rawDate'] as DateTime);
            });

            if (patientVisits.isNotEmpty) {
              lastVisitStr = patientVisits.first['dateFormatted'];
            }
          }

          String mainReason = '--';
          if (typeFrequency.isNotEmpty) {
            mainReason = typeFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          }

          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Patient History Report', 'تقرير تاريخ المرضى', 'Rapport historique des patients'), 
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(t('Chronological and analytical tracking of consultations by patient', 'المتابعة الزمنية والتحليلية للاستشارات حسب المريض', 'Suivi chronologique et analytique des consultations par patient'), 
                        style: const TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: t('Search patient by name...', 'ابحث عن المريض بالاسم...', 'Rechercher un patient par nom...'),
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 16, color: theme.iconTheme.color),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? theme.colorScheme.surface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filteredPatients.contains(_selectedPatient) ? _selectedPatient : null,
                            hint: Text(t('Select patient...', 'اختر المريض...', 'Sélectionner le patient...'), style: const TextStyle(fontSize: 14)),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFF3B82F6), size: 22),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedPatient = newValue);
                              }
                            },
                            items: filteredPatients.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 18, color: Color(0xFF3B82F6)),
                                    const SizedBox(width: 10),
                                    Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (_selectedPatient == null || patientVisits.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            t('No history available for this patient.', 'لا يوجد تاريخ متاح لهذا المريض.', 'Aucun historique disponible pour ce patient.'),
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      _statCard(t('Total Consultations', 'إجمالي الاستشارات', 'Total des consultations'), patientVisits.length.toString(), const Color(0xFF3B82F6), const Color(0xFFEFF6FF), Icons.analytics),
                      const SizedBox(width: 16),
                      _statCard(t('Last Visit', 'آخر زيارة', 'Dernière consultation'), lastVisitStr, const Color(0xFF10B981), const Color(0xFFDFF5EC), Icons.event_available),
                      const SizedBox(width: 16),
                      _statCard(t('Main Reason', 'السبب الرئيسي', 'Motif principal'), mainReason, const Color(0xFFD4A017), const Color(0xFFFFF9C4), Icons.psychology),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            color: isDark ? theme.colorScheme.surfaceVariant : const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(t('Patient Name', 'اسم المريض', 'Nom du patient'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14))),
                                Expanded(flex: 2, child: Text(t('Visit Type', 'نوع الزيارة', 'Type de visite'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14))),
                                Expanded(flex: 2, child: Text(t('Date & Time', 'التاريخ والوقت', 'Date et heure'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14))),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor),
                          Expanded(
                            child: ListView.separated(
                              itemCount: patientVisits.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEDF2F7)),
                              itemBuilder: (context, index) {
                                final visit = patientVisits[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2, 
                                        child: Text(
                                          visit['patient'], 
                                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                                        )
                                      ),
                                      Expanded(
                                        flex: 2, 
                                        child: Text(
                                          visit['type'], 
                                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                                        )
                                      ),
                                      Expanded(
                                        flex: 2, 
                                        child: Text(
                                          '${visit['dateFormatted']}  ${visit['time']}', 
                                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color, fontSize: 14, fontWeight: FontWeight.w500)
                                        )
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // دالة مساعدة مضافة للحفاظ على نظافة كود الشرط أعلاه
  bool _filteredPatientsContainsSelected(List<String> list, String? selected) {
    return list.contains(selected);
  }

  Widget _statCard(String label, String value, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(icon, color: color.withOpacity(0.25), size: 32),
          ],
        ),
      ),
    );
  }
}