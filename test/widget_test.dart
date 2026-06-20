import 'package:flutter_test/flutter_test.dart';
import 'package:phanmanee/models/telemetry_model.dart';

void main() {
  group('SensorTelemetry & VPD Unit Tests', () {
    test('VPD Calculation Correctness', () {
      // Test cases with known air temperature and humidity
      // T = 30°C, RH = 80%
      final telemetry1 = SensorTelemetry(
        timestamp: DateTime.now(),
        airTemp: 30.0,
        airHumi: 80.0,
        soilTemp: 25.0,
        soilHumi: 60.0,
      );

      // Calculations check:
      // es = 0.61078 * exp((17.27 * 30) / (30 + 237.3)) ~= 4.244 kPa
      // ea = es * (80 / 100) ~= 3.395 kPa
      // VPD = es - ea ~= 0.849 kPa
      expect(telemetry1.vpd, closeTo(0.849, 0.05));
    });

    test('VPD Status Ranges Mapping', () {
      // 1. VPD below 0.40 (Too Low)
      // T = 25°C, RH = 95% -> es = 3.167, ea = 3.009 -> VPD = 0.158
      final telemetryLow = SensorTelemetry(
        timestamp: DateTime.now(),
        airTemp: 25.0,
        airHumi: 95.0,
        soilTemp: 25.0,
        soilHumi: 60.0,
      );
      expect(telemetryLow.vpd, lessThan(0.40));

      // 2. VPD 0.40 - 0.80 (Low Stress)
      // T = 28°C, RH = 85% -> es = 3.778, ea = 3.211 -> VPD = 0.567
      final telemetryLowStress = SensorTelemetry(
        timestamp: DateTime.now(),
        airTemp: 28.0,
        airHumi: 85.0,
        soilTemp: 25.0,
        soilHumi: 60.0,
      );
      expect(telemetryLowStress.vpd, greaterThanOrEqualTo(0.40));
      expect(telemetryLowStress.vpd, lessThanOrEqualTo(0.80));

      // 3. VPD 0.81 - 1.40 (Optimal)
      // T = 30°C, RH = 75% -> es = 4.244, ea = 3.183 -> VPD = 1.061
      final telemetryOptimal = SensorTelemetry(
        timestamp: DateTime.now(),
        airTemp: 30.0,
        airHumi: 75.0,
        soilTemp: 25.0,
        soilHumi: 60.0,
      );
      expect(telemetryOptimal.vpd, greaterThanOrEqualTo(0.81));
      expect(telemetryOptimal.vpd, lessThanOrEqualTo(1.40));

      // 4. VPD 1.41 - 1.80 (High Stress)
      // T = 32°C, RH = 65% -> es = 4.753, ea = 3.090 -> VPD = 1.663
      final telemetryHighStress = SensorTelemetry(
        timestamp: DateTime.now(),
        airTemp: 32.0,
        airHumi: 65.0,
        soilTemp: 25.0,
        soilHumi: 60.0,
      );
      expect(telemetryHighStress.vpd, greaterThanOrEqualTo(1.41));
      expect(telemetryHighStress.vpd, lessThanOrEqualTo(1.80));

      // 5. VPD > 1.80 (Danger)
      // T = 35°C, RH = 50% -> es = 5.622, ea = 2.811 -> VPD = 2.811
      final telemetryDanger = SensorTelemetry(
        timestamp: DateTime.now(),
        airTemp: 35.0,
        airHumi: 50.0,
        soilTemp: 25.0,
        soilHumi: 60.0,
      );
      expect(telemetryDanger.vpd, greaterThan(1.80));
    });
  });
}
