import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DiseaseCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const DiseaseCard({Key? key, required this.result}) : super(key: key);

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

    final diseaseName =
        result['disease_name'] ?? result['disease_class'] ?? 'Unknown';
    final confidence =
        result['confidence_percent'] ?? ((result['confidence'] ?? 0.0) * 100);
    final severity = result['severity'] ?? 'Unknown';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.healing, color: AppColors.warning),
                const SizedBox(width: 8),
                const Text(
                  'Disease Diagnosis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '${confidence.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              diseaseName.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text('Severity: $severity'),
            const SizedBox(height: 12),
            if (result['symptoms'] != null) ...[
              const Text(
                'Symptoms',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(result['symptoms'].toString()),
              const SizedBox(height: 8),
            ],
            if (result['causes'] != null) ...[
              const Text(
                'Causes',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(result['causes'].toString()),
              const SizedBox(height: 8),
            ],
            if (result['treatment'] != null) ...[
              const Text(
                'Treatment',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(result['treatment'].toString()),
              const SizedBox(height: 8),
            ],
            if (result['prevention'] != null) ...[
              const Text(
                'Prevention',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(result['prevention'].toString()),
            ],
          ],
        ),
      ),
    );
  }
}
