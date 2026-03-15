import 'package:dartz/dartz.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/join_queue_result.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/live_board.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';

abstract class QueueRepository {
  Future<Either<Failure, QueueStatus>> getQueueStatus({
    String? queueNumber,
    String? studentName,
  });

  Future<Either<Failure, LiveBoard>> getLiveBoard();

  Future<Either<Failure, JoinQueueResult>> joinQueueFromQr({
    required String qrPayload,
    required String studentId,
    required String transactionType,
    required bool manual,
  });

  Future<Either<Failure, Unit>> initializeNotifications();

  Future<Either<Failure, Unit>> subscribeToQueueTopic(String queueNumber);
}
