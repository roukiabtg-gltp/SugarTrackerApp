import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientProfilePage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientProfilePage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  // مرجع لقاعدة البيانات Realtime Database
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Back to Patients", style: TextStyle(color: Colors.grey, fontSize: 16)),
      ),
      body: StreamBuilder(
        // جلب بيانات المريض الشخصية من مسار users
        stream: _dbRef.child('users').child(widget.patientId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          Map<dynamic, dynamic>? patientData;
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            patientData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          }

          // استخراج البيانات الحقيقية من Firebase
          String firstName = patientData?['first_name'] ?? "";
          String lastName = patientData?['last_name'] ?? "";
          // إذا كان الاسم فارغاً في الداتابيز، نستخدم الاسم الذي وصل من الصفحة السابقة
          String fullName = (firstName.isEmpty && lastName.isEmpty) ? widget.patientName : "$firstName $lastName";
          String birthDate = patientData?['birth_date'] ?? "Not Recorded";
          String email = patientData?['email'] ?? "No Email";
          String gender = patientData?['gender'] ?? "Not Recorded";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // كرت معلومات المريض العلوي (الآن يعرض البيانات الحقيقية)
                _buildPatientHeaderCard(fullName, birthDate, email, gender),
                const SizedBox(height: 24),
                
                // تنبيه الحالات الحرجة 
                _buildCriticalAlertBanner(),
                const SizedBox(height: 24),

                // قسم التبويبات والقياسات الحقيقية (تم تعديل التبويبات هنا)
                _buildMainContentSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientHeaderCard(String name, String birth, String mail, String sex) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFFE3F2FD),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "P",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
                const SizedBox(height: 12),
                Text("Birth Date: $birth  •  Gender: $sex", style: const TextStyle(color: Colors.grey, fontSize: 15)),
                const SizedBox(height: 8),
                Text("📧 $mail", style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          Column(
            children: [
              OutlinedButton(onPressed: () {}, child: const Text("Edit Profile")),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("Schedule Appointment", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Latest Status Update", style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text("Check recent glucose measurements below for patient health tracking.", style: TextStyle(color: Color(0xFFC62828))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // شريط التبويبات المعدل ليصبح مثل الصورة (خط بسيط تحت الكلمة)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: const Row(
              children: [
                _TabItem(title: "Measurements", isActive: true),
                _TabItem(title: "Analytics"),
                _TabItem(title: "Prescriptions"),
                _TabItem(title: "Notes"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Recent Measurements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                StreamBuilder(
                  stream: _dbRef.child('measurements').child(widget.patientId).onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No measurements recorded yet."),
                      ));
                    }

                    Map<dynamic, dynamic> measurements = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    List<MapEntry<dynamic, dynamic>> sortedList = measurements.entries.toList()
                      ..sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

                    return Table(
                      columnWidths: const {0: FlexColumnWidth(2.5), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5)},
                      children: [
                        _buildTableRowHeader(),
                        ...sortedList.map((entry) {
                          var m = entry.value;
                          return _buildDataRow(
                            m['date']?.toString().split('T').first ?? "", 
                            m['category'] ?? "Glucose", 
                            "${m['value'] ?? ""} mg/dL", 
                            "normal"
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRowHeader() {
    return const TableRow(
      children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Date", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Category", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Value", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
      ],
    );
  }

  TableRow _buildDataRow(String date, String type, String value, String status) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(date)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(type)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
      ],
    );
  }
}

// تعديل تصميم الـ TabItem ليكون خط بسيط
class _TabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  const _TabItem({required this.title, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 30),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: isActive ? const Border(bottom: BorderSide(color: Colors.blue, width: 2.5)) : null,
      ),
      child: Text(
        title, 
        style: TextStyle(
          color: isActive ? Colors.blue : Colors.grey, 
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        )
      ),
    );
  }
}