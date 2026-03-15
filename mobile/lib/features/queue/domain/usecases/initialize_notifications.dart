import 'package:dartz/dartz.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/core/usecases/usecase.dart';
import 'package:exequeue_mobile/features/queue/domain/repositories/queue_repository.dart';

class InitializeNotifications implements UseCase<Unit, NoParams> {
  InitializeNotifications(this._repository);

  final QueueRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _repository.initializeNotifications();
  }
}
