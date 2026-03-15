import 'package:flutter/material.dart';

import 'live_board_screen.dart';
import 'my_queue_screen.dart';
import 'scan_qr_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const List<String> _titles = <String>[
    'My Queue',
    'Scan QR Code',
    'Live Queue Board',
  ];

  late final List<Widget> _screens = <Widget>[
    const MyQueueScreen(),
    const ScanQrScreen(),
    const LiveBoardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _titles[_currentIndex],
            key: ValueKey<String>(_titles[_currentIndex]),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
  }
}
