import 'package:flutter/material.dart';

class InfoMetric extends StatelessWidget {
  const InfoMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: accentColor,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
