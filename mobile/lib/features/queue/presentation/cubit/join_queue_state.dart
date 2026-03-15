import 'package:equatable/equatable.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/join_queue_result.dart';

abstract class JoinQueueState extends Equatable {
  const JoinQueueState();

  @override
  List<Object?> get props => const <Object?>[];
}

class JoinQueueInitial extends JoinQueueState {
  const JoinQueueInitial();
}

class JoinQueueLoading extends JoinQueueState {
  const JoinQueueLoading();
}

class JoinQueueSuccess extends JoinQueueState {
  const JoinQueueSuccess(this.result);

  final JoinQueueResult result;

  @override
  List<Object> get props => <Object>[result];
}

class JoinQueueError extends JoinQueueState {
  const JoinQueueError(this.failure);

  final Failure failure;

  @override
  List<Object> get props => <Object>[failure];
}
