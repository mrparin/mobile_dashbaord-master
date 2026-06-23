import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/telemetry_model.dart';
import '../services/database_service.dart';
import '../services/mqtt_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView>
    with SingleTickerProviderStateMixin {
  String _selectedPreset = '24h'; // Default preset: 24 hours
  List<SensorTelemetry> _history = [];
  bool _isLoading = false;
  late TabController _tabController;
  StreamSubscription<SensorTelemetry>? _telemetrySubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    unawaited(_loadHistory());

    // Auto-refresh when new telemetry is received
    _telemetrySubscription = MqttService.instance.telemetryStream.listen((_) {
      if (mounted) {
        _loadHistory();
      }
    });
  }

  Future<void> unawaited(Future<void> future) async {
    await future;
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Seed data if empty just to show a gorgeous chart first
      await DatabaseService.instance.seedMockDataIfEmpty();
      final records = await DatabaseService.instance.getHistoryForPreset(
        _selectedPreset,
      );

      setState(() {
        _history = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบประวัติ?'),
        content: const Text(
          'คุณต้องการลบข้อมูลประวัติการวัดทั้งหมดออกจากเครื่องหรือไม่? การดำเนินการนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.clearHistory();
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบประวัติการวัดทั้งหมดเรียบร้อยแล้ว')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final double chartHeight = isLandscape ? 300 : 260;
    final double feedHeight = isLandscape ? 300 : 240;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ข้อมูลย้อนหลัง',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'ล้างข้อมูลประวัติ',
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.redAccent,
            ),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Timeframe Selector Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPresetButton('1h', '1 ชั่วโมงล่าสุด'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPresetButton('24h', '24 ชั่วโมงล่าสุด'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPresetButton('7d', '7 วันล่าสุด')),
                  ],
                ),
              ),

              // Tab Bar for Trends
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  tabs: const [
                    Tab(text: 'อากาศ (Air)'),
                    Tab(text: 'ดิน (Soil)'),
                    Tab(text: 'ดัชนี VPD'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Charts Area
              SizedBox(
                height: chartHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _history.isEmpty
                      ? const Center(
                          child: Text('ไม่มีข้อมูลประวัติในช่วงเวลานี้'),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLineChart(
                              isAir: true,
                              title: 'อุณหภูมิและความชื้นสัมพัทธ์ในอากาศ',
                            ),
                            _buildLineChart(
                              isAir: false,
                              title: 'อุณหภูมิและความชื้นในดิน',
                            ),
                            _buildVpdChart(),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Data Log Table Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'บันทึกข้อมูลการวัดทั้งหมด (${_history.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadHistory,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text(
                        'รีเฟรช',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Data Log Table List
              SizedBox(
                height: feedHeight,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _history.isEmpty
                      ? const Center(child: Text('ไม่มีบันทึกข้อมูล'))
                      : ListView.separated(
                          itemCount: _history.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            // Show newest records first in the table list
                            final record =
                                _history[_history.length - 1 - index];
                            final timeStr = DateFormat(
                              'dd/MM HH:mm',
                            ).format(record.timestamp);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildLogTag(
                                    'อากาศ',
                                    '${record.airTemp.toStringAsFixed(1)}°/${record.airHumi.toStringAsFixed(0)}%',
                                    Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildLogTag(
                                    'ดิน',
                                    '${record.soilTemp.toStringAsFixed(1)}°/${record.soilHumi.toStringAsFixed(0)}%',
                                    Colors.teal,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildLogTag(
                                    'VPD',
                                    record.vpd.toStringAsFixed(1),
                                    Colors.green,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(String preset, String label) {
    final isSelected = _selectedPreset == preset;
    return isSelected
        ? FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          )
        : OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedPreset = preset;
              });
              _loadHistory();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          );
  }

  Widget _buildLogTag(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Dual Line Chart Widget
  Widget _buildLineChart({required bool isAir, required String title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<FlSpot> tempSpots = [];
    final List<FlSpot> humiSpots = [];

    for (int i = 0; i < _history.length; i++) {
      final double x =
          _history[i].timestamp.millisecondsSinceEpoch / 1000.0;
      final double temp = isAir ? _history[i].airTemp : _history[i].soilTemp;
      final double humi = isAir ? _history[i].airHumi : _history[i].soilHumi;
      tempSpots.add(FlSpot(x, temp));
      humiSpots.add(FlSpot(x, humi));
    }

    final legend = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIndicatorDot(Colors.orange, 'อุณหภูมิ (°C)'),
        const SizedBox(width: 24),
        _buildIndicatorDot(
          isAir ? Colors.blue : Colors.teal,
          'ความชื้น (%)',
        ),
      ],
    );

    return _buildScrollableChart(
      isDark: isDark,
      legend: legend,
      minY: 0,
      maxY: 100,
      yInterval: 20,
      yLabelFn: (v) => v.toStringAsFixed(0),
      lineBars: [
        LineChartBarData(
          spots: tempSpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: humiSpots,
          isCurved: true,
          color: isAir ? Colors.blue : Colors.teal,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  // VPD Line Chart Widget
  Widget _buildVpdChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<FlSpot> spots = [];
    double maxVpd = 2.0;

    for (int i = 0; i < _history.length; i++) {
      final double x =
          _history[i].timestamp.millisecondsSinceEpoch / 1000.0;
      final double vpd = _history[i].vpd;
      spots.add(FlSpot(x, vpd));
      if (vpd > maxVpd) maxVpd = vpd;
    }

    final legend =
        _buildIndicatorDot(Colors.green, 'แรงดันไอที่แตกต่าง VPD (kPa)');

    return _buildScrollableChart(
      isDark: isDark,
      legend: legend,
      minY: 0,
      maxY: maxVpd + 0.5,
      yLabelFn: (v) => v.toStringAsFixed(1),
      lineBars: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Scrollable chart scaffold
  // Pins the Y-axis on the left and allows horizontal pan on chart + X labels
  // ---------------------------------------------------------------------------
  Widget _buildScrollableChart({
    required bool isDark,
    required Widget legend,
    required double minY,
    required double maxY,
    double? yInterval,
    required String Function(double) yLabelFn,
    required List<LineChartBarData> lineBars,
  }) {
    final theme = Theme.of(context);
    final xInterval = _getXInterval();
    final timeFormat = _getTimeFormat();
    final chartWidth = _getScrollableChartWidth();
    final bottomReservedSize = _getBottomReservedSize();

    // Compute actual min/max X from spots so the chart fills correctly
    double? minX, maxX;
    for (final bar in lineBars) {
      for (final spot in bar.spots) {
        minX = minX == null ? spot.x : (spot.x < minX ? spot.x : minX);
        maxX = maxX == null ? spot.x : (spot.x > maxX ? spot.x : maxX);
      }
    }

    // Fixed Y-axis width (matches left reserved size below)
    const double yAxisWidth = 34.0;

    final scrollController = ScrollController();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(
          children: [
            // Legend
            legend,
            const SizedBox(height: 12),
            // Chart row: pinned Y-axis | scrollable chart area
            Expanded(
              child: Row(
                children: [
                  // ── Pinned Y-axis ──────────────────────────────────────────
                  SizedBox(
                    width: yAxisWidth,
                    child: LineChart(
                      LineChartData(
                        minY: minY,
                        maxY: maxY,
                        minX: minX,
                        maxX: maxX,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: lineBars
                            .map(
                              (b) => LineChartBarData(
                                spots: b.spots,
                                color: Colors.transparent,
                                barWidth: 0,
                                dotData: const FlDotData(show: false),
                              ),
                            )
                            .toList(),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: yAxisWidth,
                              interval: yInterval,
                              getTitlesWidget: (value, meta) => Text(
                                yLabelFn(value),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Scrollable chart + X labels ────────────────────────────
                  Expanded(
                    child: Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(4),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(
                          bottom: bottomReservedSize > 30 ? 10 : 6,
                        ),
                        child: SizedBox(
                          width: chartWidth,
                          child: LineChart(
                            LineChartData(
                              minY: minY,
                              maxY: maxY,
                              minX: minX,
                              maxX: maxX,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                verticalInterval: xInterval,
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!,
                                  strokeWidth: 0.8,
                                  dashArray: [4, 4],
                                ),
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[200]!,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: bottomReservedSize,
                                    interval: xInterval,
                                    getTitlesWidget: (value, meta) {
                                      final dt =
                                          DateTime.fromMillisecondsSinceEpoch(
                                        (value * 1000).toInt(),
                                      );
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          DateFormat(timeFormat).format(dt),
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: lineBars,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculates total chart canvas width so each time-tick gets enough space.
  /// Each tick gets 56px minimum, giving clear readable labels.
  double _getScrollableChartWidth() {
    switch (_selectedPreset) {
      case '1h':
        // 6 ticks × 10 min = 60 min; give each 60px
        return 6 * 60.0;
      case '24h':
        // 24 ticks × 1 h; give each 64px
        return 24 * 64.0;
      case '7d':
        // 14 ticks × 12 h; give each 72px
        return 14 * 72.0;
      default:
        return 800;
    }
  }

  /// Returns the reserved height (px) for the bottom X-axis label row.
  /// 7d uses a 2-line label (dd/MM + HH:mm) so needs more space.
  double _getBottomReservedSize() {
    return _selectedPreset == '7d' ? 44.0 : 28.0;
  }

  /// Returns X-axis interval in seconds based on the selected time preset.
  /// - 1h  → every 10 minutes (600 seconds)
  /// - 24h → every 1 hour   (3600 seconds)
  /// - 7d  → every 12 hours (43200 seconds)
  double _getXInterval() {
    switch (_selectedPreset) {
      case '1h':
        return 600; // 10 minutes
      case '24h':
        return 3600; // 1 hour
      case '7d':
        return 43200; // 12 hours
      default:
        return 3600;
    }
  }

  /// Returns DateFormat pattern matching the selected time preset.
  String _getTimeFormat() {
    switch (_selectedPreset) {
      case '1h':
        return 'HH:mm'; // e.g. 14:30
      case '24h':
        return 'HH:mm'; // e.g. 14:00
      case '7d':
        return 'dd/MM\nHH:mm'; // e.g. 23/06\n14:00
      default:
        return 'HH:mm';
    }
  }

  Widget _buildIndicatorDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
