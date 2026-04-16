import 'package:flutter/material.dart';


class WaitingListPage extends StatelessWidget {
  const WaitingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFFF8F9FB), // الخلفية الرمادية الفاتحة
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان العلوي
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Liste d'Attente",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Text(
                "Patients en attente aujourd'hui",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // الحاوية البيضاء الرئيسية التي تحتوي على القائمة
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شريط المعلومات العلوي (عدد المرضى)
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled,
                          color: Color(0xFF2563EB), size: 28),
                      const SizedBox(width: 12),
                      Text(
                        "3 patient(s) en attente",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // قائمة المرضى (ListView)
                  Expanded(
                    child: ListView(
                      children: [
                        _buildWaitingItem(
                          time: "09:00",
                          name: "Marie Dubois",
                          type: "Consultation",
                          status: "Confirmé",
                          statusColor: Colors.green,
                        ),
                        _buildWaitingItem(
                          time: "10:00",
                          name: "Jean Martin",
                          type: "Controle",
                          status: "En attente",
                          statusColor: Colors.orange,
                        ),
                        _buildWaitingItem(
                          time: "11:00",
                          name: "Sophie Bernard",
                          type: "Consultation",
                          status: "Confirmé",
                          statusColor: Colors.green,
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

  // دالة بناء عنصر المريض الواحد (السطر)
  Widget _buildWaitingItem({
    required String time,
    required String name,
    required String type,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // الوقت بخط أزرق وعريض
          Text(
            time,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 35),

          // المعلومات الشخصية
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          // كبسولة الحالة (Status Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 25),

          // زر التحديد (Terminé) الأخضر
          ElevatedButton.icon(
            onPressed: () {
              // الأكشن هنا عند الضغط
            },
            icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
            label: const Text(
              "Terminé",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A), // أخضر غامق احترافي
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}