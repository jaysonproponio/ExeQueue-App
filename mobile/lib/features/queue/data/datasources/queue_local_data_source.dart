import 'package:exequeue_mobile/features/queue/data/models/join_queue_result_model.dart';
import 'package:exequeue_mobile/features/queue/data/models/live_board_model.dart';
import 'package:exequeue_mobile/features/queue/data/models/queue_status_model.dart';

abstract class QueueLocalDataSource {
  Future<QueueStatusModel> getQueueStatus();

  Future<LiveBoardModel> getLiveBoard();

  Future<JoinQueueResultModel> getJoinQueueFallback();
}

class QueueLocalDataSourceImpl implements QueueLocalDataSource {
  int _nextQueueSequence = 20;

  @override
  Future<QueueStatusModel> getQueueStatus() async {
    return QueueStatusModel.demo();
  }

  @override
  Future<LiveBoardModel> getLiveBoard() async {
    return LiveBoardModel.demo();
  }

  @override
  Future<JoinQueueResultModel> getJoinQueueFallback() async {
    _nextQueueSequence += 1;

    return JoinQueueResultModel.demo(
      'A${_nextQueueSequence.toString().padLeft(3, '0')}',
    );
  }
}
