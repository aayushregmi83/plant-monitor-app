import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'package:http/http.dart' as http;

class CameraFeedScreen extends StatefulWidget {
  const CameraFeedScreen({Key? key}) : super(key: key);

  @override
  State<CameraFeedScreen> createState() => _CameraFeedScreenState();
}

class _CameraFeedScreenState extends State<CameraFeedScreen> {
  final SettingsService _settings = SettingsService();
  String? _imageB64;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    final base = await _settings.getBackendUrl();
    try {
      final uri = Uri.parse('$base/api/camera-feed');
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        setState(() {
          _imageB64 = body['image'];
        });
      } else {
        setState(() {
          _imageB64 = null;
        });
      }
    } catch (_) {
      setState(() {
        _imageB64 = null;
      });
    }
  }

  void _startPolling() {
    if (_running) return;
    _running = true;
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetch());
  }

  void _stopPolling() {
    _timer?.cancel();
    _running = false;
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_imageB64 == null) {
      content = const Center(child: Text('No frame available'));
    } else {
      // image is data:image/jpeg;base64,...
      final comma = _imageB64!.indexOf(',');
      final data = comma >= 0 ? _imageB64!.substring(comma + 1) : _imageB64!;
      content = Image.memory(base64Decode(data));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Camera Feed')),
      body: Column(
        children: [
          Expanded(child: Center(child: content)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _startPolling,
                child: const Text('Start'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _stopPolling,
                child: const Text('Stop'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
