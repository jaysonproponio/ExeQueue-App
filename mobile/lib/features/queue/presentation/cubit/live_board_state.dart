import 'package:equatable/equatable.dart';

import 'package:exequeue_mobile/core/error/failures.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/live_board.dart';

abstract class LiveBoardState extends Equatable {
  const LiveBoardState({this.boardData});

  final LiveBoard? boardData;

  @override
  List<Object?> get props => <Object?>[boardData];
}

class LiveBoardInitial extends LiveBoardState {
  const LiveBoardInitial();
}

class LiveBoardLoading extends LiveBoardState {
  const LiveBoardLoading({super.boardData});
}

class LiveBoardLoaded extends LiveBoardState {
  const LiveBoardLoaded(LiveBoard boardData) : super(boardData: boardData);
}

class LiveBoardError extends LiveBoardState {
  const LiveBoardError(
    this.failure, {
    super.boardData,
  });

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure, boardData];
}
