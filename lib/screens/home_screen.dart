import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/detection_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _detect() async {
    if (_image == null) return;
    setState(() => _loading = true);
    final res = await _api.detectImage(_image!);
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Monitor')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Plant Monitor')),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera Feed'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: _image == null
                    ? const Text(
                        'No image selected',
                        style: TextStyle(fontSize: 18),
                      )
                    : Image.file(_image!),
              ),
            ),

            const SizedBox(height: 12),

            if (_loading) const LinearProgressIndicator(),

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
              onPressed: _image != null && !_loading ? _detect : null,
              child: const Text('Detect'),
            ),

            const SizedBox(height: 12),

            if (_result != null) ...[DetectionCard(result: _result!)],
          ],
        ),
      ),
    );
  }
}
