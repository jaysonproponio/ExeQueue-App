import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';
import 'package:exequeue_mobile/features/queue/domain/repositories/queue_repository.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/get_queue_status.dart';

class MockQueueRepository extends Mock implements QueueRepository {}

void main() {
  late MockQueueRepository repository;
  late GetQueueStatus useCase;

  setUp(() {
    repository = MockQueueRepository();
    useCase = GetQueueStatus(repository);
  });

  test('delegates queue status retrieval to the repository', () async {
    const params = GetQueueStatusParams(studentName: 'Juan Dela Cruz');

    when(
      () => repository.getQueueStatus(studentName: params.studentName),
    ).thenAnswer((_) async => Right(QueueStatus.demo()));

    final result = await useCase(params);

    result.fold(
      (_) => fail('Expected queue status data.'),
      (queueStatus) => expect(queueStatus, QueueStatus.demo()),
    );
    verify(
      () => repository.getQueueStatus(studentName: params.studentName),
    ).called(1);
  });
}
