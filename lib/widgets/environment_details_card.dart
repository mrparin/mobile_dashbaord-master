import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/telemetry_model.dart';

class AirEnvironmentCard extends StatelessWidget {
  final SensorTelemetry telemetry;

  const AirEnvironmentCard({super.key, required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.air, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'สภาพแวดล้อมทางอากาศ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _EnvironmentTile(
                  icon: Icons.air,
                  label: 'ความเร็วลม',
                  value: telemetry.windSpeed.toStringAsFixed(1),
                  unit: 'm/s',
                  color: Colors.blue[600]!,
                ),
                _WindDirectionTile(
                  degrees: telemetry.windDir,
                  color: Colors.teal[600]!,
                ),
                _EnvironmentTile(
                  icon: Icons.wb_sunny_outlined,
                  label: 'ความเข้มแสง',
                  value: telemetry.lux.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  ),
                  unit: 'Lux',
                  color: Colors.orange[700]!,
                ),
                _EnvironmentTile(
                  icon: Icons.solar_power_outlined,
                  label: 'พลังงานแสงอาทิตย์',
                  value: telemetry.solarWm2Est.toStringAsFixed(1),
                  unit: 'W/m²',
                  color: Colors.red[600]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SoilEnvironmentCard extends StatelessWidget {
  final SensorTelemetry telemetry;

  const SoilEnvironmentCard({super.key, required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass_outlined, color: Colors.brown[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'สภาพแวดล้อมดิน',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _EnvironmentTile(
                  icon: Icons.water_drop_outlined,
                  label: 'ค่าความดันไอในดิน',
                  value: (telemetry.vpdKpa ?? telemetry.vpd).toStringAsFixed(2),
                  unit: 'kPa',
                  color: Colors.indigo[600]!,
                ),
                _EnvironmentTile(
                  icon: Icons.bolt_outlined,
                  label: 'ค่าการนำไฟฟ้าในดิน',
                  value: telemetry.ec.toStringAsFixed(0),
                  unit: 'µS/cm',
                  color: Colors.amber[800]!,
                ),
                _EnvironmentTile(
                  icon: Icons.science_outlined,
                  label: 'ค่าphในดิน',
                  value: telemetry.ph.toStringAsFixed(1),
                  unit: 'pH',
                  color: Colors.green[600]!,
                ),
                _EnvironmentTile(
                  icon: Icons.eco_outlined,
                  label: 'ไนโตรเจน',
                  value: telemetry.n.toStringAsFixed(0),
                  unit: 'mg/kg',
                  color: Colors.purple[600]!,
                ),
                _EnvironmentTile(
                  icon: Icons.eco_outlined,
                  label: 'ฟอสฟอรัส',
                  value: telemetry.p.toStringAsFixed(0),
                  unit: 'mg/kg',
                  color: Colors.cyan[700]!,
                ),
                _EnvironmentTile(
                  icon: Icons.eco_outlined,
                  label: 'โพแทสเซียม',
                  value: telemetry.k.toStringAsFixed(0),
                  unit: 'mg/kg',
                  color: Colors.deepOrange[600]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvironmentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _EnvironmentTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 2),
                      Text(
                        unit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wind Direction Compass Tile ────────────────────────────────────────────

class _WindDirectionTile extends StatelessWidget {
  final double degrees;
  final Color color;

  const _WindDirectionTile({
    required this.degrees,
    required this.color,
  });

  /// Converts degrees to 8-point compass label (English abbreviation)
  String _directionLabel(double deg) {
    final d = ((deg % 360) + 360) % 360;
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((d + 22.5) / 45).floor() % 8;
    return labels[index];
  }

  /// Converts degrees to 8-point compass label (Thai)
  String _directionLabelThai(double deg) {
    final d = ((deg % 360) + 360) % 360;
    const labels = ['เหนือ', 'ตอ.น.', 'ตะวันออก', 'ตอ.ต.', 'ใต้', 'ตต.ต.', 'ตะวันตก', 'ตต.น.'];
    final index = ((d + 22.5) / 45).floor() % 8;
    return labels[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dir = _directionLabel(degrees);
    final dirThai = _directionLabelThai(degrees);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Compact compass dial (36x36 to fit within tile height)
          SizedBox(
            width: 36,
            height: 36,
            child: CustomPaint(
              painter: _WindCompassPainter(
                degrees: degrees,
                color: color,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ทิศทางลม',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                // Direction label + degrees + Thai name — all in one compact row
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: dir,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: '  ${degrees.toStringAsFixed(0)}°',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                      TextSpan(
                        text: '  $dirThai',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Compass CustomPainter ───────────────────────────────────────────────────

class _WindCompassPainter extends CustomPainter {
  final double degrees;
  final Color color;
  final bool isDark;

  _WindCompassPainter({
    required this.degrees,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── Background circle ──
    final bgPaint = Paint()
      ..color = (isDark ? Colors.grey[800]! : Colors.grey[200]!)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // ── Border ring ──
    final borderPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, borderPaint);

    // ── Tick marks (8-point) ──
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final isCardinal = i % 2 == 0; // N, E, S, W
      final outer = radius - 1.5;
      final inner = isCardinal ? radius - 6.0 : radius - 4.0;
      final tickPaint = Paint()
        ..color = isCardinal ? color.withOpacity(0.7) : (isDark ? Colors.grey[500]! : Colors.grey[400]!)
        ..strokeWidth = isCardinal ? 1.5 : 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + Offset(math.sin(angle) * inner, -math.cos(angle) * inner),
        center + Offset(math.sin(angle) * outer, -math.cos(angle) * outer),
        tickPaint,
      );
    }

    // ── 'N' label ──
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: color,
          fontSize: radius * 0.28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center + Offset(-textPainter.width / 2, -radius * 0.62),
    );

    // ── Arrow needle ──
    final angleRad = degrees * math.pi / 180;
    final needleLen = radius * 0.58;
    final tailLen = radius * 0.28;

    // Head (colored)
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final headEnd = center +
        Offset(math.sin(angleRad) * needleLen, -math.cos(angleRad) * needleLen);
    canvas.drawLine(center, headEnd, needlePaint);

    // Tail (muted)
    final tailPaint = Paint()
      ..color = (isDark ? Colors.grey[500]! : Colors.grey[400]!)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final tailEnd = center +
        Offset(-math.sin(angleRad) * tailLen, math.cos(angleRad) * tailLen);
    canvas.drawLine(center, tailEnd, tailPaint);

    // Arrowhead triangle at needle tip
    final arrowSize = radius * 0.18;
    final arrowLeft = headEnd +
        Offset(
          math.sin(angleRad - math.pi * 0.45) * arrowSize,
          -math.cos(angleRad - math.pi * 0.45) * arrowSize,
        );
    final arrowRight = headEnd +
        Offset(
          math.sin(angleRad + math.pi * 0.45) * arrowSize,
          -math.cos(angleRad + math.pi * 0.45) * arrowSize,
        );
    final arrowPath = Path()
      ..moveTo(headEnd.dx, headEnd.dy)
      ..lineTo(arrowLeft.dx, arrowLeft.dy)
      ..lineTo(arrowRight.dx, arrowRight.dy)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color);

    // ── Center dot ──
    canvas.drawCircle(
      center,
      radius * 0.1,
      Paint()..color = isDark ? Colors.grey[300]! : Colors.grey[700]!,
    );
  }

  @override
  bool shouldRepaint(_WindCompassPainter old) =>
      old.degrees != degrees || old.color != color || old.isDark != isDark;
}
