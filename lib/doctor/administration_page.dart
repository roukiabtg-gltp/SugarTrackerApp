import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdministrationPage extends StatefulWidget {
  const AdministrationPage({super.key});

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  String activeSubSection = "Staff"; // القسم الافتراضي

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Administration", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // القائمة الفرعية اليسرى (Sub-Sidebar)
                  _buildSubSidebar(),
                  const SizedBox(width: 32),
                  // المحتوى المتغير (Dynamic Content)
                  Expanded(child: _buildMainContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSidebar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildSubMenuItem("Create Patient", "Patient"),
          _buildSubMenuItem("Manage Data", "Data"),
          _buildSubMenuItem("Staff Management", "Staff"), // الممرضة هنا
          _buildSubMenuItem("Certificates", "Certificates"),
        ],
      ),
    );
  }

  Widget _buildSubMenuItem(String title, String section) {
    bool isActive = activeSubSection == section;
    return ListTile(
      title: Text(title, style: TextStyle(color: isActive ? Colors.blue : Colors.grey[600], fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      onTap: () => setState(() => activeSubSection = section),
      selected: isActive,
      selectedTileColor: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildMainContent() {
    if (activeSubSection == "Staff") {
      return _buildStaffSection();
    }
    return Center(child: Text("Section: $activeSubSection Coming Soon"));
  }

  // --- واجهة إضافة ممرضة جديدة ---
  Widget _buildStaffSection() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController passController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Generate Staff Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Create credentials for your nurse or assistant.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: emailController, decoration: const InputDecoration(labelText: "Nurse Email", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: passController, decoration: const InputDecoration(labelText: "Initial Password", border: OutlineInputBorder())),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            onPressed: () async {
              try {
                // 1. الحصول على ID الطبيب الحالي أوتوماتيكياً
                String currentDoctorId = FirebaseAuth.instance.currentUser!.uid;

                // 2. إنشاء الحساب في Authentication (يؤدي لإنشاء UID جديد للسكرتيرة)
                UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passController.text.trim(),
                );

                // 3. تخزين البيانات في Firestore مع الربط الصحيح
                await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
                  'uid': result.user!.uid,           // هذا الـ UID الخاص بنورين (تلقائي)
                  'doctorId': currentDoctorId,       // هذا الـ UID الخاص بالطبيب (تلقائي)
                  'name': nameController.text,
                  'email': emailController.text,
                  'role': 'nurse',                   // تحديد رتبتها كممرضة/سكرتيرة
                  'specialty': 'Nurse Assistant',
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إنشاء حساب السكرتيرة وربطها بك بنجاح!')),
                );
              } catch (e) {
                print("Error: $e");
              }
            },
            child: const Text("Create Nurse Account", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}