import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'models/telemetry_model.dart';
import 'pages/history_view.dart';
import 'services/database_service.dart';
import 'services/mqtt_service.dart';
import 'services/influx_service.dart';
import 'widgets/forecast_card.dart';
import 'widgets/gauge_card.dart';
import 'widgets/relationship_chart.dart';
import 'widgets/vpd_status_card.dart';
import 'widgets/environment_details_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Thai locale for date formatting
  await initializeDateFormatting('th_TH', null);

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
    print(".env loaded successfully.");
  } catch (e) {
    print("Warning: Could not load .env file: $e");
  }

  // Pre-initialize database
  try {
    await DatabaseService.instance.database;
    await DatabaseService.instance.seedMockDataIfEmpty();
  } catch (e) {
    print("Database initialization error: $e");
  }

  // Asynchronously sync missing data from InfluxDB
  InfluxService.instance.syncMissingData().catchError((e) {
    print("Failed to sync missing data: $e");
  });

  runApp(const DurianApp());
}

class DurianApp extends StatelessWidget {
  const DurianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phanmanee Durian Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E4620), // Durian Dark Green
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF8D6E63), // Clay/Soil Brown
          surface: const Color(0xFFF1F8E9), // Light Leaf Green background
        ),
        cardColor: Colors.white,
        fontFamily: 'Roboto', // Premium neutral system font
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF1E4620),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFA1887F),
          surface: const Color(0xFF111411), // Deep dark green-black background
        ),
        cardColor: Colors.grey[900],
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system, // respect system preferences
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [DashboardView(), HistoryView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'แผงควบคุม',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'ข้อมูลย้อนหลัง',
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final List<SensorTelemetry> _recentHistory = [];

  @override
  void initState() {
    super.initState();
    // Connect to MQTT broker
    MqttService.instance.connect();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Keep a small sliding window of recent telemetry points for UI charts
  void _updateRecentHistory(SensorTelemetry point) {
    if (_recentHistory.contains(point)) return;
    _recentHistory.add(point);
    if (_recentHistory.length > 50) {
      _recentHistory.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/durian_tree.jpg', // Durian tree icon
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.eco, color: Colors.green),
            ),
            const SizedBox(width: 10),
            const Text(
              'สวนพรรณมณี',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          // Live MQTT Connection status indicator
          ValueListenableBuilder<String>(
            valueListenable: MqttService.instance.connectionStateNotifier,
            builder: (context, status, child) {
              final isConnected = status == 'Connected';
              Color indicatorColor = Colors.orange;

              if (isConnected) {
                indicatorColor = Colors.green;
              } else if (status.contains('Failed') || status.contains('mock')) {
                indicatorColor = Colors.blue;
              }

              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: indicatorColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: indicatorColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected
                          ? 'MQTT เชื่อมต่อ'
                          : (status.contains('mock')
                                ? 'จำลองข้อมูล'
                                : 'กำลังเชื่อมต่อ'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<SensorTelemetry>(
        stream: MqttService.instance.telemetryStream,
        initialData: MqttService.instance.latestTelemetry,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังเชื่อมต่อเซิร์ฟเวอร์ MQTT...'),
                ],
              ),
            );
          }

          final telemetry = snapshot.data;
          if (telemetry == null) {
            return const Center(child: Text('ไม่มีข้อมูลส่งมาจากอุปกรณ์'));
          }

          // Add reading to the local state history for scatter plots
          _updateRecentHistory(telemetry);

          return RefreshIndicator(
            onRefresh: () async {
              MqttService.instance.disconnect();
              await MqttService.instance.connect();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.sync,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'อัปเดตล่าสุด: ${DateFormat('HH:mm:ss น.').format(telemetry.timestamp)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 1. Live Gauges Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      final int crossAxisCount = width >= 1000
                          ? 4
                          : width >= 700
                          ? 3
                          : 2;
                      final double childAspectRatio = width >= 700 ? 1.1 : 1.0;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: childAspectRatio,
                        children: [
                          GaugeCard(
                            title: 'อุณหภูมิอากาศ',
                            value: telemetry.airTemp,
                            min: 0,
                            max: 50,
                            unit: '°C',
                            color: Colors.orange[700]!,
                            icon: Icons.thermostat_outlined,
                          ),
                          GaugeCard(
                            title: 'ความชื้นอากาศ',
                            value: telemetry.airHumi,
                            min: 0,
                            max: 100,
                            unit: '%',
                            color: Colors.blue[600]!,
                            icon: Icons.cloudy_snowing,
                          ),
                          GaugeCard(
                            title: 'อุณหภูมิดิน',
                            value: telemetry.soilTemp,
                            min: 0,
                            max: 50,
                            unit: '°C',
                            color: Colors.brown[600]!,
                            icon: Icons.landslide_outlined,
                          ),
                          GaugeCard(
                            title: 'ความชื้นในดิน',
                            value: telemetry.soilHumi,
                            min: 0,
                            max: 100,
                            unit: '%',
                            color: Colors.teal[600]!,
                            icon: Icons.grass_outlined,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 2. Vapor Pressure Deficit (VPD) Status Recommendation
                  VpdStatusCard(vpdValue: telemetry.vpd),

                  const SizedBox(height: 14),

                  // Air and Soil environment details
                  AirEnvironmentCard(telemetry: telemetry),

                  const SizedBox(height: 14),

                  SoilEnvironmentCard(telemetry: telemetry),

                  const SizedBox(height: 14),

                  // 3. 7-Day Weather Forecast with dropdown filters
                  const ForecastCard(),

                  const SizedBox(height: 14),

                  // 4. Scatter Plot: Air Temp vs. Relative Humidity
                  RelationshipChart(
                    title: 'สถิติความสัมพันธ์: อากาศ',
                    xLabel: 'อุณหภูมิอากาศ (°C)',
                    yLabel: 'ความชื้นสัมพัทธ์ในอากาศ (%)',
                    history: _recentHistory,
                    isAir: true,
                    dotColor: Colors.blue[600]!,
                  ),

                  const SizedBox(height: 14),

                  // 5. Scatter Plot: Soil Temp vs. Soil Moisture
                  RelationshipChart(
                    title: 'สถิติความสัมพันธ์: ในดิน',
                    xLabel: 'อุณหภูมิดิน (°C)',
                    yLabel: 'ความชื้นในดิน (%)',
                    history: _recentHistory,
                    isAir: false,
                    dotColor: Colors.teal[600]!,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
