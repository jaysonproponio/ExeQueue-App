import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/features/queue/domain/usecases/get_queue_status.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/queue_status_state.dart';
import 'package:exequeue_mobile/features/queue/presentation/session/queue_session_store.dart';

class QueueStatusCubit extends Cubit<QueueStatusState> {
  QueueStatusCubit({
    required GetQueueStatus getQueueStatus,
    required QueueSessionStore queueSessionStore,
  })  : _getQueueStatus = getQueueStatus,
        _queueSessionStore = queueSessionStore,
        super(const QueueStatusInitial());

  final GetQueueStatus _getQueueStatus;
  final QueueSessionStore _queueSessionStore;

  Future<void> loadQueueStatus() async {
    final activeQueueNumber = _queueSessionStore.activeQueueNumber;
    if (activeQueueNumber == null || activeQueueNumber.trim().isEmpty) {
      emit(const QueueStatusEmpty());
      return;
    }

    emit(const QueueStatusLoading());

    final result = await _getQueueStatus(
      GetQueueStatusParams(queueNumber: activeQueueNumber),
    );

    result.fold(
      (failure) => emit(QueueStatusError(failure)),
      (queueStatus) => emit(QueueStatusLoaded(queueStatus)),
    );
  }

  void clearQueueStatus() {
    _queueSessionStore.clear();
    emit(const QueueStatusEmpty());
  }
}
