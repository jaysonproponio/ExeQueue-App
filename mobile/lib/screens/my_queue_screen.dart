import 'package:flutter/material.dart';

import '../models/queue_status.dart';
import '../services/api_service.dart';
import '../widgets/info_metric.dart';
import '../widgets/status_pill.dart';

class MyQueueScreen extends StatefulWidget {
  const MyQueueScreen({super.key});

  @override
  State<MyQueueScreen> createState() => _MyQueueScreenState();
}

class _MyQueueScreenState extends State<MyQueueScreen> {
  final ApiService _apiService = ApiService();

  QueueStatusData? _queueStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQueueStatus();
  }

  Future<void> _loadQueueStatus() async {
    setState(() => _loading = true);
    final queueStatus = await _apiService.fetchQueueStatus();

    if (!mounted) {
      return;
    }

    setState(() {
      _queueStatus = queueStatus;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _queueStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final queueStatus = _queueStatus ?? QueueStatusData.demo();
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _loadQueueStatus,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Queue Number',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              queueStatus.queueNumber,
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(status: queueStatus.status),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    queueStatus.transactionType,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time cashier updates appear here so students can plan when to approach the window.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              InfoMetric(
                label: 'Now Serving',
                value: queueStatus.nowServing,
                icon: Icons.campaign_outlined,
                accentColor: const Color(0xFF1A73E8),
              ),
              InfoMetric(
                label: 'Position',
                value: '${queueStatus.peopleAhead} ahead',
                icon: Icons.people_alt_outlined,
                accentColor: const Color(0xFF34A853),
              ),
              InfoMetric(
                label: 'Estimated Wait',
                value: queueStatus.formattedWait,
                icon: Icons.schedule_outlined,
                accentColor: const Color(0xFFFB8C00),
              ),
              InfoMetric(
                label: 'Status',
                value: queueStatus.status.label,
                icon: Icons.flag_outlined,
                accentColor: queueStatus.status.color,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Queue Progress',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${queueStatus.nowServing} is currently being served. You are ${queueStatus.peopleAhead} numbers away.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: queueStatus.progressRatio,
                      ),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 14,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(queueStatus.progressRatio * 100).round()}% through the queue',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
