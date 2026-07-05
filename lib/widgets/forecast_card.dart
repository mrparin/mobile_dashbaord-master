import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';

class ForecastCard extends StatefulWidget {
  const ForecastCard({super.key});

  @override
  State<ForecastCard> createState() => _ForecastCardState();
}

class _ForecastCardState extends State<ForecastCard> {
  // Cascading location state
  List<dynamic> _locations = [];
  List<String> _provinces = [];
  List<String> _districts = [];
  List<String> _subdistricts = [];

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  List<WeatherForecastDay> _forecast = [];
  String _forecastSource = 'Unknown';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLocations());
  }

  Future<void> unawaited(Future<void> future) async {
    await future;
  }

  // Load locations from assets/thailand_locations.json
  Future<void> _loadLocations() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/thailand_locations.json',
      );
      final data = jsonDecode(response) as List<dynamic>;

      final prefs = await SharedPreferences.getInstance();
      final savedProvince = prefs.getString('selected_province');
      final savedDistrict = prefs.getString('selected_district');
      final savedSubdistrict = prefs.getString('selected_subdistrict');

      setState(() {
        _locations = data;
        _provinces = data.map((item) => item['name_th'].toString()).toList();

        if (savedProvince != null && _provinces.contains(savedProvince)) {
          _selectedProvince = savedProvince;

          // Update districts list
          final provinceData = _locations.firstWhere(
            (item) => item['name_th'] == _selectedProvince,
            orElse: () => null,
          );
          if (provinceData != null) {
            final List<dynamic> districtList = provinceData['districts'] ?? [];
            _districts = districtList
                .map((item) => item['name_th'].toString())
                .toList();

            if (savedDistrict != null && _districts.contains(savedDistrict)) {
              _selectedDistrict = savedDistrict;

              // Update subdistricts list
              final districtData = districtList.firstWhere(
                (item) => item['name_th'] == _selectedDistrict,
                orElse: () => null,
              );
              if (districtData != null) {
                final List<dynamic> subList =
                    districtData['sub_districts'] ?? [];
                _subdistricts = subList
                    .map((item) => item['name_th'].toString())
                    .toList();

                if (savedSubdistrict != null &&
                    _subdistricts.contains(savedSubdistrict)) {
                  _selectedSubdistrict = savedSubdistrict;
                }
              }
            }
          }
        } else {
          // Auto-select Chanthaburi as default
          if (_provinces.contains('จันทบุรี')) {
            _selectedProvince = 'จันทบุรี';
            _updateDistricts();
          }
        }
      });

      await _fetchForecast();
    } catch (e) {
      print('Error loading locations JSON: $e');
    }
  }

  Future<void> _saveLocationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedProvince != null) {
      await prefs.setString('selected_province', _selectedProvince!);
    } else {
      await prefs.remove('selected_province');
    }
    if (_selectedDistrict != null) {
      await prefs.setString('selected_district', _selectedDistrict!);
    } else {
      await prefs.remove('selected_district');
    }
    if (_selectedSubdistrict != null) {
      await prefs.setString('selected_subdistrict', _selectedSubdistrict!);
    } else {
      await prefs.remove('selected_subdistrict');
    }
  }

  void _updateDistricts() {
    if (_selectedProvince == null) return;

    final provinceData = _locations.firstWhere(
      (item) => item['name_th'] == _selectedProvince,
      orElse: () => null,
    );

    setState(() {
      if (provinceData != null) {
        final List<dynamic> districtList = provinceData['districts'] ?? [];
        _districts = districtList
            .map((item) => item['name_th'].toString())
            .toList();
      } else {
        _districts = [];
      }
      _selectedDistrict = null;
      _subdistricts = [];
      _selectedSubdistrict = null;
    });
  }

  void _updateSubdistricts() {
    if (_selectedProvince == null || _selectedDistrict == null) return;

    final provinceData = _locations.firstWhere(
      (item) => item['name_th'] == _selectedProvince,
      orElse: () => null,
    );

    if (provinceData == null) return;

    final List<dynamic> districtList = provinceData['districts'] ?? [];
    final districtData = districtList.firstWhere(
      (item) => item['name_th'] == _selectedDistrict,
      orElse: () => null,
    );

    setState(() {
      if (districtData != null) {
        final List<dynamic> subList = districtData['sub_districts'] ?? [];
        _subdistricts = subList
            .map((item) => item['name_th'].toString())
            .toList();
      } else {
        _subdistricts = [];
      }
      _selectedSubdistrict = null;
    });
  }

  Future<void> _fetchForecast() async {
    if (_selectedProvince == null) return;

    setState(() {
      _isLoading = true;
      _forecastSource = 'Loading...';
    });

    try {
      // Look up English names of selected province, district, and subdistrict
      final provinceData = _locations.firstWhere(
        (item) => item['name_th'] == _selectedProvince,
        orElse: () => null,
      );
      final String? provinceEn = provinceData != null
          ? provinceData['name_en']?.toString()
          : null;

      String? districtEn;
      String? subdistrictEn;

      if (_selectedDistrict != null && provinceData != null) {
        final List<dynamic> districtList = provinceData['districts'] ?? [];
        final districtData = districtList.firstWhere(
          (item) => item['name_th'] == _selectedDistrict,
          orElse: () => null,
        );
        districtEn = districtData != null
            ? districtData['name_en']?.toString()
            : null;

        if (_selectedSubdistrict != null && districtData != null) {
          final List<dynamic> subList = districtData['sub_districts'] ?? [];
          final subData = subList.firstWhere(
            (item) => item['name_th'] == _selectedSubdistrict,
            orElse: () => null,
          );
          subdistrictEn = subData != null
              ? subData['name_en']?.toString()
              : null;
        }
      }

      final forecastData = await WeatherService.instance.get7DayForecast(
        province: _selectedProvince!,
        district: _selectedDistrict,
        subdistrict: _selectedSubdistrict,
        provinceEn: provinceEn,
        districtEn: districtEn,
        subdistrictEn: subdistrictEn,
      );

      setState(() {
        _forecast = forecastData;
        _forecastSource = WeatherService.instance.lastForecastSource;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching forecast in widget: $e');
      setState(() {
        _forecastSource = 'Unavailable';
        _isLoading = false;
      });
    }
  }

  // Get icon depending on condition string
  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'Sunny':
        return Icons.wb_sunny_rounded;
      case 'Cloudy':
        return Icons.wb_cloudy_rounded;
      case 'Rainy':
        return Icons.umbrella_rounded;
      case 'Thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'Windy':
        return Icons.air_rounded;
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition) {
      case 'Sunny':
        return Colors.orange[400]!;
      case 'Cloudy':
        return Colors.blueGrey[300]!;
      case 'Rainy':
        return Colors.blue[300]!;
      case 'Thunderstorm':
        return Colors.deepPurple[300]!;
      case 'Windy':
        return Colors.teal[300]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'พยากรณ์อากาศล่วงหน้า ${_forecast.length} วัน',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                'Source: $_forecastSource',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cascading Dropdowns Wrapper
            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = (constraints.maxWidth - 16) / 3;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Province Dropdown
                    SizedBox(
                      width: itemWidth,
                      child: _buildDropdown(
                        label: 'จังหวัด',
                        value: _selectedProvince,
                        items: _provinces,
                        onChanged: (val) {
                          setState(() {
                            _selectedProvince = val;
                            _updateDistricts();
                          });
                          _saveLocationSettings();
                          _fetchForecast();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // District Dropdown
                    SizedBox(
                      width: itemWidth,
                      child: _buildDropdown(
                        label: 'อำเภอ',
                        value: _selectedDistrict,
                        items: _districts,
                        onChanged: _selectedProvince == null
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedDistrict = val;
                                  _updateSubdistricts();
                                });
                                _saveLocationSettings();
                                _fetchForecast();
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Subdistrict Dropdown
                    SizedBox(
                      width: itemWidth,
                      child: _buildDropdown(
                        label: 'ตำบล',
                        value: _selectedSubdistrict,
                        items: _subdistricts,
                        onChanged: _selectedDistrict == null
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedSubdistrict = val;
                                });
                                _saveLocationSettings();
                                _fetchForecast();
                              },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // Forecast List View
            _isLoading
                ? const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _forecast.isEmpty
                ? const SizedBox(
                    height: 150,
                    child: Center(child: Text('ไม่พบข้อมูลพยากรณ์อากาศ')),
                  )
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _forecast.length,
                      itemBuilder: (context, index) {
                        final day = _forecast[index];
                        final weatherColor = _getWeatherColor(day.condition);
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final dayDate = DateTime(
                          day.date.year,
                          day.date.month,
                          day.date.day,
                        );
                        final isToday = dayDate == today;
                        final dayLabel = isToday
                            ? 'วันนี้'
                            : DateFormat('EEE d', 'th_TH').format(day.date);

                        return Container(
                          width: 112,
                          margin: const EdgeInsets.only(
                            right: 12,
                            top: 4,
                            bottom: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isToday
                                ? theme.colorScheme.primary.withOpacity(0.08)
                                : isDark
                                ? Colors.grey[850]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isToday
                                  ? theme.colorScheme.primary.withOpacity(0.3)
                                  : isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  fontWeight: isToday
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isToday
                                      ? theme.colorScheme.primary
                                      : isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                _getWeatherIcon(day.condition),
                                color: weatherColor,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${day.tempMax}° / ${day.tempMin}°',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.water_drop,
                                    size: 10,
                                    color: Colors.blue[300],
                                  ),
                                  Text(
                                    ' ${day.rainChance}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.air,
                                    size: 10,
                                    color: Colors.teal[300],
                                  ),
                                  Text(
                                    ' ${day.windSpeed.toStringAsFixed(1)} km/h',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.invert_colors,
                                    size: 10,
                                    color: Colors.lightBlue[300],
                                  ),
                                  Text(
                                    ' ${day.humidity.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          value: value,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
