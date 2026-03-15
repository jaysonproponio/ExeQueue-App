import 'package:equatable/equatable.dart';

class HomeShellState extends Equatable {
  const HomeShellState({this.currentIndex = 0});

  final int currentIndex;

  HomeShellState copyWith({int? currentIndex}) {
    return HomeShellState(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object> get props => <Object>[currentIndex];
}
