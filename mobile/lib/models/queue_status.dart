import 'package:flutter/material.dart';

enum QueueStage {
  waiting,
  called,
  skipped,
  done,
}

extension QueueStageX on QueueStage {
  String get label {
    switch (this) {
      case QueueStage.waiting:
        return 'Waiting';
      case QueueStage.called:
        return 'Called';
      case QueueStage.skipped:
        return 'Skipped';
      case QueueStage.done:
        return 'Done';
    }
  }

  Color get color {
    switch (this) {
      case QueueStage.waiting:
        return const Color(0xFF1A73E8);
      case QueueStage.called:
        return const Color(0xFF34A853);
      case QueueStage.skipped:
        return const Color(0xFFFB8C00);
      case QueueStage.done:
        return const Color(0xFF5F6B7A);
    }
  }

  static QueueStage fromValue(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'CALLED':
        return QueueStage.called;
      case 'SKIPPED':
        return QueueStage.skipped;
      case 'DONE':
        return QueueStage.done;
      case 'WAITING':
      default:
        return QueueStage.waiting;
    }
  }
}

class QueueStatusData {
  const QueueStatusData({
    required this.queueNumber,
    required this.nowServing,
    required this.peopleAhead,
    required this.estimatedWait,
    required this.status,
    required this.transactionType,
  });

  final String queueNumber;
  final String nowServing;
  final int peopleAhead;
  final Duration estimatedWait;
  final QueueStage status;
  final String transactionType;

  double get progressRatio {
    final current = _extractQueueNumber(nowServing).toDouble();
    final target = _extractQueueNumber(queueNumber).toDouble();

    if (target <= 0) {
      return 0;
    }

    if (current >= target) {
      return 1;
    }

    return (current / target).clamp(0.0, 1.0);
  }

  String get formattedWait => '${estimatedWait.inMinutes} minutes';

  factory QueueStatusData.fromJson(Map<String, dynamic> json) {
    return QueueStatusData(
      queueNumber: json['queue_number'] as String? ?? 'A021',
      nowServing: json['now_serving'] as String? ?? 'A016',
      peopleAhead: (json['people_ahead'] as num?)?.toInt() ?? 5,
      estimatedWait: Duration(
        minutes: (json['estimated_wait_minutes'] as num?)?.toInt() ?? 15,
      ),
      status: QueueStageX.fromValue(json['status'] as String?),
      transactionType:
          json['transaction_type'] as String? ?? 'Tuition Payment',
    );
  }

  factory QueueStatusData.demo() {
    return const QueueStatusData(
      queueNumber: 'A021',
      nowServing: 'A016',
      peopleAhead: 5,
      estimatedWait: Duration(minutes: 15),
      status: QueueStage.waiting,
      transactionType: 'Tuition Payment',
    );
  }
}

class LiveBoardData {
  const LiveBoardData({
    required this.nowServing,
    required this.nextQueues,
    required this.updatedAt,
  });

  final String nowServing;
  final List<String> nextQueues;
  final DateTime updatedAt;

  factory LiveBoardData.fromJson(Map<String, dynamic> json) {
    final nextQueues = (json['next_queues'] as List<dynamic>? ?? <dynamic>[])
        .map((entry) => entry.toString())
        .toList();

    return LiveBoardData(
      nowServing: json['now_serving'] as String? ?? 'A021',
      nextQueues: nextQueues.isEmpty
          ? const <String>['A022', 'A023', 'A024']
          : nextQueues,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory LiveBoardData.demo() {
    return LiveBoardData(
      nowServing: 'A021',
      nextQueues: const <String>['A022', 'A023', 'A024'],
      updatedAt: DateTime.now(),
    );
  }
}

int _extractQueueNumber(String value) {
  final match = RegExp(r'(\d+)').firstMatch(value);
  return int.tryParse(match?.group(1) ?? '') ?? 0;
}
