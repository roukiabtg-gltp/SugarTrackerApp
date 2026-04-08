import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // 🔹 إضافة مريض (نافذة محسنة)
  void _showAddPatientDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("إضافة مريض جديد", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPopupField(firstNameController, "الاسم الأول", Icons.person_outline),
              const SizedBox(height: 10),
              _buildPopupField(lastNameController, "اللقب", Icons.family_restroom),
              const SizedBox(height: 10),
              _buildPopupField(emailController, "البريد الإلكتروني", Icons.email_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (firstNameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                _addNewPatient(firstNameController.text, lastNameController.text, emailController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("حفظ المريض", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  void _addNewPatient(String fName, String lName, String email) {
    _dbRef.push().set({
      'first_name': fName,
      'last_name': lName,
      'email': email,
      'doctorId': doctorId,
      'status': 'active'
    });
  }

  void _deletePatient(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من إزالة هذا المريض من قائمتك؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("تراجع")),
          TextButton(onPressed: () { _dbRef.child(id).remove(); Navigator.pop(context); }, child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatientDialog,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("دليل المرضى", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 5),
            Text("إدارة ومتابعة مرضى العيادة", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 25),
            
            // 🔍 Search Bar المحسن
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: "ابحث باسم المريض أو البريد الإلكتروني...",
                  prefixIcon: Icon(Icons.search, color: Color(0xFF1A237E)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 25),

            Expanded(
              child: StreamBuilder(
                stream: _dbRef.orderByChild('doctorId').equalTo(doctorId).onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
                        const Text("لا يوجد مرضى مضافين بعد", style: TextStyle(color: Colors.grey)),
                      ],
                    ));
                  }

                  Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<Map<dynamic, dynamic>> patients = [];

                  values.forEach((key, value) {
                    String fullName = "${value['first_name'] ?? ""} ${value['last_name'] ?? ""}".trim();
                    if (fullName.isEmpty) fullName = "اسم مجهول";

                    if (fullName.toLowerCase().contains(searchQuery) || (value['email'] ?? "").toLowerCase().contains(searchQuery)) {
                      patients.add({"id": key, "name": fullName, "email": value['email'] ?? "N/A", "status": value['status'] ?? "inactive"});
                    }
                  });

                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final p = patients[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                              child: Text(p['name'][0].toUpperCase(), style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(p['email'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                            _buildStatusBadge(p['status']),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.blue),
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PatientProfilePage(patientId: p['id']))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => _deletePatient(p['id']),
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

  Widget _buildStatusBadge(String status) {
    bool isActive = status == "active";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? "نشط" : "خامل",
        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}