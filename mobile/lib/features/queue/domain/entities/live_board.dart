import 'package:equatable/equatable.dart';

class LiveBoard extends Equatable {
  const LiveBoard({
    required this.nowServing,
    required this.nextQueues,
    required this.updatedAt,
    this.isDemo = false,
  });

  final String nowServing;
  final List<String> nextQueues;
  final DateTime updatedAt;
  final bool isDemo;

  factory LiveBoard.demo() {
    return LiveBoard(
      nowServing: 'A021',
      nextQueues: const <String>['A022', 'A023', 'A024'],
      updatedAt: DateTime.now(),
      isDemo: true,
    );
  }

  @override
  List<Object> get props => <Object>[nowServing, nextQueues, updatedAt, isDemo];
}
