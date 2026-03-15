import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/core/platform/app_link_bridge.dart';
import 'package:exequeue_mobile/core/di/service_locator.dart';
import 'package:exequeue_mobile/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:exequeue_mobile/features/home/presentation/cubit/home_shell_state.dart';
import 'package:exequeue_mobile/features/queue/presentation/pages/live_board_page.dart';
import 'package:exequeue_mobile/features/queue/presentation/pages/my_queue_page.dart';
import 'package:exequeue_mobile/features/queue/presentation/pages/scan_qr_page.dart';
import 'package:exequeue_mobile/features/queue/presentation/session/pending_queue_link_store.dart';

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

class _HomeShellView extends StatefulWidget {
  const _HomeShellView();

  @override
  State<_HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<_HomeShellView> {
  late final AppLinkBridge _appLinkBridge = sl<AppLinkBridge>();
  late final PendingQueueLinkStore _pendingQueueLinkStore =
      sl<PendingQueueLinkStore>();
  StreamSubscription<String>? _appLinkSubscription;

  static const List<String> _titles = <String>[
    'My Queue',
    'Scan QR Code',
    'Live Queue Board',
  ];

  @override
  void initState() {
    super.initState();
    _appLinkSubscription = _appLinkBridge.links.listen(_handleIncomingPayload);
    unawaited(_loadInitialPayload());
  }

  @override
  void dispose() {
    unawaited(_appLinkSubscription?.cancel());
    super.dispose();
  }

  Future<void> _loadInitialPayload() async {
    final payload = await _appLinkBridge.getInitialLink();
    if (!mounted || payload == null) {
      return;
    }

    _handleIncomingPayload(payload);
  }

  void _handleIncomingPayload(String payload) {
    final normalized = payload.trim();
    if (!_isJoinPayload(normalized)) {
      return;
    }

    _pendingQueueLinkStore.stagePendingPayload(normalized);
    context.read<HomeShellCubit>().changeTab(1);
  }

  bool _isJoinPayload(String payload) {
    if (payload.isEmpty) {
      return false;
    }

    if (payload.toUpperCase().startsWith('JOIN-')) {
      return true;
    }

    final uri = Uri.tryParse(payload);
    if (uri == null || uri.scheme.toLowerCase() != 'exequeue') {
      return false;
    }

    final host = uri.host.toLowerCase();
    return host == 'join' || uri.pathSegments.contains('join');
  }

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
          body: _buildScreen(state.currentIndex),
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

  Widget _buildScreen(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return const MyQueuePage();
      case 1:
        return const ScanQrPage();
      case 2:
        return const LiveBoardPage();
      default:
        return const MyQueuePage();
    }
  }
}
