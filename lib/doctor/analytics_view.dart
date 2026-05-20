import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsView extends StatefulWidget {
  final Map<dynamic, dynamic> measurements;
  const AnalyticsView({super.key, required this.measurements});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String _selectedFilter = '7 DAYS';

  // 1. منطق الفلترة بناءً على الوقت
  List<MapEntry> _getFilteredData() {
    final now = DateTime.now();
    DateTime threshold;

    if (_selectedFilter == '24 HOURS') {
      threshold = now.subtract(const Duration(hours: 24));
    } else if (_selectedFilter == '7 DAYS') {
      threshold = now.subtract(const Duration(days: 7));
    } else {
      threshold = now.subtract(const Duration(days: 30));
    }

    return widget.measurements.entries.where((entry) {
      final date = DateTime.tryParse(entry.value['date'] ?? "");
      return date != null && date.isAfter(threshold);
    }).toList()..sort((a, b) => a.value['date'].compareTo(b.value['date']));
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    
    // تحويل البيانات لنقاط الرسم البياني
    List<FlSpot> spots = _convertToSpots(filteredData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildLegend(),
          const SizedBox(height: 40),
          SizedBox(
            height: 400,
            child: _buildMainChart(spots),
          ),
        ],
      ),
    );
  }

  // تصميم الهيدر والأزرار (كما في image_126095.png)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Weekly Glucose Trends", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D4059))),
            Text("Last ${_selectedFilter.toLowerCase()} glucose monitoring", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        _buildFilterToggle(),
      ],
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
      child: Row(
        children: ['24 HOURS', '7 DAYS', '30 DAYS'].map((f) {
          bool isSel = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isSel ? const Color(0xFFF1F1F1) : Colors.white,
              child: Text(f, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(Colors.blue, "Average"),
        const SizedBox(width: 20),
        _dot(Colors.green, "Minimum", dashed: true),
        const SizedBox(width: 20),
        _dot(Colors.red, "Maximum", dashed: true),
      ],
    );
  }

  Widget _dot(Color c, String t, {bool dashed = false}) {
    return Row(children: [
      Container(width: 15, height: 2, color: c),
      const SizedBox(width: 5),
      Text(t, style: const TextStyle(fontSize: 12, color: Colors.grey))
    ]);
  }

  // تجميع القياسات حسب اليوم أو الساعة وحساب المتوسط
  List<FlSpot> _convertToSpots(List<MapEntry> entries) {
    if (entries.isEmpty) return [];

    // إذا كان الفلتر أسبوعي، نجمع متوسط كل يوم
    Map<int, List<double>> dailyValues = {};
    
    for (var entry in entries) {
      DateTime date = DateTime.parse(entry.value['date']);
      double val = double.parse(entry.value['value'].toString());
      
      int key = (_selectedFilter == '24 HOURS') ? date.hour : date.weekday - 1;
      
      dailyValues.putIfAbsent(key, () => []).add(val);
    }

    return dailyValues.entries.map((e) {
      double avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return FlSpot(e.key.toDouble(), avg);
    }).toList()..sort((a, b) => a.x.compareTo(b.x));
  }

  // رسم البياني الاحترافي (كما في image_12609c.png)
  Widget _buildMainChart(List<FlSpot> spots) {
    if (spots.isEmpty) return const Center(child: Text("No data available for this period"));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: _selectedFilter == '24 HOURS' ? 23 : 6,
        minY: 0,
        maxY: 250,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) => Colors.white,
            tooltipBorder: const BorderSide(color: Color(0xFF007BFF)),
          )
        ),
        gridData: FlGridData(show: true, horizontalInterval: 65, drawVerticalLine: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (_selectedFilter == '24 HOURS') {
                  return Text('${value.toInt()}:00', style: const TextStyle(fontSize: 10));
                } else {
                  List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 10));
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 50,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[200]!)),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: const Color(0xFF007BFF), barWidth: 3, dotData: const FlDotData(show: true)),
          LineChartBarData(spots: spots.map((s) => FlSpot(s.x, s.y + 20)).toList(), isCurved: true, color: Colors.red.withOpacity(0.3), dashArray: [5, 5], dotData: const FlDotData(show: false)),
          LineChartBarData(spots: spots.map((s) => FlSpot(s.x, s.y - 15)).toList(), isCurved: true, color: Colors.green.withOpacity(0.3), dashArray: [5, 5], dotData: const FlDotData(show: false)),
        ],
      ),
    );
  }
}