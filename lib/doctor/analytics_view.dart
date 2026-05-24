import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
  String selectedFilter = '7 DAYS';
  bool showChart = true;

  final List<String> filters = [
    '24 HOURS',
    '7 DAYS',
    '30 DAYS',
  ];

  // ─────────────────────────────────────────────────────────────
  // REALTIME DATABASE STREAM
  // ─────────────────────────────────────────────────────────────

  Stream<DatabaseEvent> getMeasurementsStream() {
    return FirebaseDatabase.instance
        .ref()
        .child('measurements')
        .child(widget.patientId)
        .onValue;
  }

  // ─────────────────────────────────────────────────────────────
  // DATE PARSER
  // ─────────────────────────────────────────────────────────────

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;

    try {
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          raw > 9999999999 ? raw : raw * 1000,
        );
      }

      int? ms = int.tryParse(raw.toString());

      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          ms > 9999999999 ? ms : ms * 1000,
        );
      }

      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FILTER DATA
  // ─────────────────────────────────────────────────────────────

  List<MapEntry<String, dynamic>> _filterData(
    Map<dynamic, dynamic> raw,
  ) {
    final now = DateTime.now();

    Duration duration;

    switch (selectedFilter) {
      case '24 HOURS':
        duration = const Duration(hours: 24);
        break;

      case '30 DAYS':
        duration = const Duration(days: 30);
        break;

      default:
        duration = const Duration(days: 7);
    }

    final threshold = now.subtract(duration);

    final entries = raw.entries
        .map(
          (e) => MapEntry<String, dynamic>(
            e.key.toString(),
            Map<String, dynamic>.from(
              e.value as Map,
            ),
          ),
        )
        .where((e) {
      final dt = _parseDate(
        e.value['timestamp'] ?? e.value['date'],
      );

      return dt != null && dt.isAfter(threshold);
    }).toList();

    // SORT BY DATE
    entries.sort((a, b) {
      final da = _parseDate(
        a.value['timestamp'] ?? a.value['date'],
      );

      final db = _parseDate(
        b.value['timestamp'] ?? b.value['date'],
      );

      return (da ?? DateTime(0))
          .compareTo(db ?? DateTime(0));
    });

    return entries;
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────

  double _avg(List<double> values) {
    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) /
        values.length;
  }

  double _min(List<double> values) {
    if (values.isEmpty) return 0;

    return values.reduce(
      (a, b) => a < b ? a : b,
    );
  }

  double _max(List<double> values) {
    if (values.isEmpty) return 0;

    return values.reduce(
      (a, b) => a > b ? a : b,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // POINT COLOR
  // ─────────────────────────────────────────────────────────────

  Color _dotColor(double value) {
    if (value < 70) {
      return const Color(0xFF3B82F6);
    }

    if (value > 200) {
      return const Color(0xFFEF4444);
    }

    if (value > 140) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF10B981);
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: getMeasurementsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.snapshot.value == null) {
          return _emptyState(
            "No measurements found",
          );
        }

        final rawMap =
            snapshot.data!.snapshot.value as Map;

        final filtered = _filterData(rawMap);

        final values = filtered
            .map(
              (e) =>
                  double.tryParse(
                    e.value['value']
                            ?.toString() ??
                        '0',
                  ) ??
                  0,
            )
            .toList();

        final average = _avg(values);

        final minimum = _min(values);

        final maximum = _max(values);

        final inRange = values
            .where(
              (v) => v >= 70 && v <= 140,
            )
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ───────────────── HEADER
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        "Patient Analytics",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        widget.patientName,
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      _viewToggleBtn(
                        Icons.show_chart,
                        true,
                        "Chart",
                      ),

                      const SizedBox(width: 10),

                      _viewToggleBtn(
                        Icons.table_chart,
                        false,
                        "Table",
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ───────────────── FILTERS
              Wrap(
                spacing: 10,
                children: filters.map((filter) {
                  final selected =
                      selectedFilter ==
                          filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter =
                            filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration:
                          const Duration(
                        milliseconds: 250,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration:
                          BoxDecoration(
                        color: selected
                            ? const Color(
                                0xFF2563EB)
                            : Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(
                                  0xFF2563EB)
                              : Colors
                                  .grey.shade300,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.grey,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ───────────────── STATS
              Row(
                children: [

                  _statCard(
                    "Average",
                    "${average.toStringAsFixed(1)} mg/dL",
                    Icons.analytics,
                    const Color(0xFF2563EB),
                  ),

                  const SizedBox(width: 12),

                  _statCard(
                    "Minimum",
                    "${minimum.toStringAsFixed(1)} mg/dL",
                    Icons.arrow_downward,
                    const Color(0xFF10B981),
                  ),

                  const SizedBox(width: 12),

                  _statCard(
                    "Maximum",
                    "${maximum.toStringAsFixed(1)} mg/dL",
                    Icons.arrow_upward,
                    const Color(0xFFEF4444),
                  ),

                  const SizedBox(width: 12),

                  _statCard(
                    "In Range",
                    "$inRange / ${filtered.length}",
                    Icons.check_circle,
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ───────────────── CHART / TABLE
              filtered.isEmpty
                  ? _emptyState(
                      "No data for selected period",
                    )
                  : showChart
                      ? _buildChart(filtered)
                      : _buildTable(filtered),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CHART
  // ─────────────────────────────────────────────────────────────

  Widget _buildChart(
    List<MapEntry<String, dynamic>> entries,
  ) {
    final spots = <FlSpot>[];

    final labels = <String>[];

    final values = <double>[];

    for (int i = 0; i < entries.length; i++) {
      final data = entries[i].value;

      final value =
          double.tryParse(
            data['value']
                    ?.toString() ??
                '0',
          ) ??
          0;

      final dt = _parseDate(
        data['timestamp'] ??
            data['date'],
      );

      spots.add(
        FlSpot(
          i.toDouble(),
          value,
        ),
      );

      values.add(value);

      labels.add(
        dt != null
            ? DateFormat(
                'dd/MM\nHH:mm',
              ).format(dt)
            : '',
      );
    }

    final maxValue =
        values.isEmpty
            ? 250
            : values.reduce(
                (a, b) => a > b ? a : b,
              );

    return Container(
      height: 480,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [

          // TITLE
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              const Text(
                "Blood Glucose Trend",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEFF6FF,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: Text(
                  "${entries.length} Measurements",
                  style: const TextStyle(
                    color:
                        Color(0xFF2563EB),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // LEGEND
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _legendItem(
                const Color(0xFF10B981),
                "Normal",
              ),

              _legendItem(
                const Color(0xFFF59E0B),
                "Warning",
              ),

              _legendItem(
                const Color(0xFFEF4444),
                "Critical",
              ),

              _legendItem(
                const Color(0xFF3B82F6),
                "Low",
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: LineChart(
              LineChartData(

                minY: 40,

                maxY: maxValue < 250
                    ? 250
                    : maxValue + 30,

                clipData:
                    FlClipData.all(),

                // GRID
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  verticalInterval: 1,

                  getDrawingHorizontalLine:
                      (value) {
                    return FlLine(
                      color:
                          Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },

                  getDrawingVerticalLine:
                      (value) {
                    return FlLine(
                      color:
                          Colors.grey.shade100,
                      strokeWidth: 1,
                    );
                  },
                ),

                // NORMAL RANGE
                rangeAnnotations:
                    RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: 70,
                      y2: 140,
                      color: Colors.green
                          .withOpacity(0.08),
                    ),
                  ],
                ),

                // TITLES
                titlesData:
                    FlTitlesData(

                  topTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: false,
                    ),
                  ),

                  rightTitles:
                      const AxisTitles(
                    sideTitles:
                        SideTitles(
                      showTitles: false,
                    ),
                  ),

                  // LEFT
                  leftTitles:
                      AxisTitles(
                    axisNameWidget:
                        const Padding(
                      padding:
                          EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: Text(
                        "mg/dL",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    sideTitles:
                        SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: 20,

                      getTitlesWidget:
                          (value, meta) {
                        return Text(
                          value
                              .toInt()
                              .toString(),
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color:
                                Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),

                  // BOTTOM
                  bottomTitles:
                      AxisTitles(
                    axisNameWidget:
                        const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 10,
                      ),
                      child: Text(
                        "Timeline",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    sideTitles:
                        SideTitles(
                      showTitles: true,
                      reservedSize: 60,

                      interval:
                          entries.length > 8
                              ? (entries.length /
                                      6)
                                  .ceilToDouble()
                              : 1,

                      getTitlesWidget:
                          (value, meta) {

                        final index =
                            value.toInt();

                        if (index < 0 ||
                            index >=
                                labels.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Text(
                            labels[index],
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              fontSize: 9,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // BORDER
                borderData:
                    FlBorderData(
                  show: true,
                  border: Border.all(
                    color:
                        Colors.grey.shade300,
                  ),
                ),

                // TOUCH
                lineTouchData:
                    LineTouchData(
                  handleBuiltInTouches:
                      true,

                  touchTooltipData:
                      LineTouchTooltipData(
                    tooltipRoundedRadius:
                        12,

                    getTooltipColor:
                        (_) =>
                            const Color(
                              0xFF111827,
                            ),

                    getTooltipItems:
                        (spotsTouched) {

                      return spotsTouched.map(
                        (spot) {

                          String state =
                              "Normal";

                          if (spot.y < 70) {
                            state = "Low";
                          } else if (spot.y >
                              200) {
                            state =
                                "Critical";
                          } else if (spot.y >
                              140) {
                            state =
                                "Warning";
                          }

                          return LineTooltipItem(
                            "${spot.y.toStringAsFixed(1)} mg/dL\n$state",

                            const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ).toList();
                    },
                  ),
                ),

                // LINE
                lineBarsData: [

                  LineChartBarData(

                    spots: spots,

                    isCurved: false,

                    color:
                        const Color(0xFF2563EB),

                    barWidth: 3,

                    isStrokeCapRound:
                        true,

                    belowBarData:
                        BarAreaData(
                      show: true,

                      gradient:
                          LinearGradient(
                        begin:
                            Alignment
                                .topCenter,

                        end:
                            Alignment
                                .bottomCenter,

                        colors: [
                          const Color(
                            0xFF2563EB,
                          ).withOpacity(0.2),

                          const Color(
                            0xFF2563EB,
                          ).withOpacity(0.01),
                        ],
                      ),
                    ),

                    dotData: FlDotData(
                      show: true,

                      getDotPainter:
                          (
                        spot,
                        percent,
                        barData,
                        index,
                      ) {

                        final value =
                            values[index];

                        return FlDotCirclePainter(
                          radius: 5,
                          color:
                              _dotColor(value),
                          strokeWidth: 2,
                          strokeColor:
                              Colors.white,
                        );
                      },
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

  // ─────────────────────────────────────────────────────────────
  // TABLE
  // ─────────────────────────────────────────────────────────────

  Widget _buildTable(
    List<MapEntry<String, dynamic>>
        entries,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [

            DataColumn(
              label: Text("Date"),
            ),

            DataColumn(
              label: Text("Value"),
            ),

            DataColumn(
              label: Text("Status"),
            ),

            DataColumn(
              label: Text("Source"),
            ),
          ],

          rows: entries.map((e) {

            final data = e.value;

            final value =
                double.tryParse(
                  data['value']
                          ?.toString() ??
                      '0',
                ) ??
                0;

            final dt = _parseDate(
              data['timestamp'] ??
                  data['date'],
            );

            final date =
                dt != null
                    ? DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(dt)
                    : '--';

            final isDoctor =
                data['doctor_added'] ==
                    true;

            String status =
                "Normal";

            Color color =
                const Color(
                  0xFF10B981,
                );

            if (value < 70) {
              status = "Low";
              color =
                  const Color(
                    0xFF3B82F6,
                  );
            } else if (value > 200) {
              status = "Critical";
              color =
                  const Color(
                    0xFFEF4444,
                  );
            } else if (value > 140) {
              status = "Warning";
              color =
                  const Color(
                    0xFFF59E0B,
                  );
            }

            return DataRow(
              cells: [

                DataCell(
                  Text(date),
                ),

                DataCell(
                  Text(
                    "${value.toStringAsFixed(1)} mg/dL",
                  ),
                ),

                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color: color
                          .withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                DataCell(
                  Text(
                    isDoctor
                        ? "Doctor"
                        : "Device",
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  Widget _viewToggleBtn(
    IconData icon,
    bool chart,
    String tooltip,
  ) {
    final active =
        showChart == chart;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            showChart = chart;
          });
        },
        borderRadius:
            BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active
                ? const Color(
                    0xFFEFF6FF,
                  )
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: active
                ? const Color(
                    0xFF2563EB,
                  )
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Icon(
              icon,
              color: color,
            ),

            const SizedBox(height: 10),

            Text(
              value,
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(
    Color color,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 6),

        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String text) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Icon(
              Icons.bar_chart,
              size: 60,
              color: Colors.grey.shade300,
            ),

            const SizedBox(height: 14),

            Text(
              text,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}