import 'dart:async';
import 'dart:math' as math;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/telemetry_model.dart';

class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'sensor_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE telemetry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        air_temp REAL NOT NULL,
        air_humi REAL NOT NULL,
        soil_temp REAL NOT NULL,
        soil_humi REAL NOT NULL,
        wind_speed REAL,
        wind_dir REAL,
        lux REAL,
        ec REAL,
        ph REAL,
        n REAL,
        p REAL,
        k REAL,
        vpd_kpa REAL,
        solar_wm2_est REAL,
        eto_mm_day_est REAL
      )
    ''');

    // Create an index on timestamp for fast queries
    await db.execute('CREATE INDEX idx_telemetry_timestamp ON telemetry(timestamp)');
  }

  // Insert a new telemetry reading
  Future<int> insertTelemetry(SensorTelemetry telemetry) async {
    final db = await database;
    return await db.insert(
      'telemetry',
      telemetry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get the timestamp of the latest local telemetry reading
  Future<DateTime?> getLatestTelemetryTimestamp() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'telemetry',
      columns: ['timestamp'],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final String? tsStr = maps.first['timestamp']?.toString();
    if (tsStr == null) return null;
    return DateTime.tryParse(tsStr);
  }

  // Bulk insert telemetry records efficiently in a batch
  Future<void> insertTelemetryBatch(List<SensorTelemetry> telemetryList) async {
    if (telemetryList.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final telemetry in telemetryList) {
      batch.insert(
        'telemetry',
        telemetry.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Query historical data between start and end times
  Future<List<SensorTelemetry>> getTelemetryHistory(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'telemetry',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return SensorTelemetry.fromJson(maps[i]);
    });
  }

  // Clear all history (useful for reset/testing)
  Future<int> clearHistory() async {
    final db = await database;
    return await db.delete('telemetry');
  }

  // Helper method to query data for common presets
  Future<List<SensorTelemetry>> getHistoryForPreset(String preset) async {
    final DateTime now = DateTime.now();
    DateTime startTime;

    switch (preset) {
      case '1h':
        startTime = now.subtract(const Duration(hours: 1));
        break;
      case '24h':
        startTime = now.subtract(const Duration(hours: 24));
        break;
      case '7d':
        startTime = now.subtract(const Duration(days: 7));
        break;
      default:
        startTime = now.subtract(const Duration(hours: 24)); // default to 24h
    }

    return await getTelemetryHistory(startTime, now);
  }

  // Insert some mock historical records if the database is empty (for demo purposes)
  Future<void> seedMockDataIfEmpty() async {
    final db = await database;
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM telemetry');
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0) {
      print('Seeding database with mock telemetry history...');
      final now = DateTime.now();
      final batch = db.batch();

      // Seed 24 hours of mock data (1 reading every 30 minutes = 48 points)
      for (int i = 48; i >= 0; i--) {
        final time = now.subtract(Duration(minutes: i * 30));
        
        // Simulate daily cycles: temperatures rise in mid-afternoon, humidity drops
        final hour = time.hour;
        final double baseTemp = 25.0 + 8.0 * math.sin((hour - 8) * math.pi / 12); // peak at 2 PM (14:00)
        final double airTemp = baseTemp + (math.Random().nextDouble() - 0.5) * 1.5;
        
        final double baseHumi = 85.0 - 30.0 * math.sin((hour - 8) * math.pi / 12); // min at 2 PM
        final double airHumi = baseHumi.clamp(30.0, 100.0) + (math.Random().nextDouble() - 0.5) * 3.0;

        // Soil temperature fluctuates less
        final double soilTemp = 24.0 + 2.0 * math.sin((hour - 10) * math.pi / 12) + (math.Random().nextDouble() - 0.5) * 0.5;
        
        // Soil moisture decreases slowly during day, resets slightly if watered
        final double soilHumi = 65.0 - 5.0 * math.sin((hour - 6) * math.pi / 24) + (math.Random().nextDouble() - 0.5) * 1.0;

        final telemetry = SensorTelemetry(
          timestamp: time,
          airTemp: airTemp,
          airHumi: airHumi,
          soilTemp: soilTemp,
          soilHumi: soilHumi,
          windSpeed: 1.5 + math.Random().nextDouble() * 3.0,
          windDir: 180.0 + (math.Random().nextDouble() - 0.5) * 40.0,
          lux: hour > 6 && hour < 18 ? 2000.0 * math.sin((hour - 6) * math.pi / 12) * 20.0 : 0.0,
          ec: 0.8 + (math.Random().nextDouble() - 0.5) * 0.1,
          ph: 6.2 + (math.Random().nextDouble() - 0.5) * 0.2,
          n: 25.0,
          p: 15.0,
          k: 30.0,
          solarWm2Est: hour > 6 && hour < 18 ? 600.0 * math.sin((hour - 6) * math.pi / 12) : 0.0,
          etoMmDayEst: 3.5,
        );

        batch.insert('telemetry', telemetry.toJson());
      }
      await batch.commit(noResult: true);
      print('Mock data seeded successfully.');
    }
  }
}
