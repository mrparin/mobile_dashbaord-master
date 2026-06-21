import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GaugeCard extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color color;
  final IconData icon;

  const GaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(min, max);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double gaugeHeight = (constraints.maxWidth * 0.62).clamp(
          96.0,
          190.0,
        );
        final double titleFontSize = (constraints.maxWidth * 0.10).clamp(
          13.0,
          18.0,
        );
        final double valueFontSize = (constraints.maxWidth * 0.16).clamp(
          18.0,
          32.0,
        );
        final double iconSize = (constraints.maxWidth * 0.10).clamp(18.0, 28.0);
        final double gaugeStroke = (gaugeHeight * 0.085).clamp(8.0, 14.0);

        return Card(
          elevation: 4,
          shadowColor: color.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: isDark ? Colors.grey[900] : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.15), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: iconSize, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: titleFontSize,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: gaugeHeight,
                  child: SfRadialGauge(
                    enableLoadingAnimation: true,
                    animationDuration: 1500,
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: min,
                        maximum: max,
                        startAngle: 140,
                        endAngle: 40,
                        showLabels: false,
                        showTicks: false,
                        axisLineStyle: AxisLineStyle(
                          thickness: gaugeStroke,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          thicknessUnit: GaugeSizeUnit.logicalPixel,
                          cornerStyle: CornerStyle.bothCurve,
                        ),
                        pointers: <GaugePointer>[
                          RangePointer(
                            value: clamped,
                            width: gaugeStroke,
                            color: color,
                            cornerStyle: CornerStyle.bothCurve,
                            enableAnimation: true,
                          ),
                        ],
                        annotations: <GaugeAnnotation>[
                          GaugeAnnotation(
                            widget: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  value.toStringAsFixed(1),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: valueFontSize,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  unit,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: (titleFontSize * 0.72).clamp(
                                      10.0,
                                      14.0,
                                    ),
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            positionFactor: 0.15,
                            angle: 90,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
