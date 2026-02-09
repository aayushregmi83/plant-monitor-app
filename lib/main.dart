import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/camera_feed.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_analysis_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PlantMonitorApp());
}

class PlantMonitorApp extends StatelessWidget {
  const PlantMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Monitor',
      theme: AppTheme.build(),
      initialRoute: '/',
      routes: {
        '/': (_) => const DashboardScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/camera': (_) => const CameraFeedScreen(),
        '/health': (_) => const HealthAnalysisScreen(),
        '/detect': (_) => const HomeScreen(),
      },
    );
  }
}
