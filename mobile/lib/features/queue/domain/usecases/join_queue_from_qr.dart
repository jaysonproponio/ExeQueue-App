import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/core/usecases/usecase.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/join_queue_result.dart';
import 'package:exequeue_mobile/features/queue/domain/repositories/queue_repository.dart';

class JoinQueueFromQr
    implements UseCase<JoinQueueResult, JoinQueueFromQrParams> {
  JoinQueueFromQr(this._repository);

  final QueueRepository _repository;

  @override
  Future<Either<Failure, JoinQueueResult>> call(JoinQueueFromQrParams params) {
    return _repository.joinQueueFromQr(
      qrPayload: params.qrPayload,
      studentId: params.studentId,
      transactionType: params.transactionType,
      manual: params.manual,
    );
  }
}

class JoinQueueFromQrParams extends Equatable {
  const JoinQueueFromQrParams({
    required this.qrPayload,
    required this.transactionType,
    this.studentId = '',
    this.manual = false,
  });

  final String qrPayload;
  final String studentId;
  final String transactionType;
  final bool manual;

  @override
  List<Object> get props => <Object>[
        qrPayload,
        studentId,
        transactionType,
        manual,
      ];
}
