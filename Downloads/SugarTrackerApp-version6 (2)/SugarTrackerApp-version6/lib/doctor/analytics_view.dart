import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsView extends StatefulWidget {
  final Map measurements;
  const AnalyticsView({super.key, required this.measurements});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String _selectedPeriod = '7 DAYS';
  bool _isChartView = true; 

  // دالة التصفية الذكية والمطورة للتعرف على النصوص العربية وقراءة التواريخ النصية
  List<MapEntry> _getCleanedData() {
    if (widget.measurements.isEmpty) return [];

    var entries = widget.measurements.entries.where((e) {
      String type = (e.value['type'] ?? e.value['category'] ?? "").toString().toLowerCase();
      
      // استبعاد سجلات الزيارات
      if (type.contains("زيارة")) return false;
      
      // التحقق من القيمة برمجياً وعيادياً
      double? val = double.tryParse(e.value['value']?.toString() ?? "");
      if (val != null) {
        // فحص شامل لكل صيغ كلمة سكر (سكر، السكر، glucose، اكل)
        if (type.contains("glucose") || type.contains("سكر") || type.contains("أكل") || type.contains("السكر")) {
          if (val <= 0 || val > 1000) return false; 
        }
      }
      return true;
    }).toList();

    // ترتيب السجلات زمنياً من الأقدم إلى الأحدث للرسم البياني
    entries.sort((a, b) {
      int getMs(dynamic t) {
        if (t == null) return 0;
        if (t is int) return t;
        // محاولة تحويل التاريخ النصي "2026-05-22" إلى Milliseconds
        return DateTime.tryParse(t.toString())?.millisecondsSinceEpoch ?? int.tryParse(t.toString()) ?? 0;
      }
      dynamic ta = a.value['timestamp'] ?? a.value['date'];
      dynamic tb = b.value['timestamp'] ?? b.value['date'];
      return getMs(ta).compareTo(getMs(tb));
    });

    // الفلترة بناءً على المدة الزمنية المختارة
    DateTime now = DateTime.now();
    int days = _selectedPeriod == '7 DAYS' ? 7 : _selectedPeriod == '30 DAYS' ? 30 : 90;
    DateTime startDate = now.subtract(Duration(days: days));

    return entries.where((e) {
      dynamic ts = e.value['timestamp'] ?? e.value['date'];
      DateTime dt;
      if (ts is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(ts > 9999999999 ? ts : ts * 1000);
      } else {
        dt = DateTime.tryParse(ts?.toString() ?? "") ?? now;
      }
      return dt.isAfter(startDate);
    }).toList();
  }

 String getStatus(double value, String timing) {
  if (timing == "Fasting") {
    if (value < 0.7) return "Low";
    if (value >= 0.7 && value <= 1.1) return "Normal";
    return "Warning"; // أكبر من 1.1 صايم
  } else { // After Meal مثلاً
    if (value < 0.7) return "Low";
    if (value < 1.4) return "Normal";
    return "Warning"; // أكبر من 1.4 فاطر
  }
}

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Critical': return const Color(0xFFE11D48); 
      case 'Warning': return const Color(0xFFD97706); 
      default: return const Color(0xFF16A34A); 
    }
  }

  String _formatDate(dynamic raw) {
    try {
      if (raw == null) return "--";
      DateTime dt = raw is int 
          ? DateTime.fromMillisecondsSinceEpoch(raw > 9999999999 ? raw : raw * 1000)
          : DateTime.parse(raw.toString());
      return DateFormat('MM-dd HH:mm').format(dt);
    } catch (_) {
      String s = raw.toString();
      return s.length > 10 ? s.substring(5, 16) : s; // عرض الشهر واليوم والوقت المتاح
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanedData = _getCleanedData();

    double total = 0, maxVal = 0, minVal = 9999;
    for (var e in cleanedData) {
      double val = double.tryParse(e.value['value']?.toString() ?? "0") ?? 0;
      total += val;
      if (val > maxVal) maxVal = val;
      if (val < minVal) minVal = val;
    }
    double avgVal = cleanedData.isNotEmpty ? total / cleanedData.length : 0;
    if (minVal == 9999) minVal = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: ['7 DAYS', '30 DAYS', '90 DAYS'].map((period) {
                  bool isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF3B82F6),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (val) => setState(() => _selectedPeriod = period),
                    ),
                  );
                }).toList(),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _toggleButton(icon: Icons.show_chart, isChart: true),
                    _toggleButton(icon: Icons.grid_on, isChart: false),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              _statCard("Average Level", "${avgVal.toStringAsFixed(1)} mg/dL", Colors.blue.shade50, Colors.blue),
              const SizedBox(width: 12),
              _statCard("Highest (Max)", "${maxVal.toStringAsFixed(0)} mg/dL", Colors.red.shade50, Colors.red),
              const SizedBox(width: 12),
              _statCard("Lowest (Min)", "${minVal.toStringAsFixed(0)} mg/dL", Colors.green.shade50, Colors.green),
            ],
          ),
          const SizedBox(height: 32),

          if (cleanedData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Text("No real clinical data available for this period", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isChartView 
                  ? _buildLineChart(cleanedData) 
                  : _buildDataTable(cleanedData),
            ),
        ],
      ),
    );
  }

  Widget _toggleButton({required IconData icon, required bool isChart}) {
    bool isActive = _isChartView == isChart;
    return GestureDetector(
      onTap: () => setState(() => _isChartView = isChart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Icon(icon, size: 18, color: isActive ? const Color(0xFF3B82F6) : Colors.grey),
      ),
    );
  }

  Widget _statCard(String title, String val, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: textCol.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(val, style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<MapEntry> cleanedData) {
    List<FlSpot> spots = [];
    for (int i = 0; i < cleanedData.length; i++) {
      double y = double.tryParse(cleanedData[i].value['value']?.toString() ?? "0") ?? 0;
      spots.add(FlSpot(i.toDouble(), y));
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (spots.length / 5).clamp(1, 99).toDouble(),
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < cleanedData.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(_formatDate(cleanedData[index].value['timestamp'] ?? cleanedData[index].value['date']),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text("${value.toInt()}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: const Color(0xFF3B82F6),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF3B82F6).withOpacity(0.06),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  String status = getStatus(spot.y, "Fasting"); // أو "After Meal" حسب نوع القياس
                  return FlDotCirclePainter(
                    color: _getStatusColor(status),
                    radius: 4,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<MapEntry> cleanedData) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          dataRowHeight: 52,
          columns: const [
            DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ],
          rows: cleanedData.reversed.map((entry) {
            double val = double.tryParse(entry.value['value']?.toString() ?? "0") ?? 0;
            String status = getStatus(val, entry.value['timing'] ?? "Fasting");
            Color statusColor = _getStatusColor(status);

            return DataRow(cells: [
              DataCell(Text(_formatDate(entry.value['timestamp'] ?? entry.value['date']), style: const TextStyle(fontSize: 13))),
              DataCell(Text(entry.value['type'] ?? entry.value['category'] ?? "Glucose", style: const TextStyle(fontSize: 13))),
              DataCell(Text("$val ${entry.value['unit'] ?? 'mg/dL'}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}