import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/core/di/service_locator.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/live_board.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/live_board_cubit.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/live_board_state.dart';
import 'package:exequeue_mobile/features/queue/presentation/widgets/live_board_card.dart';

class LiveBoardPage extends StatelessWidget {
  const LiveBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveBoardCubit>(
      create: (_) => sl<LiveBoardCubit>()..startLiveUpdates(),
      child: const _LiveBoardView(),
    );
  }
}

class _LiveBoardView extends StatelessWidget {
  const _LiveBoardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveBoardCubit, LiveBoardState>(
      builder: (context, state) {
        final boardData = state.boardData ?? LiveBoard.demo();
        final loading = state is LiveBoardInitial || state is LiveBoardLoading;
        final errorMessage =
            state is LiveBoardError ? state.failure.message : null;

        return RefreshIndicator(
          onRefresh: () => context.read<LiveBoardCubit>().refreshBoard(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: <Widget>[
              if (boardData.isDemo) const _LiveBoardDemoBanner(),
              if (boardData.isDemo) const SizedBox(height: 18),
              LiveBoardCard(boardData: boardData, loading: loading),
              if (errorMessage != null) ...<Widget>[
                const SizedBox(height: 18),
                _LiveBoardErrorBanner(message: errorMessage),
              ],
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.circle,
                        size: 12,
                        color: Color(0xFF34A853),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Realtime queue updates sync every 5 seconds.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.read<LiveBoardCubit>().refreshBoard(),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveBoardDemoBanner extends StatelessWidget {
  const _LiveBoardDemoBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            const Icon(Icons.info_outline, color: Color(0xFFFB8C00)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Live board is using demo data until the backend API is reachable.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBoardErrorBanner extends StatelessWidget {
  const _LiveBoardErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            const Icon(Icons.info_outline, color: Color(0xFFFB8C00)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
