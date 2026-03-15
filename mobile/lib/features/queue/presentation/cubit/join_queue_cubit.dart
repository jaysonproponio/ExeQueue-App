import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/features/queue/domain/usecases/join_queue_from_qr.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/subscribe_to_queue_topic.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/join_queue_state.dart';

class JoinQueueCubit extends Cubit<JoinQueueState> {
  JoinQueueCubit({
    required JoinQueueFromQr joinQueueFromQr,
    required SubscribeToQueueTopic subscribeToQueueTopic,
  })  : _joinQueueFromQr = joinQueueFromQr,
        _subscribeToQueueTopic = subscribeToQueueTopic,
        super(const JoinQueueInitial());

  final JoinQueueFromQr _joinQueueFromQr;
  final SubscribeToQueueTopic _subscribeToQueueTopic;

  Future<void> joinQueue(
    String qrPayload, {
    bool manual = false,
  }) async {
    if (state is JoinQueueLoading) {
      return;
    }

    emit(const JoinQueueLoading());

    final result = await _joinQueueFromQr(
      JoinQueueFromQrParams(
        qrPayload: qrPayload,
        manual: manual,
      ),
    );

    await result.fold(
      (failure) async {
        emit(JoinQueueError(failure));
      },
      (joinResult) async {
        await _subscribeToQueueTopic(
          SubscribeToQueueTopicParams(queueNumber: joinResult.queueNumber),
        );
        if (isClosed) {
          return;
        }

        emit(JoinQueueSuccess(joinResult));
      },
    );
  }
}
