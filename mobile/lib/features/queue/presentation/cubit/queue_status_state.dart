import 'package:equatable/equatable.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';

abstract class QueueStatusState extends Equatable {
  const QueueStatusState();

  @override
  List<Object?> get props => const <Object?>[];
}

class QueueStatusInitial extends QueueStatusState {
  const QueueStatusInitial();
}

class QueueStatusLoading extends QueueStatusState {
  const QueueStatusLoading();
}

class QueueStatusEmpty extends QueueStatusState {
  const QueueStatusEmpty();
}

class QueueStatusLoaded extends QueueStatusState {
  const QueueStatusLoaded(this.queueStatus);

  final QueueStatus queueStatus;

  @override
  List<Object> get props => <Object>[queueStatus];
}

class QueueStatusError extends QueueStatusState {
  const QueueStatusError(this.failure);

  final Failure failure;

  @override
  List<Object> get props => <Object>[failure];
}
