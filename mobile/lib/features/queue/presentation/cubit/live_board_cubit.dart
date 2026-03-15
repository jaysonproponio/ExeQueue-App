import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/core/usecases/usecase.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/get_live_board.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/live_board_state.dart';

class LiveBoardCubit extends Cubit<LiveBoardState> {
  LiveBoardCubit({
    required GetLiveBoard getLiveBoard,
  })  : _getLiveBoard = getLiveBoard,
        super(const LiveBoardInitial());

  final GetLiveBoard _getLiveBoard;
  Timer? _refreshTimer;

  Future<void> startLiveUpdates() async {
    if (_refreshTimer != null) {
      return;
    }

    await refreshBoard(showLoader: true);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshBoard(),
    );
  }

  Future<void> refreshBoard({bool showLoader = false}) async {
    final currentBoard = state.boardData;
    if (showLoader || currentBoard != null) {
      emit(LiveBoardLoading(boardData: currentBoard));
    }

    final result = await _getLiveBoard(const NoParams());
    if (isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(
        LiveBoardError(
          failure,
          boardData: currentBoard,
        ),
      ),
      (boardData) => emit(LiveBoardLoaded(boardData)),
    );
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
