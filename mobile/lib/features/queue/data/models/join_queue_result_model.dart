import 'package:exequeue_mobile/features/queue/domain/entities/join_queue_result.dart';

class JoinQueueResultModel extends JoinQueueResult {
  const JoinQueueResultModel({required super.queueNumber});

  factory JoinQueueResultModel.fromJson(Map<String, dynamic> json) {
    return JoinQueueResultModel(
      queueNumber: json['queue_number'] as String? ?? 'A021',
    );
  }

  factory JoinQueueResultModel.demo(String queueNumber) {
    return JoinQueueResultModel(queueNumber: queueNumber);
  }

  JoinQueueResult toEntity() {
    return JoinQueueResult(queueNumber: queueNumber);
  }
}
