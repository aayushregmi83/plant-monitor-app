import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_theme.dart';
import '../widgets/disease_card.dart';

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
  final ApiService _api = ApiService();

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
    try {
      final res = await _api.detectDisease(_image!);
      setState(() => _result = res);
    } catch (e) {
      setState(() {
        _result = {'error': e.toString()};
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final detection = _result != null
        ? _result!['detection'] as Map<String, dynamic>?
        : null;
    final score = detection != null
        ? ((detection['confidence'] ?? 0.0) as num) * 100
        : 0.0;
    final statusLabel = score >= 80
        ? 'Excellent'
        : score >= 60
        ? 'Good'
        : score >= 40
        ? 'Fair'
        : 'Needs Attention';
    final statusColor = score >= 80
        ? AppColors.primary
        : score >= 60
        ? const Color(0xFF8BC34A)
        : score >= 40
        ? AppColors.warning
        : AppColors.danger;

    return AppScaffold(
      title: 'Health Analysis',
      subtitle: 'Diagnose plant health with AI assistance',
      currentRoute: '/health',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [statusColor, Colors.grey.shade300],
                        stops: [score / 100, score / 100],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              score.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'Health Score',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result == null
                        ? 'Upload a leaf image for disease analysis.'
                        : 'AI analysis complete. Review recommendations below.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.upload_file, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Disease Detection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black12,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: _image == null
                          ? const Text('Drop a leaf image here')
                          : Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _image != null && !_loading ? _analyze : null,
                    icon: const Icon(Icons.search),
                    label: const Text('Analyze Disease'),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_result != null) DiseaseCard(result: _result!),
        ],
      ),
    );
  }
}
