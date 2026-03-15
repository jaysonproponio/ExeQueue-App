import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/core/di/service_locator.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_stage.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/queue_status_cubit.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/queue_status_state.dart';
import 'package:exequeue_mobile/features/queue/presentation/widgets/info_metric.dart';
import 'package:exequeue_mobile/features/queue/presentation/widgets/status_pill.dart';

class MyQueuePage extends StatelessWidget {
  const MyQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QueueStatusCubit>(
      create: (_) => sl<QueueStatusCubit>()..loadQueueStatus(),
      child: const _MyQueueView(),
    );
  }
}

class _MyQueueView extends StatelessWidget {
  const _MyQueueView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueStatusCubit, QueueStatusState>(
      builder: (context, state) {
        if (state is QueueStatusInitial || state is QueueStatusLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is QueueStatusError) {
          return _QueueStatusErrorView(
            message: state.failure.message,
            onRetry: () => context.read<QueueStatusCubit>().loadQueueStatus(),
          );
        }

        final queueStatus = (state as QueueStatusLoaded).queueStatus;

        return RefreshIndicator(
          onRefresh: () => context.read<QueueStatusCubit>().loadQueueStatus(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: <Widget>[
              if (queueStatus.isDemo) const _DemoModeBanner(),
              if (queueStatus.isDemo) const SizedBox(height: 18),
              _QueueSummaryCard(queueStatus: queueStatus),
              const SizedBox(height: 18),
              _QueueMetricsGrid(queueStatus: queueStatus),
              const SizedBox(height: 18),
              _QueueProgressCard(queueStatus: queueStatus),
            ],
          ),
        );
      },
    );
  }
}

class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.info_outline, color: Color(0xFFFB8C00)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Demo queue data is being shown because the backend or database is not configured yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueSummaryCard extends StatelessWidget {
  const _QueueSummaryCard({required this.queueStatus});

  final QueueStatus queueStatus;

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
    );
  }
}

class _QueueMetricsGrid extends StatelessWidget {
  const _QueueMetricsGrid({required this.queueStatus});

  final QueueStatus queueStatus;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
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
    );
  }
}

class _QueueProgressCard extends StatelessWidget {
  const _QueueProgressCard({required this.queueStatus});

  final QueueStatus queueStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
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
    );
  }
}

class _QueueStatusErrorView extends StatelessWidget {
  const _QueueStatusErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
