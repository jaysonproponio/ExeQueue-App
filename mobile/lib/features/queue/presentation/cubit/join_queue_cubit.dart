import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/features/queue/domain/usecases/join_queue_from_qr.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/subscribe_to_queue_topic.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/join_queue_state.dart';
import 'package:exequeue_mobile/features/queue/presentation/session/queue_session_store.dart';

class JoinQueueCubit extends Cubit<JoinQueueState> {
  JoinQueueCubit({
    required JoinQueueFromQr joinQueueFromQr,
    required QueueSessionStore queueSessionStore,
    required SubscribeToQueueTopic subscribeToQueueTopic,
  })  : _joinQueueFromQr = joinQueueFromQr,
        _queueSessionStore = queueSessionStore,
        _subscribeToQueueTopic = subscribeToQueueTopic,
        super(const JoinQueueInitial());

  final JoinQueueFromQr _joinQueueFromQr;
  final QueueSessionStore _queueSessionStore;
  final SubscribeToQueueTopic _subscribeToQueueTopic;

  Future<bool> joinQueue(
    String qrPayload, {
    required String studentId,
    required String transactionType,
    bool manual = false,
  }) async {
    if (state is JoinQueueLoading) {
      return false;
    }

    emit(const JoinQueueLoading());
    var joinedSuccessfully = false;

    final result = await _joinQueueFromQr(
      JoinQueueFromQrParams(
        qrPayload: qrPayload,
        studentId: studentId,
        transactionType: transactionType,
        manual: manual,
      ),
    );

    await result.fold(
      (failure) async {
        emit(JoinQueueError(failure));
      },
      (joinResult) async {
        joinedSuccessfully = true;
        _queueSessionStore.setActiveQueueNumber(joinResult.queueNumber);
        await _subscribeToQueueTopic(
          SubscribeToQueueTopicParams(queueNumber: joinResult.queueNumber),
        );
        if (isClosed) {
          return;
        }

        emit(JoinQueueSuccess(joinResult));
      },
    );

    return joinedSuccessfully;
  }
}
