import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/features/home/presentation/cubit/home_shell_state.dart';

class HomeShellCubit extends Cubit<HomeShellState> {
  HomeShellCubit() : super(const HomeShellState());

  void changeTab(int index) {
    if (index == state.currentIndex) {
      return;
    }

    emit(state.copyWith(currentIndex: index));
  }
}
