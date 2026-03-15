import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/core/di/service_locator.dart';
import 'package:exequeue_mobile/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:exequeue_mobile/features/home/presentation/cubit/home_shell_state.dart';
import 'package:exequeue_mobile/features/queue/presentation/pages/live_board_page.dart';
import 'package:exequeue_mobile/features/queue/presentation/pages/my_queue_page.dart';
import 'package:exequeue_mobile/features/queue/presentation/pages/scan_qr_page.dart';

class HomeShellPage extends StatelessWidget {
  const HomeShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeShellCubit>(
      create: (_) => sl<HomeShellCubit>(),
      child: const _HomeShellView(),
    );
  }
}

class _HomeShellView extends StatelessWidget {
  const _HomeShellView();

  static const List<String> _titles = <String>[
    'My Queue',
    'Scan QR Code',
    'Live Queue Board',
  ];

  static const List<Widget> _screens = <Widget>[
    MyQueuePage(),
    ScanQrPage(),
    LiveBoardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeShellCubit, HomeShellState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _titles[state.currentIndex],
                key: ValueKey<String>(_titles[state.currentIndex]),
              ),
            ),
          ),
          body: IndexedStack(
            index: state.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: state.currentIndex,
            onTap: context.read<HomeShellCubit>().changeTab,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_number),
                label: 'My Queue',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan QR',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor),
                label: 'Live Board',
              ),
            ],
          ),
        );
      },
    );
  }
}
