import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/features/queue/domain/usecases/get_queue_status.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/queue_status_state.dart';

class QueueStatusCubit extends Cubit<QueueStatusState> {
  QueueStatusCubit({
    required GetQueueStatus getQueueStatus,
  })  : _getQueueStatus = getQueueStatus,
        super(const QueueStatusInitial());

  final GetQueueStatus _getQueueStatus;

  Future<void> loadQueueStatus({
    String studentName = 'Juan Dela Cruz',
  }) async {
    emit(const QueueStatusLoading());

    final result = await _getQueueStatus(
      GetQueueStatusParams(studentName: studentName),
    );

    result.fold(
      (failure) => emit(QueueStatusError(failure)),
      (queueStatus) => emit(QueueStatusLoaded(queueStatus)),
    );
  }
}
