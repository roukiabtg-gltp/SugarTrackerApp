import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../doctor_settings_notifier.dart';

class AnalyticsView extends StatefulWidget {
  final String patientId;
  final String patientName;

  const AnalyticsView({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String _selectedFilter = 'all'; // الفلتر الافتراضي: الكل
  bool _showChart = true;

  // دوال فحص القيم وتحويلها بأمان كما يفعل تطبيق المريض
  double _parseValue(dynamic rawValue) {
    if (rawValue == null) return 0.0;
    if (rawValue is num) return rawValue.toDouble();
    try {
      String cleanStr = rawValue.toString().trim();
      cleanStr = cleanStr.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanStr) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(raw > 9999999999 ? raw : raw * 1000);
      }
      int? ms = int.tryParse(raw.toString());
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms > 9999999999 ? ms : ms * 1000);
      }
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String unit = "mg/dL";

    final texts = {
      'avg': t('Average','المتوسط','Moyenne'),
      'max': t('Max','أعلى قياس','Maximum'),
      'min': t('Min','أقل قياس','Minimum'),
      'total': t('Total','الإجمالي','Total'),
      'empty': t('No data available for this period','لا توجد بيانات لهذه الفترة','Aucune donnée pour cette période'),
      'day': t('Day','يوم','Jour'),
      'week': t('Week','أسبوع','Semaine'),
      'month': t('Month','شهر','Mois'),
      'all': t('All','الكل','Tout'),
    };

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref("measurements/${widget.patientId}").onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _buildEmptyState(texts['empty']!);
        }

        Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
        
        // تحويل كافة البيانات المتاحة إلى قائمة مجهزة بالتواريخ أولاً لضمان دقة الفلترة
        List<MapEntry<dynamic, dynamic>> allEntries = data.entries.toList();
        List<Map<String, dynamic>> parsedEntries = [];

        for (var entry in allEntries) {
          if (entry.value == null) continue;
          final dateRaw = entry.value['timestamp'] ?? entry.value['date'] ?? entry.value['dateTime'] ?? entry.value['time'];
          DateTime? recordDate = _parseDate(dateRaw);
          if (recordDate != null) {
            parsedEntries.add({
              'entry': entry,
              'date': recordDate,
            });
          }
        }

        if (parsedEntries.isEmpty) return _buildEmptyState(texts['empty']!);

        // ترتيب البيانات زمنياً من الأقدم للأحدث
        parsedEntries.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        // تحديد نقطة المرجعية الزمنية (تاريخ آخر قياس فعلي متوفر في حساب المريض بدلاً من تاريخ اليوم الحالي الصارم)
        DateTime referenceDate = parsedEntries.last['date'] as DateTime;

        // تصفية البيانات برمجياً بناءً على الفلتر المختار
        var filteredList = parsedEntries.where((item) {
          DateTime itemDate = item['date'] as DateTime;

          if (_selectedFilter == 'day') {
            // نفس اليوم الخاص بآخر قياس تم تسجيله
            return itemDate.year == referenceDate.year && 
                   itemDate.month == referenceDate.month && 
                   itemDate.day == referenceDate.day;
          } else if (_selectedFilter == 'week') {
            // خلال آخر 7 أيام قبل تاريخ آخر قياس
            return itemDate.isAfter(referenceDate.subtract(const Duration(days: 7)));
          } else if (_selectedFilter == 'month') {
            // نفس الشهر والسنة الخاص بآخر قياس
            return itemDate.year == referenceDate.year && 
                   itemDate.month == referenceDate.month;
          }
          return true; // في حال اختيار 'all' يعرض كل البيانات
        }).toList();

        if (filteredList.isEmpty) return _buildEmptyState(texts['empty']!);

        // بناء نقاط الرسم البياني وجدول البيانات من القائمة المصفاة
        List<FlSpot> spots = [];
        List<Map<String, dynamic>> tableData = [];

        for (int i = 0; i < filteredList.length; i++) {
          final v = filteredList[i]['entry'].value;
          double rawVal = _parseValue(v['value'] ?? v['Value']);
          
          // معادلة تحويل القياسات من نظامك
          double displayedVal = rawVal < 5.0 ? rawVal * 100 : rawVal;
          DateTime dt = filteredList[i]['date'] as DateTime;

          spots.add(FlSpot(i.toDouble(), displayedVal));
          tableData.add({'val': displayedVal, 'time': dt.millisecondsSinceEpoch});
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مفاتيح الفلترة العلوية المستقرة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('Patient Analytics','تحليلات المريض','Analytique du patient'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: Icon(_showChart ? Icons.table_chart_rounded : Icons.show_chart_rounded, color: const Color(0xFF2563EB)),
                    onPressed: () => setState(() => _showChart = !_showChart),
                  )
                ],
              ),
              
              const SizedBox(height: 16),

              // شريط الفلاتر الموحد
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _buildFilterButton(texts['day']!, 'day'),
                    _buildFilterButton(texts['week']!, 'week'),
                    _buildFilterButton(texts['month']!, 'month'),
                    _buildFilterButton(texts['all']!, 'all'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // شبكة كروت عرض الإحصائيات (الحساب التلقائي اللحظي المصفى)
              _buildStatsGrid(spots, texts, unit),

              const SizedBox(height: 24),

              // العرض الرسومي أو الجدول البياني بعد الفلترة والتحويل
              _showChart 
                  ? _buildChart(spots, tableData, unit) 
                  : _buildTable(tableData, unit),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(String label, String value) {
    bool isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<FlSpot> spots, Map<String, String> texts, String unit) {
    double sum = spots.map((s) => s.y).reduce((a, b) => a + b);
    double avg = sum / spots.length;
    double maxV = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double minV = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        Row(
          children: [
            _statBox(texts['avg']!, avg.toStringAsFixed(1), unit, const Color(0xFF2563EB)),
            const SizedBox(width: 12),
            _statBox(texts['total']!, spots.length.toString(), "", const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statBox(texts['max']!, maxV.toStringAsFixed(1), unit, const Color(0xFFEF4444)),
            const SizedBox(width: 12),
            _statBox(texts['min']!, minV.toStringAsFixed(1), unit, const Color(0xFF10B981)),
          ],
        ),
      ],
    );
  }

  Widget _statBox(String label, String val, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text("$val $unit".trim(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> spots, List<Map<String, dynamic>> tableData, String unit) {
    final maxValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.white.withOpacity(0.95),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  int index = touchedSpot.x.toInt();
                  if (index >= tableData.length || index < 0) return null;
                  final DateTime date = DateTime.fromMillisecondsSinceEpoch(tableData[index]['time']);
                  final String formattedTime = "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                  return LineTooltipItem(
                    "$formattedTime\n",
                    const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                    children: [
                      TextSpan(
                        text: "${touchedSpot.y.toStringAsFixed(1)} $unit",
                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF2563EB),
              barWidth: 4,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF2563EB),
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(show: true, color: const Color(0xFF2563EB).withOpacity(0.08)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data, String unit) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: DataTable(
        columnSpacing: 20,
        columns: [
          DataColumn(label: Text(t('Date','التاريخ','Date'), style: const TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('${t('Value','القيمة','Valeur')} ($unit)', style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: data.reversed.take(20).map((e) {
          DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['time']);
          String formattedDate = "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
          return DataRow(cells: [
            DataCell(Text(formattedDate)),
            DataCell(Text(e['val'].toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}