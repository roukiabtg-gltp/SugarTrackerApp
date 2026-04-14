import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
// تأكدي من استيراد ملف البروفايل الذي أنشأتِه
import 'patient_profile_page.dart'; 

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('users');
  final String? doctorId = FirebaseAuth.instance.currentUser?.uid;
  
  String searchQuery = "";
  String selectedStatus = "All Status";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان وزر الإضافة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Patients",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
                _buildAddPatientButton(),
              ],
            ),
            const SizedBox(height: 25),

            // شريط البحث والفلاتر
            _buildFilterBar(),

            const SizedBox(height: 25),

            // الجدول الاحترافي
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    const Divider(height: 1),
                    Expanded(child: _buildPatientsList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت شريط الفلترة المنظم
  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              decoration: const InputDecoration(
                hintText: "Search patients...",
                icon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        _buildStatusDropdown(),
        const SizedBox(width: 15),
        _buildFilterIconButton(),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          items: ["All Status", "Critical", "Normal", "Warning"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (val) => setState(() => selectedStatus = val!),
        ),
      ),
    );
  }

  Widget _buildFilterIconButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.filter_list, color: Colors.black87, size: 20),
      label: const Text("Filters", style: TextStyle(color: Colors.black87)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildAddPatientButton() {
    return ElevatedButton.icon(
      onPressed: () { /* كود إضافة مريض */ },
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text("Add Patient", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("Patient Name", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text("Age", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text("Status", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text("Value", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text("Actions", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return StreamBuilder(
      stream: _dbRef.orderByChild('doctorId').equalTo(doctorId).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("No patients found"));

        Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        List<Map> patients = [];
        values.forEach((key, value) {
          String firstName = value['first_name'] ?? "";
          String lastName = value['last_name'] ?? "";
          String fullName = "$firstName $lastName".trim();
          
          double glucose = double.tryParse(value['glucoseLevel']?.toString() ?? "0") ?? 0.0;
          String status = (glucose > 180 || (glucose < 70 && glucose > 0)) ? "Critical" : "Normal";

          if (fullName.toLowerCase().contains(searchQuery) && 
             (selectedStatus == "All Status" || status == selectedStatus)) {
            patients.add({"id": key, ...value, "status": status, "fullName": fullName});
          }
        });

        return ListView.separated(
          itemCount: patients.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F1F1)),
          itemBuilder: (context, index) => _buildPatientRow(patients[index]),
        );
      },
    );
  }

  Widget _buildPatientRow(Map p) {
    Color statusColor = p['status'] == "Critical" ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(p['fullName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          Expanded(flex: 1, child: Text("${p['age'] ?? '--'}", textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(p['status'].toLowerCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(flex: 2, child: Text("${p['glucoseLevel'] ?? '0'} mg/dL", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
              onPressed: () {
                // الانتقال لصفحة البروفايل مع تمرير البيانات
                Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PatientProfilePage(
      patientId: p['id'],      // إرسال الـ ID
      patientName: p['fullName'], // إرسال الاسم (هذا هو البارامتر الذي كان يسبب الخطأ)
    ),
  ),
);
              },
            ),
          ),
        ],
      ),
    );
  }
}