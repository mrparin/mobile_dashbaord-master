import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/telemetry_model.dart';
import 'database_service.dart';
import 'mqtt_service.dart';

class InfluxService {
  InfluxService._privateConstructor();
  static final InfluxService instance = InfluxService._privateConstructor();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final ValueNotifier<String> syncStateNotifier = ValueNotifier<String>('Idle');

  // Synchronizes historical data since the last record in SQLite
  Future<void> syncMissingData() async {
    if (_isSyncing) return;
    _isSyncing = true;
    syncStateNotifier.value = 'Syncing...';

    final String baseUrl = dotenv.get('INFLUX_URL', fallback: 'http://sci-iot.ddns.net:8086').trim();
    final String token = dotenv.get('INFLUX_TOKEN', fallback: '').trim();
    final String org = dotenv.get('INFLUX_ORG', fallback: 'sci-iot').trim();
    final String bucket = dotenv.get('INFLUX_BUCKET', fallback: 'durian_data').trim();

    if (token.isEmpty) {
      print('InfluxDB Token is empty. Skipping synchronization.');
      _isSyncing = false;
      syncStateNotifier.value = 'Failed (No Token)';
      return;
    }

    try {
      // 1. Find the latest timestamp from SQLite
      final lastTimestamp = await DatabaseService.instance.getLatestTelemetryTimestamp();
      DateTime startTime;

      if (lastTimestamp != null) {
        // Query from the last record timestamp + 1 second to avoid duplicates
        startTime = lastTimestamp.add(const Duration(seconds: 1));
      } else {
        // If empty, sync the last 24 hours of data
        startTime = DateTime.now().subtract(const Duration(hours: 24));
      }

      // Check if start time is in the future (skewed clocks) or too close to now
      if (startTime.isAfter(DateTime.now())) {
        startTime = DateTime.now().subtract(const Duration(hours: 24));
      }

      print('Syncing InfluxDB telemetry from: ${startTime.toIso8601String()}');

      // 2. Build InfluxDB Flux Query
      final String fluxQuery = '''
from(bucket: "$bucket")
  |> range(start: ${startTime.toUtc().toIso8601String()})
  |> filter(fn: (r) => r["_measurement"] == "all_sensor_data")
  |> filter(fn: (r) => r["location"] == "farm1")
  |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
''';

      final queryUrl = Uri.parse('$baseUrl/api/v2/query?org=$org');

      // 3. Execute HTTP Post
      final response = await http.post(
        queryUrl,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/vnd.flux',
          'Accept': 'application/csv',
        },
        body: fluxQuery,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('InfluxDB Query failed with status: ${response.statusCode}, body: ${response.body}');
      }

      // 4. Parse CSV response
      final syncedTelemetry = _parseInfluxDbCsv(response.body);
      print('Fetched ${syncedTelemetry.length} telemetry records from InfluxDB.');

      if (syncedTelemetry.isNotEmpty) {
        // 5. Bulk insert to SQLite
        await DatabaseService.instance.insertTelemetryBatch(syncedTelemetry);
        print('Successfully saved ${syncedTelemetry.length} records to local database.');

        // 6. Push the latest record to MQTT stream so that the UI updates immediately
        final latestPoint = syncedTelemetry.last;
        MqttService.instance.emitTelemetry(latestPoint);
      }

      _isSyncing = false;
      syncStateNotifier.value = 'Success';
    } catch (e) {
      print('Error syncing historical InfluxDB data: $e');
      _isSyncing = false;
      syncStateNotifier.value = 'Failed';
    }
  }

  // Parses InfluxDB pivoted query CSV result
  List<SensorTelemetry> _parseInfluxDbCsv(String csvData) {
    final lines = csvData.split('\n');
    if (lines.isEmpty) return [];

    int headerIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty && !line.startsWith('#')) {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex == -1 || headerIndex >= lines.length) return [];

    final header = lines[headerIndex].split(',');
    final Map<String, int> colIndices = {};
    for (int i = 0; i < header.length; i++) {
      colIndices[header[i].trim()] = i;
    }

    final List<SensorTelemetry> results = [];
    for (int i = headerIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split(',');
      if (parts.length < header.length) continue;

      double getDouble(String fieldName) {
        final idx = colIndices[fieldName];
        if (idx != null && idx < parts.length) {
          return double.tryParse(parts[idx].trim()) ?? 0.0;
        }
        return 0.0;
      }

      DateTime? getTime() {
        final idx = colIndices['_time'];
        if (idx != null && idx < parts.length) {
          return DateTime.tryParse(parts[idx].trim());
        }
        return null;
      }

      final time = getTime();
      if (time == null) continue;

      results.add(SensorTelemetry(
        timestamp: time.toLocal(),
        airTemp: getDouble('air_temp'),
        airHumi: getDouble('air_humi'),
        soilTemp: getDouble('soil_temp'),
        soilHumi: getDouble('soil_humi'),
        windSpeed: getDouble('wind_speed_avg5m'),
        windDir: getDouble('wind_dir_deg'),
        lux: getDouble('lux'),
        ec: getDouble('ec'),
        ph: getDouble('ph'),
        n: getDouble('n'),
        p: getDouble('phosphorus'), // map phosphorus to p
        k: getDouble('k'),
        vpdKpa: getDouble('vpd_kpa'),
        solarWm2Est: getDouble('solar_wm2_est'),
        etoMmDayEst: getDouble('eto_mm_day_est'),
      ));
    }

    // Sort by timestamp ascending just in case InfluxDB returns them out of order
    results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return results;
  }
}
