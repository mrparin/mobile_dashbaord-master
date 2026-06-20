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
                _EnvironmentTile(
                  icon: Icons.explore_outlined,
                  label: 'ทิศทางลม',
                  value: telemetry.windDir.toStringAsFixed(0),
                  unit: '°',
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
