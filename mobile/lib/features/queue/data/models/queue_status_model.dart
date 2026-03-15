import 'package:exequeue_mobile/features/queue/domain/entities/queue_stage.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';

class QueueStatusModel extends QueueStatus {
  const QueueStatusModel({
    required super.queueNumber,
    required super.nowServing,
    required super.peopleAhead,
    required super.estimatedWait,
    required super.status,
    required super.transactionType,
  });

  factory QueueStatusModel.fromJson(Map<String, dynamic> json) {
    return QueueStatusModel(
      queueNumber: json['queue_number'] as String? ?? 'A021',
      nowServing: json['now_serving'] as String? ?? 'A016',
      peopleAhead: (json['people_ahead'] as num?)?.toInt() ?? 5,
      estimatedWait: Duration(
        minutes: (json['estimated_wait_minutes'] as num?)?.toInt() ?? 15,
      ),
      status: queueStageFromValue(json['status'] as String?),
      transactionType:
          json['transaction_type'] as String? ?? 'Tuition Payment',
    );
  }

  factory QueueStatusModel.demo() {
    return const QueueStatusModel(
      queueNumber: 'A021',
      nowServing: 'A016',
      peopleAhead: 5,
      estimatedWait: Duration(minutes: 15),
      status: QueueStage.waiting,
      transactionType: 'Tuition Payment',
    );
  }

  QueueStatus toEntity() {
    return QueueStatus(
      queueNumber: queueNumber,
      nowServing: nowServing,
      peopleAhead: peopleAhead,
      estimatedWait: estimatedWait,
      status: status,
      transactionType: transactionType,
    );
  }
}
