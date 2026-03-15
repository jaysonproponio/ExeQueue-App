import 'package:dartz/dartz.dart';

import 'package:exequeue_mobile/core/error/exceptions.dart';
import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/core/network/api_config.dart';
import 'package:exequeue_mobile/features/queue/data/datasources/queue_local_data_source.dart';
import 'package:exequeue_mobile/features/queue/data/datasources/queue_notification_data_source.dart';
import 'package:exequeue_mobile/features/queue/data/datasources/queue_remote_data_source.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/join_queue_result.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/live_board.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';
import 'package:exequeue_mobile/features/queue/domain/repositories/queue_repository.dart';

class QueueRepositoryImpl implements QueueRepository {
  QueueRepositoryImpl({
    required QueueRemoteDataSource remoteDataSource,
    required QueueLocalDataSource localDataSource,
    required QueueNotificationDataSource notificationDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _notificationDataSource = notificationDataSource;

  final QueueRemoteDataSource _remoteDataSource;
  final QueueLocalDataSource _localDataSource;
  final QueueNotificationDataSource _notificationDataSource;

  @override
  Future<Either<Failure, QueueStatus>> getQueueStatus({
    String? queueNumber,
    String? studentName,
  }) async {
    try {
      final model = await _remoteDataSource.getQueueStatus(
        queueNumber: queueNumber,
        studentName: studentName,
      );
      return Right<Failure, QueueStatus>(model.toEntity());
    } on ServerException catch (error) {
      if (ApiConfig.hasCustomBaseUrl) {
        return Left<Failure, QueueStatus>(ServerFailure(error.message));
      }

      return _getFallbackQueueStatus();
    } on ParsingException catch (error) {
      return Left<Failure, QueueStatus>(UnexpectedFailure(error.message));
    } catch (_) {
      if (ApiConfig.hasCustomBaseUrl) {
        return const Left<Failure, QueueStatus>(
          ServerFailure('Unable to connect to the configured backend API.'),
        );
      }

      return _getFallbackQueueStatus();
    }
  }

  @override
  Future<Either<Failure, LiveBoard>> getLiveBoard() async {
    try {
      final model = await _remoteDataSource.getLiveBoard();
      return Right<Failure, LiveBoard>(model.toEntity());
    } on ServerException catch (error) {
      if (ApiConfig.hasCustomBaseUrl) {
        return Left<Failure, LiveBoard>(ServerFailure(error.message));
      }

      return _getFallbackLiveBoard();
    } on ParsingException catch (error) {
      return Left<Failure, LiveBoard>(UnexpectedFailure(error.message));
    } catch (_) {
      if (ApiConfig.hasCustomBaseUrl) {
        return const Left<Failure, LiveBoard>(
          ServerFailure('Unable to connect to the configured backend API.'),
        );
      }

      return _getFallbackLiveBoard();
    }
  }

  @override
  Future<Either<Failure, JoinQueueResult>> joinQueueFromQr({
    required String qrPayload,
    required String studentId,
    required String transactionType,
    required bool manual,
  }) async {
    try {
      final model = await _remoteDataSource.joinQueue(
        qrPayload: qrPayload,
        studentId: studentId,
        transactionType: transactionType,
        manual: manual,
      );
      return Right<Failure, JoinQueueResult>(model.toEntity());
    } on ServerException catch (error) {
      return Left<Failure, JoinQueueResult>(ServerFailure(error.message));
    } on ParsingException catch (error) {
      return Left<Failure, JoinQueueResult>(UnexpectedFailure(error.message));
    } catch (_) {
      return Left<Failure, JoinQueueResult>(
        ServerFailure(
          ApiConfig.hasCustomBaseUrl
              ? 'Unable to connect to the configured backend API.'
              : 'Unable to connect to the backend API. A real queue number can only be issued online.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> initializeNotifications() async {
    try {
      await _notificationDataSource.initialize();
    } catch (_) {
      return Right<Failure, Unit>(unit);
    }

    return Right<Failure, Unit>(unit);
  }

  @override
  Future<Either<Failure, Unit>> subscribeToQueueTopic(
    String queueNumber,
  ) async {
    try {
      await _notificationDataSource.subscribeToQueueTopic(queueNumber);
    } catch (_) {
      return Right<Failure, Unit>(unit);
    }

    return Right<Failure, Unit>(unit);
  }

  Future<Either<Failure, QueueStatus>> _getFallbackQueueStatus() async {
    try {
      final model = await _localDataSource.getQueueStatus();
      return Right<Failure, QueueStatus>(model.toEntity());
    } on CacheException catch (error) {
      return Left<Failure, QueueStatus>(CacheFailure(error.message));
    } catch (_) {
      return const Left<Failure, QueueStatus>(
        CacheFailure('Unable to load queue fallback data.'),
      );
    }
  }

  Future<Either<Failure, LiveBoard>> _getFallbackLiveBoard() async {
    try {
      final model = await _localDataSource.getLiveBoard();
      return Right<Failure, LiveBoard>(model.toEntity());
    } on CacheException catch (error) {
      return Left<Failure, LiveBoard>(CacheFailure(error.message));
    } catch (_) {
      return const Left<Failure, LiveBoard>(
        CacheFailure('Unable to load live board fallback data.'),
      );
    }
  }
}
