import 'dart:math' as math;

class SensorTelemetry {
  final DateTime timestamp;
  final double airTemp;
  final double airHumi;
  final double soilTemp;
  final double soilHumi;
  final double windSpeed;
  final double windDir;
  final double lux;
  final double ec;
  final double ph;
  final double n;
  final double p;
  final double k;
  final double? vpdKpa; // Telemetry provided VPD (if any)
  final double solarWm2Est;
  final double etoMmDayEst;

  SensorTelemetry({
    required this.timestamp,
    required this.airTemp,
    required this.airHumi,
    required this.soilTemp,
    required this.soilHumi,
    this.windSpeed = 0.0,
    this.windDir = 0.0,
    this.lux = 0.0,
    this.ec = 0.0,
    this.ph = 7.0,
    this.n = 0.0,
    this.p = 0.0,
    this.k = 0.0,
    this.vpdKpa,
    this.solarWm2Est = 0.0,
    this.etoMmDayEst = 0.0,
  });

  // Calculates VPD (kPa) based on Air Temperature (T) and Air Humidity (RH)
  double get calculatedVpd {
    // es (Saturation Vapor Pressure) in kPa
    final double es = 0.6108 * math.exp((17.27 * airTemp) / (airTemp + 237.3));
    // ea (Actual Vapor Pressure) in kPa
    final double ea = es * (airHumi / 100.0);
    // VPD = es - ea = es * (1 - RH/100)
    final double vpd = es - ea;
    return math.max(0.0, double.parse(vpd.toStringAsFixed(3)));
  }

  // Gets either the calculated VPD or the one received from telemetry (preferring the calculated one)
  double get vpd => calculatedVpd;

  // Factory to create from MQTT JSON payload (compatible with both flat and nested JSON)
  factory SensorTelemetry.fromJson(Map<String, dynamic> json) {
    // Check if nested env and npk exist
    final env = json['env'] is Map ? json['env'] as Map<String, dynamic> : null;
    final npk = json['npk'] is Map ? json['npk'] as Map<String, dynamic> : null;

    final airTemp = _toDouble(env != null ? (env['air_temp'] ?? env['Air_temp']) : (json['air_temp'] ?? json['temp']));
    final airHumi = _toDouble(env != null ? (env['air_humi'] ?? env['Air_humi'] ?? env['humidity']) : (json['air_humi'] ?? json['hum'] ?? json['humidity']));
    final soilTemp = _toDouble(npk != null ? (npk['soil_temp'] ?? npk['Soil_temp']) : json['soil_temp']);
    final soilHumi = _toDouble(npk != null ? (npk['soil_humi'] ?? npk['Soil_humi'] ?? npk['soil_moisture']) : (json['soil_humi'] ?? json['soil_moisture']));
    final windSpeed = _toDouble(env != null ? (env['wind_speed_avg5m'] ?? env['wind_speed']) : (json['wind_speed_avg5m'] ?? json['wind_speed']));
    final windDir = _toDouble(env != null ? (env['wind_dir_deg'] ?? env['wind_dir']) : (json['wind_dir_deg'] ?? json['wind_dir']));
    final lux = _toDouble(env != null ? env['lux'] : json['lux']);
    
    final ec = _toDouble(npk != null ? npk['ec'] : json['ec']);
    final ph = _toDouble(npk != null ? npk['ph'] : json['ph']);
    final n = _toDouble(npk != null ? npk['n'] : json['n']);
    final p = _toDouble(npk != null ? npk['p'] : json['p']);
    final k = _toDouble(npk != null ? npk['k'] : json['k']);
    
    final double? parsedVpdKpa = json['vpd_kpa'] != null ? _toDouble(json['vpd_kpa']) : null;
    final double? nestedVpdKpa = npk != null && npk['vpd_kpa'] != null ? _toDouble(npk['vpd_kpa']) : null;
    final double? vpdKpa = nestedVpdKpa ?? parsedVpdKpa;

    final double parsedSolar = _toDouble(json['solar_wm2_est'] ?? json['solar']);
    final double nestedSolar = env != null && env['solar_wm2_est'] != null ? _toDouble(env['solar_wm2_est']) : 0.0;
    double solarWm2Est = nestedSolar > 0.0 ? nestedSolar : (parsedSolar > 0.0 ? parsedSolar : (lux > 0.0 ? lux / 120.0 : 0.0));

    final double parsedEto = _toDouble(json['eto_mm_day_est'] ?? json['eto']);
    final double nestedEto = env != null && env['eto_mm_day_est'] != null ? _toDouble(env['eto_mm_day_est']) : 0.0;
    double etoMmDayEst = nestedEto > 0.0 ? nestedEto : parsedEto;

    return SensorTelemetry(
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      airTemp: airTemp,
      airHumi: airHumi,
      soilTemp: soilTemp,
      soilHumi: soilHumi,
      windSpeed: windSpeed,
      windDir: windDir,
      lux: lux,
      ec: ec,
      ph: ph,
      n: n,
      p: p,
      k: k,
      vpdKpa: vpdKpa,
      solarWm2Est: solarWm2Est,
      etoMmDayEst: etoMmDayEst,
    );
  }

  // Helper to convert dynamic fields safely to double
  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // To JSON map for database saving or network transfer
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'air_temp': airTemp,
      'air_humi': airHumi,
      'soil_temp': soilTemp,
      'soil_humi': soilHumi,
      'wind_speed': windSpeed,
      'wind_dir': windDir,
      'lux': lux,
      'ec': ec,
      'ph': ph,
      'n': n,
      'p': p,
      'k': k,
      'vpd_kpa': vpd,
      'solar_wm2_est': solarWm2Est,
      'eto_mm_day_est': etoMmDayEst,
    };
  }
}
