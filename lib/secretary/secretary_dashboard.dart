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
  int _selectedIndex = 0;
  String? doctorUid; 
  bool _isLoadingDoctor = true; // مؤشر لحين جلب الـ ID

  @override
  void initState() {
    super.initState();
    _fetchDoctorId(); 
  }

  Future<void> _fetchDoctorId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // جلب وثيقة السكرتيرة الحالية من جدول الـ users
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (mounted && doc.exists && doc.data() != null) {
          final userData = doc.data() as Map<String, dynamic>;
          
          setState(() {
            // سحب معرف الطبيب الصحيح المثبت في الفايربيس
            doctorUid = userData['doctorId']; 
            _isLoadingDoctor = false;
          });
          
          debugPrint("=== SUCCESS: تم جلب معرف الطبيب الصحيح بنجاح: $doctorUid ===");
        } else {
          if (mounted) {
            setState(() {
              _isLoadingDoctor = false;
            });
          }
        }
      } catch (e) {
        debugPrint("❌ حدث خطأ أثناء جلب معطيات الداشبورد: $e");
        if (mounted) {
          setState(() {
            _isLoadingDoctor = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // تنسيق التاريخ بصيغة الفايربيس القياسية (yyyy-MM-dd)
    String todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), 
      body: Row(
        children: [
          // --- 1. الشريط الجانبي (Sidebar) ---
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "GlucoLink",
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Secrétaire Médicale",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.home_filled, "Accueil", 0),
                _buildMenuItem(Icons.calendar_month_outlined, "Rendez-vous", 1),
                _buildMenuItem(Icons.access_time, "Liste d'Attente", 2),
                _buildMenuItem(Icons.people_outline, "Patients", 3),
                _buildMenuItem(Icons.attach_money, "Facturation", 4),
                _buildMenuItem(Icons.description_outlined, "Certificats", 5),
              ],
            ),
          ),

          // --- 2. المحتوى الرئيسي ---
          Expanded(
            child: _isLoadingDoctor 
              ? const Center(child: CircularProgressIndicator()) 
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Bonjour, Nourhene",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(width: 8),
                          const Text("👋", style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      Text(
                        DateFormat('EEEE d MMMM yyyy', 'fr').format(DateTime.now()), 
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      // كروت العمليات السريعة
                      Row(
                        children: [
                          _buildActionCard("Nouveau\nRendez-vous", "Planifier consultation", Icons.add, const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
                          const SizedBox(width: 24),
                          _buildActionCard("Nouveau\nPatient", "Créer dossier patient", Icons.person_add_alt_1_outlined, const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                          const SizedBox(width: 24),
                          _buildActionCard("Liste d'Attente", "En file d'attente", Icons.access_time, const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // ✨ تحديث الإحصائيات الذكية عبر استماع مباشر من الفايربيس لبيانات الطبيب الحالي
                      if (doctorUid != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('appointments')
                              .where('doctorId', isEqualTo: doctorUid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int totalRdv = 0;
                            int todayRdv = 0;
                            int pendingRdv = 0;

                            if (snapshot.hasData) {
                              var docs = snapshot.data!.docs;
                              totalRdv = docs.length; // الإجمالي المكتشف للطبيب

                              for (var doc in docs) {
                                var data = doc.data() as Map<String, dynamic>;
                                if (data['date'] == todayDateStr) {
                                  todayRdv++; // مواعيد اليوم فقط
                                }
                                if (data['status'] == 'en_attente') {
                                  pendingRdv++; // مواعيد قيد الانتظار
                                }
                              }
                            }

                            return Row(
                              children: [
                                Expanded(child: _buildSmallStat("Aujourd'hui", todayRdv.toString(), "Rendez-vous", const Color(0xFF2563EB))),
                                const SizedBox(width: 15), 
                                Expanded(child: _buildSmallStat("Total", totalRdv.toString(), "Rendez-vous", const Color(0xFF16A34A))),
                                const SizedBox(width: 15),
                                Expanded(child: _buildSmallStat("En Attente", pendingRdv.toString(), "À confirmer", Colors.orange)),
                                const SizedBox(width: 15),
                                Expanded(child: _buildSmallStat("Patients", totalRdv > 0 ? (totalRdv).toString() : "—", "Enregistrés", Colors.purple)),
                              ],
                            );
                          },
                        )
                      else
                        const Center(child: Text("Impossible de charger les statistiques.")),
                        
                      const SizedBox(height: 40),

                      // جدول مواعيد اليوم بعد ربطه بالتصفية المزدوجة الصحيحة
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Rendez-vous d'Aujourd'hui", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                TextButton(
                                  onPressed: () {}, 
                                  child: const Row(
                                    children: [
                                      Text("Voir tout ", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                      Icon(Icons.arrow_forward, size: 16, color: Color(0xFF2563EB)),
                                    ],
                                  )
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            doctorUid == null 
                            ? const Center(child: Text("Erreur de configuration."))
                            : StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('appointments') 
                                    .where('doctorId', isEqualTo: doctorUid) // التصفية بحسب معرّف الطبيب الحقيقي
                                    .where('date', isEqualTo: todayDateStr)  // التصفية بحسب تاريخ اليوم الموحد
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 30),
                                      child: Center(
                                        child: Text(
                                          "Aucun rendez-vous aujourd'hui",
                                          style: TextStyle(color: Colors.grey, fontSize: 15),
                                        ),
                                      ),
                                    );
                                  }

                                  final rdvDocs = snapshot.data!.docs;

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: rdvDocs.length,
                                    itemBuilder: (context, index) {
                                      final rdv = rdvDocs[index].data() as Map<String, dynamic>;
                                      
                                      String patientName = rdv['patientName'] ?? 'Patient';
                                      String heure = rdv['time'] ?? '--:--';
                                      String type = rdv['type'] ?? 'Consultation';
                                      String status = rdv['status'] ?? 'en_attente';

                                      Color statusColor = Colors.orange;
                                      String cleanStatus = status.toLowerCase().trim();
                                      
                                      if (cleanStatus == 'confirme' || cleanStatus == 'confirmé' || cleanStatus == 'terminé') {
                                        statusColor = Colors.green;
                                      } else if (cleanStatus == 'annulé' || cleanStatus == 'annule') {
                                        statusColor = Colors.red;
                                      }

                                      return _buildPatientRow(patientName, "$heure - $type", status, statusColor);
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // الدوال المساعدة للواجهة
  Widget _buildMenuItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String sub, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)), 
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPatientRow(String name, String time, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}