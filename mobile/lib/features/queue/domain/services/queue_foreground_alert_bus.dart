import 'dart:async';

import 'package:exequeue_mobile/features/queue/domain/entities/queue_alert.dart';

class QueueForegroundAlertBus {
  final StreamController<QueueAlert> _controller =
      StreamController<QueueAlert>.broadcast();

  Stream<QueueAlert> get alerts => _controller.stream;

  void dispatch(QueueAlert alert) {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(alert);
  }
}
