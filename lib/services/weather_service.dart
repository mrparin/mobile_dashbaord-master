import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WeatherForecastDay {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double humidity;
  final String condition;
  final String description;
  final double windSpeed;
  final int rainChance;

  WeatherForecastDay({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.windSpeed,
    required this.rainChance,
  });

  factory WeatherForecastDay.fromJson(Map<String, dynamic> json) {
    return WeatherForecastDay(
      date: DateTime.parse(json['date']),
      tempMin: (json['temp_min'] as num).toDouble(),
      tempMax: (json['temp_max'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      condition: json['condition'].toString(),
      description: json['description'].toString(),
      windSpeed: (json['wind_speed'] as num).toDouble(),
      rainChance: (json['rain_chance'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'temp_min': tempMin,
      'temp_max': tempMax,
      'humidity': humidity,
      'condition': condition,
      'description': description,
      'wind_speed': windSpeed,
      'rain_chance': rainChance,
    };
  }
}

class WeatherService {
  WeatherService._privateConstructor();
  static final WeatherService instance = WeatherService._privateConstructor();
  String _lastForecastSource = 'Unknown';

  String get lastForecastSource => _lastForecastSource;

  // Fetches daily forecast from TMD first, then falls back to OpenWeatherMap,
  // Open-Meteo, and finally local simulation.
  Future<List<WeatherForecastDay>> get7DayForecast({
    required String province,
    String? district,
    String? subdistrict,
    String? provinceEn,
    String? districtEn,
    String? subdistrictEn,
  }) async {
    final String tmdToken = dotenv.get('TMD_API_TOKEN', fallback: '').trim();
    final String apiKey = dotenv
        .get('OPENWEATHERMAP_API_KEY', fallback: '')
        .trim();
    final String requestLocation = _buildLocationLabel(
      province: province,
      district: district,
      subdistrict: subdistrict,
    );

    // Build the Thai fallback order for TMD place queries.
    final List<Map<String, String>> tmdPlaceFallbacks = [];
    if (subdistrict != null &&
        subdistrict.isNotEmpty &&
        district != null &&
        district.isNotEmpty) {
      tmdPlaceFallbacks.add({
        'province': province,
        'amphoe': district,
        'tambon': subdistrict,
      });
    }
    if (district != null && district.isNotEmpty) {
      tmdPlaceFallbacks.add({'province': province, 'amphoe': district});
    }
    tmdPlaceFallbacks.add({'province': province});

    if (tmdToken.isNotEmpty) {
      print(
        '[Forecast] source=TMD status=trying location=$requestLocation fallbacks=$tmdPlaceFallbacks',
      );
      final tmdForecast = await _fetchTmdForecast(
        token: tmdToken,
        placeFallbacks: tmdPlaceFallbacks,
      );
      if (tmdForecast != null && tmdForecast.isNotEmpty) {
        _lastForecastSource = 'TMD';
        print(
          '[Forecast] source=TMD status=selected location=$requestLocation days=${tmdForecast.length}',
        );
        return tmdForecast;
      }
    } else {
      print(
        '[Forecast] source=TMD status=skipped reason=missing-token location=$requestLocation',
      );
    }

    // Build the English fallback order for non-TMD providers.
    final List<String> queryFallbacks = [];
    if (subdistrictEn != null &&
        subdistrictEn.isNotEmpty &&
        districtEn != null &&
        districtEn.isNotEmpty &&
        provinceEn != null &&
        provinceEn.isNotEmpty) {
      queryFallbacks.add('$subdistrictEn, $districtEn, $provinceEn');
    }
    if (districtEn != null &&
        districtEn.isNotEmpty &&
        provinceEn != null &&
        provinceEn.isNotEmpty) {
      queryFallbacks.add('$districtEn, $provinceEn');
    }
    if (provinceEn != null && provinceEn.isNotEmpty) {
      queryFallbacks.add(provinceEn);
    }
    queryFallbacks.add(province); // Fallback to Thai province name

    print(
      '[Forecast] source=fallback status=trying location=$requestLocation queries=$queryFallbacks',
    );

    if (apiKey.isNotEmpty) {
      for (final targetLocation in queryFallbacks) {
        try {
          final String url =
              'https://api.openweathermap.org/data/2.5/forecast?q=${Uri.encodeQueryComponent(targetLocation)},TH&units=metric&appid=$apiKey';
          print('Trying OpenWeatherMap for: $targetLocation');
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = jsonDecode(response.body);
            if (data.containsKey('list')) {
              final List<dynamic> list = data['list'];

              // Group entries by date (YYYY-MM-DD)
              final Map<String, List<Map<String, dynamic>>> grouped = {};
              for (final item in list) {
                final String dtTxt = item['dt_txt'].toString();
                if (dtTxt.length >= 10) {
                  final String dateKey = dtTxt.substring(0, 10);
                  grouped
                      .putIfAbsent(dateKey, () => [])
                      .add(item as Map<String, dynamic>);
                }
              }

              final List<WeatherForecastDay> forecastDays = [];
              for (final entry in grouped.entries) {
                final String dateStr = entry.key;
                final List<Map<String, dynamic>> dayItems = entry.value;

                double tempMin = 99.0;
                double tempMax = -99.0;
                double totalHumidity = 0.0;
                double totalWindSpeed = 0.0;
                double maxRainChance = 0.0;

                // Use the time slot with the highest rain chance as the day's representative weather.
                Map<String, dynamic> representativeItem = dayItems.first;
                for (final item in dayItems) {
                  final mainData = item['main'] as Map<String, dynamic>;
                  final double tMin = (mainData['temp_min'] as num).toDouble();
                  final double tMax = (mainData['temp_max'] as num).toDouble();
                  final double humi = (mainData['humidity'] as num).toDouble();

                  final windData = item['wind'] as Map<String, dynamic>;
                  final double wSpeed = (windData['speed'] as num).toDouble();

                  final double pop = (item['pop'] as num?)?.toDouble() ?? 0.0;

                  if (tMin < tempMin) tempMin = tMin;
                  if (tMax > tempMax) tempMax = tMax;
                  totalHumidity += humi;
                  totalWindSpeed += wSpeed;
                  if (pop > maxRainChance) {
                    maxRainChance = pop;
                    representativeItem = item;
                  }
                }

                final double avgHumidity = totalHumidity / dayItems.length;
                final double avgWindSpeed =
                    (totalWindSpeed / dayItems.length) * 3.6; // m/s to km/h

                final weatherArray =
                    representativeItem['weather'] as List<dynamic>;
                final weatherMain = weatherArray.isNotEmpty
                    ? weatherArray[0]['main'].toString()
                    : 'Clouds';

                forecastDays.add(
                  WeatherForecastDay(
                    date: DateTime.tryParse(dateStr) ?? DateTime.now(),
                    tempMin: double.parse(tempMin.toStringAsFixed(1)),
                    tempMax: double.parse(tempMax.toStringAsFixed(1)),
                    humidity: double.parse(avgHumidity.toStringAsFixed(1)),
                    condition: _mapOwmCondition(weatherMain),
                    description: _mapOwmDescription(weatherMain),
                    windSpeed: double.parse(avgWindSpeed.toStringAsFixed(1)),
                    rainChance: (maxRainChance * 100).toInt().clamp(0, 100),
                  ),
                );
              }

              if (forecastDays.isNotEmpty) {
                _lastForecastSource = 'OpenWeatherMap';
                print(
                  '[Forecast] source=OpenWeatherMap status=selected location=$targetLocation days=${forecastDays.length}',
                );
                return forecastDays;
              }
            }
          } else {
            print(
              '[Forecast] source=OpenWeatherMap status=miss location=$targetLocation code=${response.statusCode}',
            );
          }
        } catch (e) {
          print(
            '[Forecast] source=OpenWeatherMap status=error location=$targetLocation error=$e',
          );
        }
      }
    } else {
      print(
        '[Forecast] source=OpenWeatherMap status=skipped reason=missing-api-key location=$requestLocation',
      );
    }

    // Fall back to Open-Meteo API
    print(
      '[Forecast] source=Open-Meteo status=trying location=$requestLocation',
    );
    final openMeteoForecast = await _fetchOpenMeteoForecast(queryFallbacks);
    if (openMeteoForecast != null && openMeteoForecast.isNotEmpty) {
      _lastForecastSource = 'Open-Meteo';
      print(
        '[Forecast] source=Open-Meteo status=selected location=$requestLocation days=${openMeteoForecast.length}',
      );
      return openMeteoForecast;
    }

    // Direct fallback to simulation if both APIs fail or are unreachable
    print(
      '[Forecast] source=simulation status=selected location=$requestLocation reason=all-apis-failed',
    );
    _lastForecastSource = 'Simulation';
    return _generateSimulatedForecast(province, district, subdistrict);
  }

  Future<List<WeatherForecastDay>?> _fetchTmdForecast({
    required String token,
    required List<Map<String, String>> placeFallbacks,
  }) async {
    const String baseUrl =
        'https://data.tmd.go.th/nwpapi/v1/forecast/location/daily/place';

    for (final place in placeFallbacks) {
      try {
        final uri = Uri.parse(baseUrl).replace(
          queryParameters: {
            ...place,
            'duration': '7',
            'fields': 'tc_min,tc_max,rh,cond,ws10m,rain',
          },
        );

        print('Trying TMD forecast for place: $place');
        final response = await http
            .get(
              uri,
              headers: {
                'accept': 'application/json',
                'authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode != 200) {
          print(
            'TMD API returned ${response.statusCode} for $place. Trying next fallback...',
          );
          continue;
        }

        final Map<String, dynamic> decoded =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> forecastLocations = _extractTmdForecastLocations(
          decoded,
        );

        if (forecastLocations.isEmpty) {
          print('TMD API returned no forecast locations for $place.');
          continue;
        }

        final Map<String, dynamic> firstLocation =
            forecastLocations.first as Map<String, dynamic>;
        final List<dynamic> forecasts =
            firstLocation['forecasts'] as List<dynamic>? ?? const [];
        final List<WeatherForecastDay> parsedForecasts = [];

        for (final entry in forecasts) {
          final Map<String, dynamic> forecastEntry =
              entry as Map<String, dynamic>;
          final Map<String, dynamic> data =
              forecastEntry['data'] as Map<String, dynamic>? ?? const {};
          final DateTime? parsedDate = DateTime.tryParse(
            forecastEntry['time']?.toString() ?? '',
          );
          if (parsedDate == null) {
            continue;
          }

          final int conditionCode = _readInt(data, const ['cond']);
          final double rainVolume = _readDouble(data, const ['rain']);
          final double windSpeedMs = _readDouble(data, const ['ws10m']);

          parsedForecasts.add(
            WeatherForecastDay(
              date: parsedDate,
              tempMin: _readDouble(data, const ['tc_min', 'tc']),
              tempMax: _readDouble(data, const ['tc_max', 'tc']),
              humidity: _readDouble(data, const ['rh']),
              condition: _mapTmdCondition(conditionCode),
              description: _mapTmdDescription(conditionCode, rainVolume),
              windSpeed: double.parse((windSpeedMs * 3.6).toStringAsFixed(1)),
              rainChance: _estimateTmdRainChance(conditionCode, rainVolume),
            ),
          );
        }

        if (parsedForecasts.isNotEmpty) {
          return parsedForecasts;
        }
      } catch (e) {
        print('Error fetching TMD forecast for $place: $e. Trying next...');
      }
    }

    return null;
  }

  // Fetch forecast from Open-Meteo using cascading geocoding to resolve coordinates
  Future<List<WeatherForecastDay>?> _fetchOpenMeteoForecast(
    List<String> locationFallbacks,
  ) async {
    for (final locationName in locationFallbacks) {
      try {
        // 1. Geocode location name to latitude and longitude
        final geocodingUrl =
            'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(locationName)}&count=1&language=en';
        print('Trying Open-Meteo geocoding search for: $locationName');
        final geoResponse = await http
            .get(Uri.parse(geocodingUrl))
            .timeout(const Duration(seconds: 4));

        if (geoResponse.statusCode == 200) {
          final geoData = jsonDecode(geoResponse.body) as Map<String, dynamic>;
          if (geoData.containsKey('results') &&
              (geoData['results'] as List).isNotEmpty) {
            final firstResult = geoData['results'][0];
            final double latitude = (firstResult['latitude'] as num).toDouble();
            final double longitude = (firstResult['longitude'] as num)
                .toDouble();
            print('Geocoded "$locationName" to: ($latitude, $longitude)');

            // 2. Query forecast with resolved coordinates
            final forecastUrl =
                'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,relative_humidity_2m_max,wind_speed_10m_max,precipitation_probability_max,weather_code&timezone=Asia%2FBangkok';
            final forecastResponse = await http
                .get(Uri.parse(forecastUrl))
                .timeout(const Duration(seconds: 5));

            if (forecastResponse.statusCode == 200) {
              final data =
                  jsonDecode(forecastResponse.body) as Map<String, dynamic>;
              if (data.containsKey('daily')) {
                final daily = data['daily'] as Map<String, dynamic>;
                final times = daily['time'] as List<dynamic>;
                final tempMaxs = daily['temperature_2m_max'] as List<dynamic>;
                final tempMins = daily['temperature_2m_min'] as List<dynamic>;
                final humidities =
                    daily['relative_humidity_2m_max'] as List<dynamic>;
                final windSpeeds = daily['wind_speed_10m_max'] as List<dynamic>;
                final rainChances =
                    daily['precipitation_probability_max'] as List<dynamic>;
                final codes = daily['weather_code'] as List<dynamic>;

                final List<WeatherForecastDay> list = [];
                for (int i = 0; i < times.length; i++) {
                  final int code = (codes[i] as num).toInt();
                  list.add(
                    WeatherForecastDay(
                      date:
                          DateTime.tryParse(times[i].toString()) ??
                          DateTime.now(),
                      tempMin: (tempMins[i] as num).toDouble(),
                      tempMax: (tempMaxs[i] as num).toDouble(),
                      humidity: (humidities[i] as num).toDouble(),
                      condition: _mapWmoCodeToCondition(code),
                      description: _mapWmoCodeToDescription(code),
                      windSpeed: (windSpeeds[i] as num).toDouble(),
                      rainChance: (rainChances[i] as num).toInt(),
                    ),
                  );
                }
                print(
                  '[Forecast] source=Open-Meteo status=resolved location=$locationName days=${list.length}',
                );
                return list;
              }
            }
          }
        }
      } catch (e) {
        print(
          'Open-Meteo geocoding/forecast error for "$locationName": $e. Trying next fallback...',
        );
      }
    }
    return null;
  }

  String _mapOwmCondition(String main) {
    switch (main.toLowerCase()) {
      case 'thunderstorm':
        return 'Thunderstorm';
      case 'rain':
      case 'drizzle':
        return 'Rainy';
      case 'clear':
        return 'Sunny';
      case 'clouds':
        return 'Cloudy';
      default:
        return 'Cloudy';
    }
  }

  String _mapOwmDescription(String main) {
    switch (main.toLowerCase()) {
      case 'thunderstorm':
        return 'มีฝนฟ้าคะนองกระจายและมีฝนตกหนักบางแห่ง';
      case 'rain':
      case 'drizzle':
        return 'มีฝนตกฟ้าคะนองเป็นแห่งๆ';
      case 'clear':
        return 'ท้องฟ้าแจ่มใส แดดจัด';
      case 'clouds':
        return 'มีเมฆบางส่วน อากาศค่อนข้างร้อน';
      default:
        return 'มีเมฆบางส่วน';
    }
  }

  List<dynamic> _extractTmdForecastLocations(Map<String, dynamic> decoded) {
    final dynamic lowerCaseRoot = decoded['weather_forecast'];
    if (lowerCaseRoot is Map<String, dynamic>) {
      final dynamic locations = lowerCaseRoot['locations'];
      if (locations is List<dynamic>) {
        return locations;
      }
    }

    final dynamic upperCaseRoot = decoded['WeatherForecasts'];
    if (upperCaseRoot is List<dynamic>) {
      return upperCaseRoot;
    }
    if (upperCaseRoot is Map<String, dynamic>) {
      final dynamic locations = upperCaseRoot['locations'];
      if (locations is List<dynamic>) {
        return locations;
      }
    }

    final dynamic singularRoot = decoded['WeatherForecast'];
    if (singularRoot is Map<String, dynamic>) {
      final dynamic locations = singularRoot['locations'];
      if (locations is List<dynamic>) {
        return locations;
      }
      return [singularRoot];
    }

    return const [];
  }

  String _buildLocationLabel({
    required String province,
    String? district,
    String? subdistrict,
  }) {
    final List<String> parts = [
      if (subdistrict != null && subdistrict.isNotEmpty) subdistrict,
      if (district != null && district.isNotEmpty) district,
      province,
    ];
    return parts.join(' / ');
  }

  double _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final dynamic value = data[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0.0;
  }

  int _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final dynamic value = data[key];
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }

  String _mapTmdCondition(int code) {
    switch (code) {
      case 1:
        return 'Sunny';
      case 2:
      case 3:
      case 4:
        return 'Cloudy';
      case 5:
      case 6:
      case 7:
        return 'Rainy';
      case 8:
        return 'Thunderstorm';
      default:
        return 'Cloudy';
    }
  }

  String _mapTmdDescription(int code, double rainVolume) {
    switch (code) {
      case 1:
        return 'ท้องฟ้าแจ่มใส';
      case 2:
        return 'มีเมฆบางส่วน';
      case 3:
        return 'เมฆเป็นส่วนมาก';
      case 4:
        return 'มีเมฆมาก';
      case 5:
        return 'มีฝนเล็กน้อย';
      case 6:
        return 'มีฝนปานกลาง';
      case 7:
        return 'มีฝนตกหนัก';
      case 8:
        return 'มีฝนฟ้าคะนอง';
      default:
        if (rainVolume > 0) {
          return 'มีโอกาสเกิดฝน';
        }
        return 'มีเมฆบางส่วน';
    }
  }

  int _estimateTmdRainChance(int code, double rainVolume) {
    if (code == 8) return 95;
    if (code == 7 || rainVolume >= 20) return 90;
    if (code == 6 || rainVolume >= 10) return 75;
    if (code == 5 || rainVolume > 0) return 60;
    if (code == 4) return 40;
    if (code == 3) return 30;
    if (code == 2) return 15;
    if (code == 1) return 5;
    return 20;
  }

  String _mapWmoCodeToCondition(int code) {
    if (code == 0) return 'Sunny';
    if (code >= 1 && code <= 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Cloudy';
    if (code >= 51 && code <= 65) return 'Rainy';
    if (code >= 80 && code <= 82) return 'Rainy';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  String _mapWmoCodeToDescription(int code) {
    if (code == 0) return 'ท้องฟ้าแจ่มใส แดดจัด';
    if (code >= 1 && code <= 3) return 'มีเมฆบางส่วน อากาศค่อนข้างร้อน';
    if (code == 45 || code == 48) return 'มีหมอกในตอนเช้า';
    if (code >= 51 && code <= 55) return 'มีฝนตกปรอยๆ';
    if (code >= 61 && code <= 65) return 'มีฝนตกฟ้าคะนองเป็นแห่งๆ';
    if (code >= 80 && code <= 82) return 'มีฝนตกฟ้าคะนองเป็นแห่งๆ';
    if (code >= 95 && code <= 99) {
      return 'มีฝนฟ้าคะนองกระจายและมีฝนตกหนักบางแห่ง';
    }
    return 'มีเมฆบางส่วน';
  }

  // Generates high-fidelity simulated weather forecasts based on location
  List<WeatherForecastDay> _generateSimulatedForecast(
    String province,
    String? district,
    String? subdistrict,
  ) {
    // Generate deterministic seed based on location name so the forecast remains stable
    final String seedString =
        '${subdistrict ?? ''}-${district ?? ''}-$province';
    final int seed = seedString.codeUnits.fold(
      0,
      (prev, element) => prev + element,
    );
    final math.Random random = math.Random(seed);

    final List<WeatherForecastDay> forecast = [];
    final List<String> conditions = [
      'Sunny',
      'Cloudy',
      'Rainy',
      'Thunderstorm',
      'Windy',
    ];
    final List<String> descriptions = [
      'ท้องฟ้าแจ่มใส แดดจัด',
      'มีเมฆบางส่วน อากาศค่อนข้างร้อน',
      'มีฝนตกฟ้าคะนองเป็นแห่งๆ',
      'มีฝนฟ้าคะนองกระจายและมีฝนตกหนักบางแห่ง',
      'ลมแรง ท้องฟ้ามีเมฆหนา',
    ];

    // Adapt temperatures depending on the province
    double baseTempMax = 33.0;
    double baseTempMin = 24.0;
    double baseHumi = 78.0;

    if (province == 'กรุงเทพมหานคร') {
      baseTempMax = 35.0;
      baseTempMin = 26.0;
      baseHumi = 70.0;
    } else if (province == 'ชุมพร') {
      baseTempMax = 32.0;
      baseTempMin = 23.0;
      baseHumi = 82.0;
    } else if (province == 'ระยอง') {
      baseTempMax = 32.5;
      baseTempMin = 24.5;
      baseHumi = 80.0;
    }

    // Micro-climates: adjust slightly if a district/subdistrict is selected
    if (district != null) {
      // Seeded variations
      baseTempMax += (random.nextDouble() - 0.5) * 1.5;
      baseHumi += (random.nextDouble() - 0.5) * 4.0;
    }
    if (subdistrict != null) {
      baseTempMax += (random.nextDouble() - 0.5) * 1.0;
      baseHumi += (random.nextDouble() - 0.5) * 3.0;
    }

    final DateTime today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final DateTime date = today.add(Duration(days: i));

      // Add slight daily variance
      final double dayTempMax = baseTempMax + (random.nextDouble() - 0.5) * 2.0;
      final double dayTempMin = baseTempMin + (random.nextDouble() - 0.5) * 1.5;
      final double dayHumi = (baseHumi + (random.nextDouble() - 0.5) * 6.0)
          .clamp(40.0, 100.0);
      final double windSpeed = 5.0 + random.nextDouble() * 15.0;

      // Higher humidity -> higher rain chance
      int rainChance = ((dayHumi - 50.0) * 1.8 + random.nextInt(20))
          .clamp(0, 100)
          .toInt();

      // Determine condition index
      int conditionIdx = 1; // Default to Cloudy
      if (rainChance > 75) {
        conditionIdx = 3; // Thunderstorm
      } else if (rainChance > 50) {
        conditionIdx = 2; // Rainy
      } else if (rainChance < 20) {
        conditionIdx = 0; // Sunny
      } else if (windSpeed > 15) {
        conditionIdx = 4; // Windy
      }

      forecast.add(
        WeatherForecastDay(
          date: date,
          tempMin: double.parse(dayTempMin.toStringAsFixed(1)),
          tempMax: double.parse(dayTempMax.toStringAsFixed(1)),
          humidity: double.parse(dayHumi.toStringAsFixed(1)),
          condition: conditions[conditionIdx],
          description: descriptions[conditionIdx],
          windSpeed: double.parse(windSpeed.toStringAsFixed(1)),
          rainChance: rainChance,
        ),
      );
    }

    return forecast;
  }
}
