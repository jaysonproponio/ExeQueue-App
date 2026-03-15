import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/core/usecases/usecase.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';
import 'package:exequeue_mobile/features/queue/domain/repositories/queue_repository.dart';

class GetQueueStatus implements UseCase<QueueStatus, GetQueueStatusParams> {
  GetQueueStatus(this._repository);

  final QueueRepository _repository;

  @override
  Future<Either<Failure, QueueStatus>> call(GetQueueStatusParams params) {
    return _repository.getQueueStatus(studentName: params.studentName);
  }
}

class GetQueueStatusParams extends Equatable {
  const GetQueueStatusParams({
    this.studentName = 'Juan Dela Cruz',
  });

  final String studentName;

  @override
  List<Object> get props => <Object>[studentName];
}
