import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class ApiService {
  // Default for Android emulator -> change to host IP for physical devices
  final String? baseUrl;
  final SettingsService _settings = SettingsService();

  ApiService({this.baseUrl});

  Future<Map<String, dynamic>> detectImage(File imageFile) async {
    final effectiveBase = baseUrl ?? await _settings.getBackendUrl();
    final uri = Uri.parse('$effectiveBase/api/detect');

    var request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    try {
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return json.decode(resp.body) as Map<String, dynamic>;
      } else {
        return {
          'error': 'Server returned ${resp.statusCode}',
          'body': resp.body,
        };
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> detectDisease(File imageFile) async {
    final effectiveBase = baseUrl ?? await _settings.getBackendUrl();
    final uri = Uri.parse('$effectiveBase/api/detect-disease');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    try {
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      return {'error': 'Server returned ${resp.statusCode}', 'body': resp.body};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
