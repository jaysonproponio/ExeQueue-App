import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/get_queue_status.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/queue_status_cubit.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/queue_status_state.dart';

class MockGetQueueStatus extends Mock implements GetQueueStatus {}

void main() {
  late MockGetQueueStatus getQueueStatus;

  setUpAll(() {
    registerFallbackValue(const GetQueueStatusParams());
  });

  setUp(() {
    getQueueStatus = MockGetQueueStatus();
  });

  blocTest<QueueStatusCubit, QueueStatusState>(
    'emits loading then loaded when the use case succeeds',
    build: () {
      when(
        () => getQueueStatus(any()),
      ).thenAnswer((_) async => Right(QueueStatus.demo()));

      return QueueStatusCubit(getQueueStatus: getQueueStatus);
    },
    act: (cubit) => cubit.loadQueueStatus(),
    expect: () => <Matcher>[
      isA<QueueStatusLoading>(),
      isA<QueueStatusLoaded>().having(
        (state) => state.queueStatus,
        'queueStatus',
        QueueStatus.demo(),
      ),
    ],
    verify: (_) {
      verify(() => getQueueStatus(const GetQueueStatusParams())).called(1);
    },
  );

  blocTest<QueueStatusCubit, QueueStatusState>(
    'emits loading then error when the use case fails',
    build: () {
      when(
        () => getQueueStatus(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('Failed')));

      return QueueStatusCubit(getQueueStatus: getQueueStatus);
    },
    act: (cubit) => cubit.loadQueueStatus(),
    expect: () => <Matcher>[
      isA<QueueStatusLoading>(),
      isA<QueueStatusError>().having(
        (state) => state.failure.message,
        'message',
        'Failed',
      ),
    ],
  );
}
