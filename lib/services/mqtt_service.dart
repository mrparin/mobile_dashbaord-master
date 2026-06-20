import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/telemetry_model.dart';
import 'database_service.dart';

class MqttService {
  MqttService._privateConstructor();
  static final MqttService instance = MqttService._privateConstructor();

  MqttServerClient? _client;
  final StreamController<SensorTelemetry> _telemetryStreamController =
      StreamController<SensorTelemetry>.broadcast();

  Stream<SensorTelemetry> get telemetryStream => _telemetryStreamController.stream;

  final ValueNotifier<String> connectionStateNotifier = ValueNotifier<String>('Disconnected');
  String get connectionState => connectionStateNotifier.value;

  bool _isConnecting = false;
  Timer? _mockTimer;

  SensorTelemetry? _latestTelemetry;
  SensorTelemetry? get latestTelemetry => _latestTelemetry;

  // Initialize and connect to the broker using environment variables
  Future<void> connect() async {
    if (_isConnecting || (_client?.connectionStatus?.state == MqttConnectionState.connected)) {
      return;
    }

    _isConnecting = true;
    _updateState('Connecting...');

    final String server = dotenv.get('MQTT_SERVER', fallback: 'sci-iot.ddns.net').trim();
    final int port = int.tryParse(dotenv.get('MQTT_PORT', fallback: '1883')) ?? 1883;
    final String topic = dotenv.get('MQTT_TOPIC', fallback: 'v1/devices/me/telemetry').replaceAll('"', '').trim();

    final String clientId = 'durian_monitor_mobile_${math.Random().nextInt(10000)}';

    print('MQTT Server: $server, Port: $port, Topic: $topic');

    _client = MqttServerClient.withPort(server, clientId, port);
    _client!.keepAlivePeriod = 30;
    _client!.autoReconnect = true;
    _client!.onConnected = () => _onConnected(topic);
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.pongCallback = _pong;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      print('MQTT connection exception: $e');
      _updateState('Failed to connect. Starting mock stream.');
      _isConnecting = false;
      _startMockTelemetryStream();
    }
  }

  void _onConnected(String topic) {
    _updateState('Connected');
    _isConnecting = false;
    _stopMockTelemetryStream();

    print('MQTT connected. Subscribing to topic: $topic');
    _client!.subscribe(topic, MqttQos.atLeastOnce);

    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('MQTT Received Payload: $payload');
      _processPayload(payload);
    });
  }

  void _onDisconnected() {
    _updateState('Disconnected');
    print('MQTT disconnected. Starting fallback mock stream.');
    _startMockTelemetryStream();
  }

  void _onSubscribed(String topic) {
    print('MQTT successfully subscribed to: $topic');
  }

  void _pong() {
    print('MQTT Ping response received');
  }

  void _updateState(String state) {
    connectionStateNotifier.value = state;
  }

  void disconnect() {
    _client?.disconnect();
    _stopMockTelemetryStream();
    _updateState('Disconnected');
  }

  // Emit a telemetry point manually (e.g. from historical synchronization)
  void emitTelemetry(SensorTelemetry telemetry) {
    _latestTelemetry = telemetry;
    _telemetryStreamController.add(telemetry);
  }

  // Parse payload, calculate VPD, stream it, and log it to local DB
  void _processPayload(String payload) {
    try {
      final dynamic data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        final telemetry = SensorTelemetry.fromJson(data);
        _latestTelemetry = telemetry;
        
        // Add to stream
        _telemetryStreamController.add(telemetry);

        // Save to SQLite
        DatabaseService.instance.insertTelemetry(telemetry);
      }
    } catch (e) {
      print('Error parsing MQTT payload: $e');
    }
  }

  // Fallback simulator to ensure UI works when MQTT is not reachable or offline
  void _startMockTelemetryStream() {
    _mockTimer?.cancel();
    
    // Send one immediately
    _generateAndSendMockData();

    // Send a new reading every 10 seconds for real-time demonstration
    _mockTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _generateAndSendMockData();
    });
  }

  void _stopMockTelemetryStream() {
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  void _generateAndSendMockData() {
    final now = DateTime.now();
    final hour = now.hour;

    // Daily cycle simulations
    final double baseTemp = 25.0 + 8.0 * math.sin((hour - 8) * math.pi / 12);
    final double airTemp = baseTemp + (math.Random().nextDouble() - 0.5) * 1.5;
    
    final double baseHumi = 85.0 - 30.0 * math.sin((hour - 8) * math.pi / 12);
    final double airHumi = baseHumi.clamp(30.0, 100.0) + (math.Random().nextDouble() - 0.5) * 3.0;

    final double soilTemp = 24.0 + 2.0 * math.sin((hour - 10) * math.pi / 12) + (math.Random().nextDouble() - 0.5) * 0.5;
    final double soilHumi = 65.0 - 5.0 * math.sin((hour - 6) * math.pi / 24) + (math.Random().nextDouble() - 0.5) * 1.0;

    final telemetry = SensorTelemetry(
      timestamp: now,
      airTemp: airTemp,
      airHumi: airHumi,
      soilTemp: soilTemp,
      soilHumi: soilHumi,
      windSpeed: 1.0 + math.Random().nextDouble() * 3.0,
      windDir: 195.0 + (math.Random().nextDouble() - 0.5) * 30.0,
      lux: hour > 6 && hour < 18 ? 2000.0 * math.sin((hour - 6) * math.pi / 12) * 20.0 : 0.0,
      ec: 0.82 + (math.Random().nextDouble() - 0.5) * 0.05,
      ph: 6.3 + (math.Random().nextDouble() - 0.5) * 0.1,
      n: 25.0,
      p: 15.0,
      k: 30.0,
      solarWm2Est: hour > 6 && hour < 18 ? 550.0 * math.sin((hour - 6) * math.pi / 12) : 0.0,
      etoMmDayEst: 3.2,
    );

    _latestTelemetry = telemetry;
    _telemetryStreamController.add(telemetry);
    
    // Save simulated readings to database too!
    DatabaseService.instance.insertTelemetry(telemetry);
  }
}
