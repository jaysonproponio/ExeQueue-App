import 'package:flutter/foundation.dart';

class QueueSessionStore extends ChangeNotifier {
  String? _activeQueueNumber;

  String? get activeQueueNumber => _activeQueueNumber;

  bool get hasActiveQueue =>
      _activeQueueNumber != null && _activeQueueNumber!.trim().isNotEmpty;

  void setActiveQueueNumber(String queueNumber) {
    final normalizedQueueNumber = queueNumber.trim();
    if (normalizedQueueNumber.isEmpty ||
        normalizedQueueNumber == _activeQueueNumber) {
      return;
    }

    _activeQueueNumber = normalizedQueueNumber;
    notifyListeners();
  }

  void clear() {
    if (_activeQueueNumber == null) {
      return;
    }

    _activeQueueNumber = null;
    notifyListeners();
  }
}
