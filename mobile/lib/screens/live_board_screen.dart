import 'dart:async';

import 'package:flutter/material.dart';

import '../models/queue_status.dart';
import '../services/api_service.dart';
import '../widgets/live_board_card.dart';

class LiveBoardScreen extends StatefulWidget {
  const LiveBoardScreen({super.key});

  @override
  State<LiveBoardScreen> createState() => _LiveBoardScreenState();
}

class _LiveBoardScreenState extends State<LiveBoardScreen> {
  final ApiService _apiService = ApiService();

  LiveBoardData _boardData = LiveBoardData.demo();
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshBoard();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshBoard(),
    );
  }

  Future<void> _refreshBoard() async {
    final boardData = await _apiService.fetchLiveBoard();

    if (!mounted) {
      return;
    }

    setState(() {
      _boardData = boardData;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshBoard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          LiveBoardCard(boardData: _boardData, loading: _loading),
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
                    onPressed: _refreshBoard,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
