import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/settings_service.dart';

class HealthAnalysisScreen extends StatefulWidget {
  const HealthAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<HealthAnalysisScreen> createState() => _HealthAnalysisScreenState();
}

class _HealthAnalysisScreenState extends State<HealthAnalysisScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;
  final SettingsService _settings = SettingsService();

  Future<void> _pick(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
    );
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _result = null;
    });
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _loading = true);

    final base = await _settings.getBackendUrl();
    final uri = Uri.parse('$base/api/detect-disease');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', _image!.path),
      );
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        setState(() {
          _result = json.decode(resp.body) as Map<String, dynamic>;
        });
      } else {
        setState(() {
          _result = {'error': 'Server returned ${resp.statusCode}'};
        });
      }
    } catch (e) {
      setState(() {
        _result = {'error': e.toString()};
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _image == null
                    ? const Text('No image selected')
                    : Image.file(_image!),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                    onPressed: () => _pick(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    onPressed: () => _pick(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _image != null && !_loading ? _analyze : null,
              child: const Text('Analyze'),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_result != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(_result!.toString()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
