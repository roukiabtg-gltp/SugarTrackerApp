import 'package:flutter/material.dart';


class CertificatsPage extends StatelessWidget {
  const CertificatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFFF8F9FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الرأس: العنوان وزر إضافة شهادة جديدة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gestion des Certificats",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const Text(
                    "Tous les certificats médicaux",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // أكشن لإضافة شهادة
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Nouveau Certificat",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),

          // الحاوية البيضاء المركزية (حالة الصفحة الفارغة)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة الشهادة الرمادية
                  Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  
                  // نص "لا توجد شهادات"
                  Text(
                    "Aucun certificat enregistré",
                    style: const TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // رابط "إنشاء أول شهادة"
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Créer le premier certificat",
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
}