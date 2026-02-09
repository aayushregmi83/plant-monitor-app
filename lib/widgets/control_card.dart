import 'package:flutter/material.dart';
import '../services/sensor_service.dart';
import '../theme/app_theme.dart';

class ControlCard extends StatefulWidget {
  final String deviceId;
  final SensorService sensorService;
  const ControlCard({
    Key? key,
    this.deviceId = 'sensor_node_1',
    required this.sensorService,
  }) : super(key: key);

  @override
  State<ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<ControlCard> {
  Map<String, dynamic> _commands = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCommands();
  }

  Future<void> _loadCommands() async {
    setState(() => _loading = true);
    final cmds = await widget.sensorService.getCommands(
      deviceId: widget.deviceId,
    );
    setState(() {
      _commands = cmds;
      _loading = false;
    });
  }

  Future<void> _update(Map<String, dynamic> updates) async {
    setState(() => _loading = true);
    final success = await widget.sensorService.sendCommand(
      widget.deviceId,
      updates,
    );
    if (success) {
      // merge updates into local state
      _commands.addAll(updates);
    }
    setState(() => _loading = false);
  }

  Widget _switchRow(String label, String keyManual, String keyState) {
    final manual = _commands[keyManual] == true;
    final state = _commands[keyState] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.power, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    state ? 'On' : 'Off',
                    style: TextStyle(
                      color: state ? AppColors.primary : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Manual mode', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: manual,
                    activeColor: AppColors.primary,
                    onChanged: (v) => _update({keyManual: v}),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('State', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: state,
                    activeColor: AppColors.primary,
                    onChanged: (v) => _update({keyState: v}),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _commands.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.tune, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Controls',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _switchRow('Fan', 'fan_manual', 'fan_state'),
            _switchRow('Pump', 'pump_manual', 'pump_state'),
            _switchRow('Bulb', 'bulb_manual', 'bulb_state'),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _loadCommands,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
