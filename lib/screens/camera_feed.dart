import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/detection_card.dart';
import '../widgets/disease_card.dart';
import '../widgets/app_scaffold.dart';
import '../theme/app_theme.dart';

class CameraFeedScreen extends StatefulWidget {
  const CameraFeedScreen({Key? key}) : super(key: key);

  @override
  State<CameraFeedScreen> createState() => _CameraFeedScreenState();
}

class _CameraFeedScreenState extends State<CameraFeedScreen> {
  CameraController? _controller;
  bool _initializing = false;
  bool _running = false;
  bool _detecting = false;
  String? _error;
  Map<String, dynamic>? _detectResult;
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_running || _initializing) return;
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
          _initializing = false;
        });
        return;
      }

      final selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _running = true;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initializing = false;
      });
    }
  }

  Future<void> _stopCamera() async {
    await _controller?.dispose();
    if (!mounted) return;
    setState(() {
      _controller = null;
      _running = false;
    });
  }

  Future<void> _captureAndDetect({required bool disease}) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      setState(() => _error = 'Camera not ready. Tap Start first.');
      return;
    }
    setState(() {
      _detecting = true;
      _detectResult = null;
    });

    try {
      final file = await _controller!.takePicture();
      final image = File(file.path);
      final result = disease
          ? await _api.detectDisease(image)
          : await _api.detectImage(image);
      if (!mounted) return;
      setState(() => _detectResult = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _detectResult = {'error': e.toString()});
    }

    if (!mounted) return;
    setState(() => _detecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _controller != null && _controller!.value.isInitialized
        ? CameraPreview(_controller!)
        : const SizedBox.shrink();

    return AppScaffold(
      title: 'Live Feed & Detection',
      subtitle: 'Use your phone camera for real-time capture',
      currentRoute: '/camera',
      trailing: _FeedBadge(running: _running),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.videocam, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Live Camera',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _initializing ? null : _startCamera,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _running ? _stopCamera : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _running ? preview : _cameraPlaceholder(),
                          ),
                          _roiOverlay(),
                          if (_initializing)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _detecting
                            ? null
                            : () => _captureAndDetect(disease: false),
                        icon: const Icon(Icons.search),
                        label: const Text('Capture & Detect'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _detecting
                            ? null
                            : () => _captureAndDetect(disease: true),
                        icon: const Icon(Icons.healing),
                        label: const Text('Capture & Disease'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_detecting) const LinearProgressIndicator(minHeight: 4),
          if (_detectResult != null) ...[
            const SizedBox(height: 12),
            if (_detectResult!.containsKey('disease_name') ||
                _detectResult!.containsKey('disease_class'))
              DiseaseCard(result: _detectResult!)
            else
              DetectionCard(result: _detectResult!),
          ],
        ],
      ),
    );
  }

  Widget _cameraPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.videocam_off, color: Colors.white54, size: 64),
          SizedBox(height: 12),
          Text('Camera is stopped', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _roiOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.lightBlueAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.65),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Text(
                  'Place leaf or fruit inside the box',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedBadge extends StatelessWidget {
  final bool running;
  const _FeedBadge({required this.running});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: running ? AppColors.primary : AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            running ? 'Live' : 'Stopped',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
