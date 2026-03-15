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
      studentName: params.studentName,
      transactionType: params.transactionType,
      manual: params.manual,
    );
  }
}

class JoinQueueFromQrParams extends Equatable {
  const JoinQueueFromQrParams({
    required this.qrPayload,
    this.studentName = 'Juan Dela Cruz',
    this.transactionType = 'Tuition Payment',
    this.manual = false,
  });

  final String qrPayload;
  final String studentName;
  final String transactionType;
  final bool manual;

  @override
  List<Object> get props => <Object>[
        qrPayload,
        studentName,
        transactionType,
        manual,
      ];
}
