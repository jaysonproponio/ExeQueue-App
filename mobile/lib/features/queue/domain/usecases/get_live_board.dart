import 'package:dartz/dartz.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/core/usecases/usecase.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/live_board.dart';
import 'package:exequeue_mobile/features/queue/domain/repositories/queue_repository.dart';

class GetLiveBoard implements UseCase<LiveBoard, NoParams> {
  GetLiveBoard(this._repository);

  final QueueRepository _repository;

  @override
  Future<Either<Failure, LiveBoard>> call(NoParams params) {
    return _repository.getLiveBoard();
  }
}
