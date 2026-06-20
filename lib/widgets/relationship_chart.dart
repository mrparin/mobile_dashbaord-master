import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/telemetry_model.dart';

class RelationshipChart extends StatelessWidget {
  final String title;
  final String xLabel;
  final String yLabel;
  final List<SensorTelemetry> history;
  final bool isAir; // true for Air Temp vs Humi, false for Soil Temp vs Humi
  final Color dotColor;

  const RelationshipChart({
    super.key,
    required this.title,
    required this.xLabel,
    required this.yLabel,
    required this.history,
    required this.isAir,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter points that are valid
    final List<ScatterSpot> spots = [];
    double minX = 100.0;
    double maxX = 0.0;
    double minY = 100.0;
    double maxY = 0.0;

    for (var record in history) {
      final double x = isAir ? record.airTemp : record.soilTemp;
      final double y = isAir ? record.airHumi : record.soilHumi;

      spots.add(ScatterSpot(
        x,
        y,
        dotPainter: FlDotCirclePainter(
          radius: 6,
          color: dotColor,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ));

      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // Add safe padding to the chart bounds, or use defaults if history is empty
    if (spots.isEmpty) {
      minX = 15.0;
      maxX = 45.0;
      minY = 30.0;
      maxY = 100.0;
    } else {
      minX = (minX - 2.0).clamp(0.0, 100.0);
      maxX = (maxX + 2.0).clamp(0.0, 100.0);
      minY = (minY - 5.0).clamp(0.0, 100.0);
      maxY = (maxY + 5.0).clamp(0.0, 100.0);
    }

    // Ensure min and max bounds are not equal
    if (minX == maxX) {
      minX -= 2.0;
      maxX += 2.0;
    }
    if (minY == maxY) {
      minY -= 5.0;
      maxY += 5.0;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[200] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ความสัมพันธ์: แกน X = $xLabel | แกน Y = $yLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: spots.isEmpty
                  ? Center(
                      child: Text(
                        'กำลังรอข้อมูลการวัด...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    )
                  : ScatterChart(
                      ScatterChartData(
                        scatterSpots: spots,
                        minX: minX,
                        maxX: maxX,
                        minY: minY,
                        maxY: maxY,
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!,
                            strokeWidth: 1,
                          ),
                          getDrawingVerticalLine: (value) => FlLine(
                            color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            axisNameWidget: Text(
                              yLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: dotColor,
                              ),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            axisNameWidget: Text(
                              xLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    value.toStringAsFixed(0),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        scatterTouchData: ScatterTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: ScatterTouchTooltipData(
                            tooltipBgColor: isDark ? Colors.grey[850]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                            tooltipBorder: BorderSide(
                              color: dotColor.withOpacity(0.5),
                              width: 1,
                            ),
                            getTooltipItems: (ScatterSpot spot) {
                              return ScatterTooltipItem(
                                '${spot.x.toStringAsFixed(1)}°C\n${spot.y.toStringAsFixed(1)}%',
                                textStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
