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
}

QueueStage queueStageFromValue(String? raw) {
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
