import 'package:flutter/material.dart';

import 'package:exequeue_mobile/features/queue/domain/entities/queue_stage.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final QueueStage status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: status.color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
