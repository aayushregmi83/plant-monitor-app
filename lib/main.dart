import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/camera_feed.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_analysis_screen.dart';

void main() {
  runApp(const PlantMonitorApp());
}

class PlantMonitorApp extends StatelessWidget {
  const PlantMonitorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Monitor',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const DashboardScreen(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/camera': (_) => const CameraFeedScreen(),
        '/health': (_) => const HealthAnalysisScreen(),
        '/detect': (_) => const HomeScreen(),
      },
    );
  }
}
