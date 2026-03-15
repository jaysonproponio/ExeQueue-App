import 'package:equatable/equatable.dart';

import 'package:exequeue_mobile/features/queue/domain/entities/queue_stage.dart';

class QueueStatus extends Equatable {
  const QueueStatus({
    required this.queueNumber,
    required this.nowServing,
    required this.peopleAhead,
    required this.estimatedWait,
    required this.status,
    required this.transactionType,
    this.isDemo = false,
  });

  final String queueNumber;
  final String nowServing;
  final int peopleAhead;
  final Duration estimatedWait;
  final QueueStage status;
  final String transactionType;
  final bool isDemo;

  double get progressRatio {
    final current = _extractQueueNumber(nowServing).toDouble();
    final target = _extractQueueNumber(queueNumber).toDouble();

    if (target <= 0) {
      return 0;
    }

    if (current >= target) {
      return 1;
    }

    return (current / target).clamp(0, 1).toDouble();
  }

  String get formattedWait => '${estimatedWait.inMinutes} minutes';

  factory QueueStatus.demo() {
    return const QueueStatus(
      queueNumber: 'A021',
      nowServing: 'A016',
      peopleAhead: 5,
      estimatedWait: Duration(minutes: 15),
      status: QueueStage.waiting,
      transactionType: 'Tuition Payment',
      isDemo: true,
    );
  }

  @override
  List<Object> get props => <Object>[
        queueNumber,
        nowServing,
        peopleAhead,
        estimatedWait,
        status,
        transactionType,
        isDemo,
      ];
}

int _extractQueueNumber(String value) {
  final match = RegExp(r'(\d+)').firstMatch(value);
  return int.tryParse(match?.group(1) ?? '') ?? 0;
}
