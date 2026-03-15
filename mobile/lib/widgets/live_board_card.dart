import 'package:flutter/material.dart';

import '../models/queue_status.dart';

class LiveBoardCard extends StatelessWidget {
  const LiveBoardCard({
    super.key,
    required this.boardData,
    required this.loading,
  });

  final LiveBoardData boardData;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.circle,
                  size: 12,
                  color: Color(0xFF34A853),
                ),
                const SizedBox(width: 10),
                Text(
                  loading ? 'Syncing live queue...' : 'Realtime queue board',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'NOW SERVING',
              style: textTheme.bodyMedium?.copyWith(
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                boardData.nowServing,
                key: ValueKey<String>(boardData.nowServing),
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 52,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'NEXT QUEUE',
              style: textTheme.bodyMedium?.copyWith(
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: boardData.nextQueues
                  .map(
                    (queueNumber) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x0F1A73E8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        queueNumber,
                        style: textTheme.titleLarge,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
