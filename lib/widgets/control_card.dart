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
    setState(() {
      _commands = cmds;
      if (_mode != ControlMode.voice) {
        _mode = _deriveMode(cmds);
      }
      _loading = false;
    });
  }

  ControlMode _deriveMode(Map<String, dynamic> cmds) {
    final manualEnabled =
        (cmds['fan_manual'] == true) ||
        (cmds['pump_manual'] == true) ||
        (cmds['bulb_manual'] == true);
    return manualEnabled ? ControlMode.manual : ControlMode.automatic;
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

  Future<void> _setMode(ControlMode mode) async {
    setState(() => _mode = mode);
    if (mode == ControlMode.automatic) {
      await _update({
        'fan_manual': false,
        'pump_manual': false,
        'bulb_manual': false,
      });
    } else {
      await _update({
        'fan_manual': true,
        'pump_manual': true,
        'bulb_manual': true,
      });
    }
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

  Widget _switchRow(String label, String keyState) {
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
                    onChanged: _mode == ControlMode.manual
                        ? (v) => _update({keyState: v})
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
            _switchRow('Fan', 'fan_state'),
            _switchRow('Pump', 'pump_state'),
            _switchRow('Bulb', 'bulb_state'),
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
