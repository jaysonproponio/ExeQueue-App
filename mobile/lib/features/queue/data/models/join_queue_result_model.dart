import 'package:exequeue_mobile/core/error/exceptions.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/join_queue_result.dart';

class JoinQueueResultModel extends JoinQueueResult {
  const JoinQueueResultModel({required super.queueNumber});

  factory JoinQueueResultModel.fromJson(Map<String, dynamic> json) {
    final queueNumber = (json['queue_number'] as String? ?? '').trim();
    if (queueNumber.isEmpty) {
      throw const ParsingException('Join queue response is missing queue_number.');
    }

    return JoinQueueResultModel(
      queueNumber: queueNumber,
    );
  }

  JoinQueueResult toEntity() {
    return JoinQueueResult(queueNumber: queueNumber);
  }
}
