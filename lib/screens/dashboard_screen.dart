import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sensor_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/control_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SensorService _sensor = SensorService();
  Timer? _timer;
  Map<String, dynamic>? _sensorData;
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    final s = await _sensor.getSensorData();
    final st = await _sensor.getStatus();
    setState(() {
      _sensorData = s;
      _status = st;
    });
  }

  @override
  Widget build(BuildContext context) {
    final temp = _sensorData != null && _sensorData!['temperature'] != null
        ? '${_sensorData!['temperature']} °C'
        : '--';
    final humidity = _sensorData != null && _sensorData!['humidity'] != null
        ? '${_sensorData!['humidity']} %'
        : '--';
    final moisture =
        _sensorData != null && _sensorData!['soil_moisture'] != null
        ? '${_sensorData!['soil_moisture']} %'
        : '--';

    return Scaffold(
      appBar: AppBar(title: const Text('Plant Monitor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  label: 'Temperature',
                  value: temp,
                  icon: Icons.thermostat,
                ),
                StatCard(
                  label: 'Humidity',
                  value: humidity,
                  icon: Icons.water_drop,
                ),
                StatCard(
                  label: 'Soil Moisture',
                  value: moisture,
                  icon: Icons.grass,
                ),
              ],
            ),

            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ESP32 Info',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _status != null && _status!['status'] != null
                              ? _status!['status']
                              : '',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Device connected: ${_status != null && _status!['camera_connected'] == true ? 'Yes' : 'No'}',
                    ),
                    Text(
                      'Streaming: ${_status != null && _status!['camera_streaming'] == true ? 'Yes' : 'No'}',
                    ),
                    Text(
                      'Detector available: ${_status != null && _status!['detector_available'] == true ? 'Yes' : 'No'}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera),
                    label: const Text('Live Feed'),
                    onPressed: () => Navigator.pushNamed(context, '/camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.science),
                    label: const Text('Health Analysis'),
                    onPressed: () => Navigator.pushNamed(context, '/health'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Detect (Image)'),
              onPressed: () => Navigator.pushNamed(context, '/detect'),
            ),

            const SizedBox(height: 12),
            // Control card for fan/pump/bulb
            ControlCard(sensorService: _sensor),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Plant Monitor')),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Live Feed'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Health Analysis'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/health');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
