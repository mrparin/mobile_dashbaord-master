import 'package:flutter/material.dart';

class VpdThreshold {
  final double min;
  final double max;
  final String status;
  final String meaning;
  final String action;
  final Color color;
  final IconData icon;

  VpdThreshold({
    required this.min,
    required this.max,
    required this.status,
    required this.meaning,
    required this.action,
    required this.color,
    required this.icon,
  });
}

class VpdStatusCard extends StatelessWidget {
  final double vpdValue;

  const VpdStatusCard({
    super.key,
    required this.vpdValue,
  });

  // Load rules directly from the markdown spec:
  static final List<VpdThreshold> thresholds = [
    VpdThreshold(
      min: 0.0,
      max: 0.399,
      status: 'ต่ำเกินไป (Too Low)',
      meaning: 'อากาศชื้นจัด อัตราการคายน้ำต่ำมาก พืชไม่ดูดน้ำและธาตุอาหาร (โดยเฉพาะแคลเซียม) เสี่ยงต่อการเกิดโรครา',
      action: 'งดการให้น้ำและระบบพ่นหมอก เปิดพัดลมระบายอากาศ (หากเป็นโรงเรือน) เพื่อให้อากาศหมุนเวียน',
      color: Colors.blue[600]!,
      icon: Icons.water_drop_outlined,
    ),
    VpdThreshold(
      min: 0.40,
      max: 0.80,
      status: 'เฝ้าระวังต่ำ (Low Stress)',
      meaning: 'อากาศค่อนข้างชื้น พืชคายน้ำได้เล็กน้อย เหมาะสำหรับช่วงดึงดอก หรือช่วงเพาะกล้าที่ต้องการความชื้นสูง',
      action: 'ระบบทำงานปกติ ไม่ต้องเปิดระบบพ่นหมอกเพิ่ม',
      color: Colors.teal[500]!,
      icon: Icons.visibility_outlined,
    ),
    VpdThreshold(
      min: 0.81,
      max: 1.40,
      status: 'เหมาะสมที่สุด (Optimal)',
      meaning: 'ช่วงทองของทุเรียน พืชเปิดปากใบเต็มที่ สังเคราะห์แสงและดูดซึมธาตุอาหารจากดินได้ดีที่สุด',
      action: 'รักษาระดับนี้ไว้ เป็นช่วงที่ทุเรียนเติบโตและสะสมอาหารได้ดีที่สุด',
      color: Colors.green[600]!,
      icon: Icons.check_circle_outline,
    ),
    VpdThreshold(
      min: 1.41,
      max: 1.80,
      status: 'เริ่มวิกฤต (High Stress)',
      meaning: 'อากาศแห้งและร้อนเกินไป ทุเรียนคายน้ำเร็วกว่าการดูดน้ำจากราก พืชจะเริ่มปิดปากใบเพื่อเอาตัวรอด',
      action: 'แจ้งเตือนระดับสีเหลือง: ควรเปิดระบบพ่นหมอก (Fogging) เพื่อเพิ่มความชื้นในอากาศทันที',
      color: Colors.orange[600]!,
      icon: Icons.warning_amber_outlined,
    ),
    VpdThreshold(
      min: 1.801,
      max: 10.0,
      status: 'วิกฤตรุนแรง (Danger)',
      meaning: 'อากาศแห้งจัด วิกฤตใบไหม้ ปากใบปิดสนิท หยุดการสังเคราะห์แสง หากอยู่ในช่วงติดผลจะทำให้ ผลร่วง',
      action: 'แจ้งเตือนระดับสีแดง: สั่งเปิดระบบพ่นหมอกเต็มกำลัง และเพิ่มรอบการให้น้ำที่โคนต้นเพื่อสู้กับแดด',
      color: Colors.red[600]!,
      icon: Icons.gpp_bad_outlined,
    ),
  ];

  VpdThreshold _getThreshold(double val) {
    for (var t in thresholds) {
      if (val >= t.min && val <= t.max) {
        return t;
      }
    }
    // Fallback just in case
    return thresholds[2];
  }

  @override
  Widget build(BuildContext context) {
    final t = _getThreshold(vpdValue);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 6,
      shadowColor: t.color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: t.color.withOpacity(0.3),
            width: 2.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.color.withOpacity(0.06),
              t.color.withOpacity(0.01),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(t.icon, color: t.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ค่าดัชนี VPD ปัจจุบัน',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${vpdValue.toStringAsFixed(2)} kPa',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.color,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    t.status.split(' ')[0], // only show Thai text on badge
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            Text(
              'สถานะ: ${t.status}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: t.color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ผลกระทบต่อสรีรวิทยาทุเรียน:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[350] : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.meaning,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: t.color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'คำแนะนำการจัดการระบบอัจฉริยะ:',
                        style: TextStyle(
                          color: t.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.action,
                    style: TextStyle(
                      color: isDark ? Colors.grey[200] : Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
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
}
