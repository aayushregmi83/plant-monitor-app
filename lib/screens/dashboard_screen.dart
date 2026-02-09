import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sensor_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/control_card.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_theme.dart';

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
    if (!mounted) return;
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
    final intensity =
        _sensorData != null && _sensorData!['light_intensity'] != null
        ? '${_sensorData!['light_intensity']} %'
        : '--';
    final connected = _status != null && _status!['status'] == 'running';
    final isSimulated =
        _sensorData != null &&
        (_sensorData!['simulated'] == true ||
            _sensorData!['data_source'] == 'simulated');
    final dataSource = isSimulated ? 'Simulated Data' : 'Real Data';
    final dataColor = isSimulated ? AppColors.warning : AppColors.primary;

    return AppScaffold(
      title: 'Plant Monitor Dashboard',
      subtitle: 'Real-time greenhouse overview',
      currentRoute: '/',
      trailing: _StatusBadge(connected: connected),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardWidth = width > 900
                  ? (width - 32) / 3
                  : width > 600
                  ? (width - 16) / 2
                  : width;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      label: 'Temperature',
                      value: temp,
                      icon: Icons.thermostat,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      label: 'Humidity',
                      value: humidity,
                      icon: Icons.water_drop,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      label: 'Soil Moisture',
                      value: moisture,
                      icon: Icons.grass,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      label: 'Bulb Intensity',
                      value: intensity,
                      icon: Icons.lightbulb,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.memory, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text(
                        'System Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: dataColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: dataColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        dataSource,
                        style: TextStyle(
                          color: dataColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoChip(
                        label: 'Device connected',
                        value:
                            _status != null &&
                                _status!['camera_connected'] == true
                            ? 'Yes'
                            : 'No',
                      ),
                      _InfoChip(
                        label: 'Streaming',
                        value:
                            _status != null &&
                                _status!['camera_streaming'] == true
                            ? 'Yes'
                            : 'No',
                      ),
                      _InfoChip(
                        label: 'Detector',
                        value:
                            _status != null &&
                                _status!['detector_available'] == true
                            ? 'Available'
                            : 'Offline',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videocam),
                  label: const Text('Live Feed'),
                  onPressed: () => Navigator.pushNamed(context, '/camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.healing),
                  label: const Text('Health Analysis'),
                  onPressed: () => Navigator.pushNamed(context, '/health'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ControlCard(sensorService: _sensor),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool connected;
  const _StatusBadge({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: connected ? AppColors.primary : AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            connected ? 'Connected' : 'Offline',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.light, AppColors.light.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
