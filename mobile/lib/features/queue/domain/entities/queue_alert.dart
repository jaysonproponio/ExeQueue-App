import 'package:equatable/equatable.dart';

class QueueAlert extends Equatable {
  const QueueAlert({
    required this.title,
    required this.body,
    required this.queueNumber,
    this.distance,
  });

  final String title;
  final String body;
  final String queueNumber;
  final int? distance;

  bool get isThresholdAlert =>
      distance == null || (distance! >= 0 && distance! <= 5);

  String get distanceLabel {
    final currentDistance = distance;
    if (currentDistance == null) {
      return 'Please prepare to proceed to the cashier window.';
    }

    if (currentDistance == 0) {
      return 'You are next. Please proceed to the cashier window now.';
    }

    if (currentDistance == 1) {
      return 'There is only 1 queue ahead of you.';
    }

    return 'There are only $currentDistance queues ahead of you.';
  }

  @override
  List<Object?> get props => <Object?>[
        title,
        body,
        queueNumber,
        distance,
      ];
}
