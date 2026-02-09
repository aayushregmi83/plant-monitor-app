import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

class SensorService {
  final SettingsService _settings = SettingsService();

  Future<Map<String, dynamic>> getSensorData({
    String deviceId = 'sensor_node_1',
  }) async {
    final base = await _settings.getBackendUrl();
    final uri = Uri.parse('$base/api/sensor-data?device_id=$deviceId');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print('Sensor fetch error: $e');
    }
    return {};
  }

  Future<Map<String, dynamic>> getStatus() async {
    final base = await _settings.getBackendUrl();
    final uri = Uri.parse('$base/api/status');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print('Status fetch error: $e');
    }
    return {};
  }

  Future<Map<String, dynamic>> getCommands({
    String deviceId = 'sensor_node_1',
  }) async {
    final base = await _settings.getBackendUrl();
    final uri = Uri.parse('$base/api/commands/$deviceId');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print('Commands fetch error: $e');
    }
    return {};
  }

  Future<bool> sendCommand(
    String deviceId,
    Map<String, dynamic> command,
  ) async {
    final base = await _settings.getBackendUrl();
    final uri = Uri.parse('$base/api/commands/$deviceId');
    try {
      final resp = await http
          .post(
            uri,
            body: json.encode(command),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Command send error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>> getThresholds() async {
    final base = await _settings.getBackendUrl();
    final uri = Uri.parse('$base/api/thresholds');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print('Thresholds fetch error: $e');
    }
    return {};
  }

  Future<bool> updateThresholds(Map<String, dynamic> updates) async {
    final base = await _settings.getBackendUrl();
    final uri = Uri.parse('$base/api/thresholds');
    try {
      final resp = await http
          .post(
            uri,
            body: json.encode(updates),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Thresholds update error: $e');
    }
    return false;
  }
}
