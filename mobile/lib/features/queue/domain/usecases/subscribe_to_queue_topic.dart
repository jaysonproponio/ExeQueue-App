import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/core/usecases/usecase.dart';
import 'package:exequeue_mobile/features/queue/domain/repositories/queue_repository.dart';

class SubscribeToQueueTopic
    implements UseCase<Unit, SubscribeToQueueTopicParams> {
  SubscribeToQueueTopic(this._repository);

  final QueueRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SubscribeToQueueTopicParams params) {
    return _repository.subscribeToQueueTopic(params.queueNumber);
  }
}

class SubscribeToQueueTopicParams extends Equatable {
  const SubscribeToQueueTopicParams({required this.queueNumber});

  final String queueNumber;

  @override
  List<Object> get props => <Object>[queueNumber];
}
