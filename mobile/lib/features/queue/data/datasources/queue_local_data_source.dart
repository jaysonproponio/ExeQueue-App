import 'package:exequeue_mobile/features/queue/data/models/live_board_model.dart';
import 'package:exequeue_mobile/features/queue/data/models/queue_status_model.dart';

abstract class QueueLocalDataSource {
  Future<QueueStatusModel> getQueueStatus();

  Future<LiveBoardModel> getLiveBoard();
}

class QueueLocalDataSourceImpl implements QueueLocalDataSource {
  @override
  Future<QueueStatusModel> getQueueStatus() async {
    return QueueStatusModel.demo();
  }

  @override
  Future<LiveBoardModel> getLiveBoard() async {
    return LiveBoardModel.empty();
  }
}
