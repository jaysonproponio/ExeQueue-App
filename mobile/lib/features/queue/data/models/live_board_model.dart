import 'package:exequeue_mobile/features/queue/domain/entities/live_board.dart';

class LiveBoardModel extends LiveBoard {
  const LiveBoardModel({
    required super.nowServing,
    required super.nextQueues,
    required super.updatedAt,
    required super.isDemo,
  });

  factory LiveBoardModel.fromJson(Map<String, dynamic> json) {
    final rawQueues = json['next_queues'] as List<dynamic>? ?? <dynamic>[];
    final nextQueues = rawQueues
        .map((dynamic entry) => entry.toString())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);

    return LiveBoardModel(
      nowServing: json['now_serving'] as String? ?? 'A021',
      nextQueues: nextQueues.isEmpty
          ? const <String>['A022', 'A023', 'A024']
          : nextQueues,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      isDemo: false,
    );
  }

  factory LiveBoardModel.demo() {
    return LiveBoardModel(
      nowServing: 'A021',
      nextQueues: const <String>['A022', 'A023', 'A024'],
      updatedAt: DateTime.now(),
      isDemo: true,
    );
  }

  LiveBoard toEntity() {
    return LiveBoard(
      nowServing: nowServing,
      nextQueues: nextQueues,
      updatedAt: updatedAt,
      isDemo: isDemo,
    );
  }
}
