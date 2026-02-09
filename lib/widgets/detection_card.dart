import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DetectionCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const DetectionCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result.containsKey('error')) {
      return Card(
        color: const Color(0xFFFFEBEE),
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
    final confidence = detection != null
        ? (detection['confidence'] ?? 0.0) as num
        : 0.0;
    final confidencePct = (confidence * 100).toStringAsFixed(1);
    final badgeColor = confidence >= 0.8
        ? AppColors.primary
        : confidence >= 0.5
        ? AppColors.warning
        : AppColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Detection Result',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withOpacity(0.6)),
                  ),
                  child: Text(
                    '$confidencePct%',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (detection != null) ...[
              Text(
                detection['label'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
            if (top.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Top predictions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var p in top.take(3))
                    Chip(
                      label: Text(
                        '${p['label']} ${(p['confidence'] * 100).toStringAsFixed(1)}%',
                      ),
                      backgroundColor: AppColors.light,
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                ],
              ),
            ],
            if (funFacts != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fun fact',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(funFacts['fact'] ?? ''),
                    if (funFacts['benefit'] != null) ...[
                      const SizedBox(height: 6),
                      Text('Benefit: ${funFacts['benefit']}'),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
