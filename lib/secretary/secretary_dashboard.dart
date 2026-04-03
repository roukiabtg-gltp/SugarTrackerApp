import 'package:flutter/material.dart';

class SecretaryDashboard extends StatelessWidget {
  const SecretaryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Secrétaire"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 100, color: Color(0xFF1A237E)),
            SizedBox(height: 20),
            Text("Gestion المواعيد والانتظار", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("قيد التطوير..."),
          ],
        ),
      ),
    );
  }
}