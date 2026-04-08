import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class PatientProfilePage extends StatefulWidget {
  final String patientId;
  const PatientProfilePage({super.key, required this.patientId});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // دالة لجلب الأيقونة واللون بناءً على نوع القياس
  Map<String, dynamic> _getStyle(String type) {
    if (type.contains("سكر")) {
      return {"icon": Icons.bloodtype, "color": Colors.redAccent, "bg": Colors.red[50]};
    } else if (type.contains("ضغط")) {
      return {"icon": Icons.favorite, "color": Colors.purple, "bg": Colors.purple[50]};
    } else if (type.contains("زيارة")) {
      return {"icon": Icons.local_hospital, "color": Colors.teal, "bg": Colors.teal[50]};
    }
    return {"icon": Icons.straighten, "color": Colors.blueGrey, "bg": Colors.blueGrey[50]};
  }

  int _calculateAge(String? birthDateStr) {
    if (birthDateStr == null || birthDateStr.isEmpty) return 0;
    try {
      DateFormat format = DateFormat("d/M/yyyy");
      DateTime birthDate = format.parse(birthDateStr);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
      return age < 0 ? 0 : age;
    } catch (e) { return 0; }
  }

  Map<String, dynamic> _performSmartDiagnosis(List<Map<dynamic, dynamic>> records) {
    if (records.isEmpty) return {"text": "لا توجد بيانات", "color": Colors.grey};
    try {
      final lastMedical = records.firstWhere(
        (r) => (r['type']?.toString().contains("سكر") ?? false) || (r['type']?.toString().contains("ضغط") ?? false),
        orElse: () => {},
      );
      if (lastMedical.isEmpty) return {"text": "مستقرة", "color": Colors.green};
      double val = double.tryParse(lastMedical['value']?.toString().split(' ')[0] ?? '0') ?? 0;
      String type = lastMedical['type']?.toString() ?? "";
      if (type.contains("سكر")) {
        if (val > 140) return {"text": "مرتفعة", "color": Colors.orange};
        if (val < 70) return {"text": "منخفضة", "color": Colors.blue};
      }
    } catch (e) { return {"text": "تحليل البيانات...", "color": Colors.blueGrey}; }
    return {"text": "مستقرة", "color": Colors.green};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F9), // خلفية أهدأ قليلاً
      appBar: AppBar(
        title: const Text("الملف الطبي الذكي", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: _rootRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("لا توجد بيانات"));

          final allData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final userData = allData['users']?[widget.patientId] ?? {};
          
          List<Map<dynamic, dynamic>> allRecords = [];
          if (allData['measurements']?[widget.patientId] != null) {
            Map mData = allData['measurements'][widget.patientId];
            mData.forEach((k, v) => allRecords.add(Map<dynamic, dynamic>.from(v)));
            allRecords.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
          }

          final measurements = allRecords.where((r) => r['type'] != "زيارة عيادة").toList();
          final visits = allRecords.where((r) => r['type'] == "زيارة عيادة").toList();

          int age = _calculateAge(userData['birth_date']);
          var diag = _performSmartDiagnosis(measurements);
          String lastVisit = visits.isNotEmpty ? visits.first['date'] : "لا يوجد";

          return Column(
            children: [
              _buildHeader(userData, age, diag, lastVisit),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEnhancedList(measurements),
                    _buildEnhancedList(visits, isVisit: true),
                    _buildNotesTab(userData['notes'] ?? 'لا توجد ملاحظات طبية حالياً'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }

  // تصميم الهيدر الجديد
  Widget _buildHeader(Map user, int age, Map diag, String lastVisit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20, top: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1A237E),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Text(user['first_name']?[0] ?? "P", style: const TextStyle(fontSize: 24, color: Colors.white)),
            ),
            title: Text("${user['first_name'] ?? ''} ${user['last_name'] ?? ''}", 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: Text("آخر زيارة: $lastVisit", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            trailing: _statusBadge(diag['text'], diag['color']),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoItem("العمر", "$age سنة", Icons.calendar_today),
                _infoItem("الزمرة", user['blood_type'] ?? "N/A", Icons.water_drop),
                _infoItem("الجنس", user['gender'] ?? "أنثى", Icons.person),
              ],
            ),
          )
        ],
      ),
    );
  }

  // قائمة القياسات والزيارات بشكل مطور (بطاقات احترافية مع شريط جانبي)
  Widget _buildEnhancedList(List list, {bool isVisit = false}) {
    if (list.isEmpty) return const Center(child: Text("لا توجد سجلات مسجلة"));
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final style = _getStyle(list[i]['type'] ?? "");
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // الشريط الملون الجانبي
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: style['color'],
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                  ),
                ),
                const SizedBox(width: 15),
                // الأيقونة الدائرية
                CircleAvatar(
                  backgroundColor: style['bg'],
                  child: Icon(style['icon'], color: style['color'], size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(list[i]['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(list[i]['date'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    list[i]['value'] ?? '',
                    style: TextStyle(color: style['color'], fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // نافذة الإضافة المحدثة
  void _showAddEntryDialog() {
    final controller = TextEditingController();
    String type = "قياس السكر";
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("إضافة سجل جديد", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: ["قياس السكر", "قياس الضغط", "زيارة عيادة"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => type = v!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              if (type == "زيارة عيادة")
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
                    child: Row(children: [const Icon(Icons.calendar_month, color: Colors.blue), const SizedBox(width: 10), Text(DateFormat('yyyy-MM-dd').format(selectedDate))]),
                  ),
                )
              else
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: "القيمة المكتشفة",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                _rootRef.child('measurements/${widget.patientId}').push().set({
                  'type': type,
                  'value': type == "زيارة عيادة" ? "تمت" : controller.text,
                  'timestamp': ServerValue.timestamp,
                  'date': type == "زيارة عيادة" ? DateFormat('yyyy-MM-dd').format(selectedDate) : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                });
                Navigator.pop(context);
              },
              child: const Text("حفظ السجل", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // عناصر مساعدة
  Widget _buildTabBar() => TabBar(
    controller: _tabController,
    labelColor: const Color(0xFF1A237E),
    indicatorColor: const Color(0xFF1A237E),
    indicatorWeight: 3,
    tabs: const [Tab(text: "القياسات"), Tab(text: "الأجندة"), Tab(text: "ملاحظات")],
  );

  Widget _buildNotesTab(String n) => Container(
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: SingleChildScrollView(child: Text(n, style: const TextStyle(fontSize: 16, height: 1.5))),
  );

  Widget _infoItem(String l, String v, IconData icon) => Column(
    children: [
      Icon(icon, color: Colors.white60, size: 18),
      const SizedBox(height: 5),
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    ],
  );

  Widget _statusBadge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: c, width: 1)),
    child: Text(t, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
  );
}