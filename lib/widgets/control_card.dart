import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/sensor_service.dart';
import '../theme/app_theme.dart';

enum ControlMode { automatic, manual, voice }

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
  ControlMode _mode = ControlMode.automatic;
  bool _autoEnabled = true;
  Map<String, dynamic> _thresholds = {};
  final TextEditingController _tempHighController = TextEditingController();
  final TextEditingController _tempLowController = TextEditingController();
  final TextEditingController _moistureLowController = TextEditingController();
  final TextEditingController _moistureHighController = TextEditingController();
  final TextEditingController _lightLowController = TextEditingController();
  final TextEditingController _lightHighController = TextEditingController();
  bool _savingThresholds = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _speechReady = false;
  bool _listening = false;
  String _lastVoice = '';

  @override
  void initState() {
    super.initState();
    _loadCommands();
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _tempHighController.dispose();
    _tempLowController.dispose();
    _moistureLowController.dispose();
    _moistureHighController.dispose();
    _lightLowController.dispose();
    _lightHighController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _initSpeech() async {
    final ready = await _speech.initialize();
    if (!mounted) return;
    setState(() => _speechReady = ready);
  }

  Future<void> _loadCommands() async {
    setState(() => _loading = true);
    final cmds = await widget.sensorService.getCommands(
      deviceId: widget.deviceId,
    );
    final thresholds = await widget.sensorService.getThresholds();
    setState(() {
      _commands = cmds;
      _autoEnabled = cmds['auto_enabled'] != false;
      _thresholds = thresholds;
      _hydrateThresholdControllers();
      if (_mode != ControlMode.voice) {
        _mode = _deriveMode(cmds);
      }
      _loading = false;
    });
  }

  void _hydrateThresholdControllers() {
    if (_thresholds.isEmpty) return;
    _tempHighController.text = _thresholds['temp_high']?.toString() ?? '';
    _tempLowController.text = _thresholds['temp_low']?.toString() ?? '';
    _moistureLowController.text = _thresholds['moisture_low']?.toString() ?? '';
    _moistureHighController.text =
        _thresholds['moisture_high']?.toString() ?? '';
    _lightLowController.text = _thresholds['intensity_low']?.toString() ?? '';
    _lightHighController.text = _thresholds['intensity_high']?.toString() ?? '';
  }

  double? _parseDouble(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  int? _parseInt(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<void> _saveThresholds() async {
    setState(() => _savingThresholds = true);
    final tempHigh = _parseDouble(_tempHighController);
    final tempLow = _parseDouble(_tempLowController);
    final moistureLow = _parseInt(_moistureLowController);
    final moistureHigh = _parseInt(_moistureHighController);
    final lightLow = _parseInt(_lightLowController);
    final lightHigh = _parseInt(_lightHighController);

    final updates = <String, dynamic>{};
    if (tempHigh != null) updates['temp_high'] = tempHigh;
    if (tempLow != null) updates['temp_low'] = tempLow;
    if (moistureLow != null) updates['moisture_low'] = moistureLow;
    if (moistureHigh != null) updates['moisture_high'] = moistureHigh;
    if (lightLow != null) updates['intensity_low'] = lightLow;
    if (lightHigh != null) updates['intensity_high'] = lightHigh;

    final success =
        updates.isNotEmpty &&
        await widget.sensorService.updateThresholds(updates);
    if (success) {
      _thresholds.addAll(updates);
      _showMessage('Thresholds saved');
    } else {
      _showMessage('Failed to save thresholds');
    }

    if (!mounted) return;
    setState(() => _savingThresholds = false);
  }

  Widget _thresholdField({
    required String label,
    required String suffix,
    required TextEditingController controller,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: false,
        ),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  ControlMode _deriveMode(Map<String, dynamic> cmds) {
    final autoEnabled = cmds['auto_enabled'] != false;
    return autoEnabled ? ControlMode.automatic : ControlMode.manual;
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
      if (updates.containsKey('auto_enabled')) {
        _autoEnabled = updates['auto_enabled'] == true;
        if (!_autoEnabled && _mode == ControlMode.automatic) {
          _mode = ControlMode.manual;
        }
        if (_autoEnabled && _mode == ControlMode.manual) {
          _mode = ControlMode.automatic;
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _setMode(ControlMode mode) async {
    setState(() => _mode = mode);
    if (mode == ControlMode.automatic) {
      await _update({
        'auto_enabled': true,
        'fan_manual': false,
        'pump_manual': false,
        'bulb_manual': false,
      });
    } else {
      await _update({
        'auto_enabled': false,
        'fan_manual': true,
        'pump_manual': true,
        'bulb_manual': true,
      });
    }
  }

  Future<void> _setAutoEnabled(bool enabled) async {
    if (enabled) {
      await _update({
        'auto_enabled': true,
        'fan_manual': false,
        'pump_manual': false,
        'bulb_manual': false,
      });
      setState(() => _mode = ControlMode.automatic);
      return;
    }

    await _update({
      'auto_enabled': false,
      'fan_manual': true,
      'pump_manual': true,
      'bulb_manual': true,
    });
    setState(() => _mode = ControlMode.manual);
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      _showMessage('Speech recognition not available');
      return;
    }

    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _listening = false);
      return;
    }

    final started = await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _lastVoice = result.recognizedWords);
        if (result.finalResult) {
          _handleVoiceCommand(result.recognizedWords);
        }
      },
    );

    if (!mounted) return;
    setState(() => _listening = started);
  }

  Future<void> _handleVoiceCommand(String input) async {
    final result = _parseCommand(input);
    await _applyCommand(result);
  }

  _CommandResult _parseCommand(String input) {
    final text = input.toLowerCase();

    if (text.contains('automatic')) {
      return _CommandResult(
        mode: ControlMode.automatic,
        reply: 'Switched to automatic mode',
      );
    }

    if (text.contains('manual')) {
      return _CommandResult(
        mode: ControlMode.manual,
        reply: 'Switched to manual mode',
      );
    }

    if (text.contains('voice')) {
      return _CommandResult(
        mode: ControlMode.voice,
        reply: 'Voice mode enabled',
      );
    }

    final updates = <String, dynamic>{};
    final replyParts = <String>[];

    if (text.contains('fan')) {
      if (text.contains('on')) {
        updates['fan_state'] = true;
        replyParts.add('turning on the fan');
      }
      if (text.contains('off')) {
        updates['fan_state'] = false;
        replyParts.add('turning off the fan');
      }
      updates['fan_manual'] = true;
    }

    if (text.contains('pump')) {
      if (text.contains('on')) {
        updates['pump_state'] = true;
        replyParts.add('turning on the pump');
      }
      if (text.contains('off')) {
        updates['pump_state'] = false;
        replyParts.add('turning off the pump');
      }
      updates['pump_manual'] = true;
    }

    if (text.contains('bulb') || text.contains('light')) {
      if (text.contains('on')) {
        updates['bulb_state'] = true;
        replyParts.add('turning on the bulb');
      }
      if (text.contains('off')) {
        updates['bulb_state'] = false;
        replyParts.add('turning off the bulb');
      }
      updates['bulb_manual'] = true;
    }

    if (text.contains('all') && text.contains('on')) {
      updates['fan_state'] = true;
      updates['pump_state'] = true;
      updates['bulb_state'] = true;
      updates['fan_manual'] = true;
      updates['pump_manual'] = true;
      updates['bulb_manual'] = true;
      replyParts.add('turning on all devices');
    }

    if (text.contains('all') && text.contains('off')) {
      updates['fan_state'] = false;
      updates['pump_state'] = false;
      updates['bulb_state'] = false;
      updates['fan_manual'] = true;
      updates['pump_manual'] = true;
      updates['bulb_manual'] = true;
      replyParts.add('turning off all devices');
    }

    if (updates.isEmpty) {
      return _CommandResult(reply: 'No matching command');
    }

    return _CommandResult(
      updates: updates,
      reply: replyParts.isEmpty ? 'Command applied' : replyParts.join(', '),
    );
  }

  Future<void> _applyCommand(_CommandResult result) async {
    if (result.mode != null) {
      await _setMode(result.mode!);
    }

    if (result.updates.isNotEmpty) {
      await _update(result.updates);
    }

    _showMessage(result.reply);
    await _speak(result.reply);
  }

  Future<void> _speak(String message) async {
    await _tts.stop();
    await _tts.speak(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addChatMessage(String text, {required bool fromUser}) {
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: fromUser));
    });
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    _addChatMessage(text, fromUser: true);
    final result = _parseCommand(text);
    await _applyCommand(result);
    _addChatMessage(result.reply, fromUser: false);
  }

  Widget _switchRow(String label, String keyState, String keyManual) {
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
                  const Text('State', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: state,
                    activeColor: AppColors.primary,
                    onChanged: !_autoEnabled
                        ? (v) => _update({
                            keyState: v,
                            keyManual: true,
                            'auto_enabled': false,
                          })
                        : null,
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
            SegmentedButton<ControlMode>(
              segments: const [
                ButtonSegment(
                  value: ControlMode.automatic,
                  label: Text('Automatic'),
                ),
                ButtonSegment(value: ControlMode.manual, label: Text('Manual')),
                ButtonSegment(value: ControlMode.voice, label: Text('Voice')),
              ],
              selected: {_mode},
              onSelectionChanged: (value) => _setMode(value.first),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Automatic control',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: _autoEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (v) => _setAutoEnabled(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppColors.light,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Automatic thresholds',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _thresholdField(
                          label: 'Temp High',
                          suffix: 'C',
                          controller: _tempHighController,
                        ),
                        const SizedBox(width: 8),
                        _thresholdField(
                          label: 'Temp Low',
                          suffix: 'C',
                          controller: _tempLowController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _thresholdField(
                          label: 'Moisture Low',
                          suffix: '%',
                          controller: _moistureLowController,
                        ),
                        const SizedBox(width: 8),
                        _thresholdField(
                          label: 'Moisture High',
                          suffix: '%',
                          controller: _moistureHighController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _thresholdField(
                          label: 'Light Low',
                          suffix: '%',
                          controller: _lightLowController,
                        ),
                        const SizedBox(width: 8),
                        _thresholdField(
                          label: 'Light High',
                          suffix: '%',
                          controller: _lightHighController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _savingThresholds ? null : _saveThresholds,
                        icon: _savingThresholds
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save Thresholds'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_mode == ControlMode.voice) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleListening,
                    icon: Icon(_listening ? Icons.mic_off : Icons.mic),
                    label: Text(
                      _listening ? 'Stop Listening' : 'Start Listening',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _lastVoice.isEmpty ? 'Say: "Turn on fan"' : _lastVoice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _speechReady
                    ? 'Voice tips: fan on/off, pump on/off, bulb on/off, all on/off.'
                    : 'Speech recognition unavailable on this device.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              color: AppColors.light,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Command Chat',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 140,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: _messages.isEmpty
                          ? const Center(
                              child: Text('Type commands if voice fails'),
                            )
                          : ListView.builder(
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final align = msg.fromUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start;
                                final color = msg.fromUser
                                    ? AppColors.primary.withOpacity(0.15)
                                    : Colors.grey.shade200;
                                return Column(
                                  crossAxisAlignment: align,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(msg.text),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: 'Type a command... e.g., fan on',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _sendChat(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _sendChat,
                          icon: const Icon(Icons.send),
                          label: const Text('Send'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _switchRow('Fan', 'fan_state', 'fan_manual'),
            _switchRow('Pump', 'pump_state', 'pump_manual'),
            _switchRow('Bulb', 'bulb_state', 'bulb_manual'),
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

class _CommandResult {
  final Map<String, dynamic> updates;
  final ControlMode? mode;
  final String reply;

  const _CommandResult({
    this.updates = const {},
    this.mode,
    this.reply = 'Command applied',
  });
}

class _ChatMessage {
  final String text;
  final bool fromUser;

  const _ChatMessage({required this.text, required this.fromUser});
}
