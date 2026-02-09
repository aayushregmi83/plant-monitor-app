import 'package:flutter/material.dart';

class DetectionCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const DetectionCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result.containsKey('error')) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'Error: ${result['error']}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final detection = result['detection'] as Map<String, dynamic>?;
    final top = (result['top_predictions'] ?? []) as List<dynamic>;
    final funFacts = result['fun_facts'] as Map<String, dynamic>?;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detected:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (detection != null) ...[
              Text(
                '${detection['label']}  •  ${((detection['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 18),
              ),
            ],

            const SizedBox(height: 8),
            if (top.isNotEmpty) ...[
              const Text(
                'Top predictions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (var p in top.take(3))
                Text(
                  '${p['label']} • ${(p['confidence'] * 100).toStringAsFixed(1)}%',
                ),
            ],

            const SizedBox(height: 8),
            if (funFacts != null) ...[
              const Text(
                'Fun fact:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(funFacts['fact'] ?? ''),
              const SizedBox(height: 6),
              Text('Benefit: ${funFacts['benefit'] ?? ''}'),
            ],
          ],
        ),
      ),
    );
  }
}
