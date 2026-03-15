import 'package:equatable/equatable.dart';

class JoinQueueResult extends Equatable {
  const JoinQueueResult({required this.queueNumber});

  final String queueNumber;

  @override
  List<Object> get props => <Object>[queueNumber];
}
