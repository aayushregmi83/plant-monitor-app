import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _backendKey = 'backend_url';

  Future<String> getBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendKey) ?? 'http://10.0.2.2:5000';
  }

  Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendKey, url);
  }
}
