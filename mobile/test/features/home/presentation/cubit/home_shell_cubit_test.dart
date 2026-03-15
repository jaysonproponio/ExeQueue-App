import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exequeue_mobile/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:exequeue_mobile/features/home/presentation/cubit/home_shell_state.dart';

void main() {
  group('HomeShellCubit', () {
    blocTest<HomeShellCubit, HomeShellState>(
      'emits an updated tab index',
      build: HomeShellCubit.new,
      act: (cubit) => cubit.changeTab(2),
      expect: () => <HomeShellState>[
        const HomeShellState(currentIndex: 2),
      ],
    );

    blocTest<HomeShellCubit, HomeShellState>(
      'does not emit when the current tab is selected again',
      build: HomeShellCubit.new,
      act: (cubit) => cubit.changeTab(0),
      expect: () => <HomeShellState>[],
    );
  });
}
