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
            onPressed: () => _registerNurse(emailController.text, passController.text, nameController.text),
            child: const Text("Create Nurse Account", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // دالة تسجيل الممرضة في Firebase
  Future<void> _registerNurse(String email, String password, String name) async {
    try {
      // 1. إنشاء الحساب في Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. تخزين البيانات في Firestore مع تحديد الـ Role كممرضة
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'nurse', // تحديد دور الممرضة
        'doctorId': FirebaseAuth.instance.currentUser!.uid, // ربطها بهذا الطبيب
        'specialty': 'Nurse Assistant',
        'uid': userCredential.user!.uid,
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nurse account created successfully!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}