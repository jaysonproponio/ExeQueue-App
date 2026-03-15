import 'package:flutter/foundation.dart';

class PendingQueueLinkStore extends ChangeNotifier {
  String? _pendingPayload;

  void stagePendingPayload(String payload) {
    final normalized = payload.trim();
    if (normalized.isEmpty) {
      return;
    }

    _pendingPayload = normalized;
    notifyListeners();
  }

  String? consumePendingPayload() {
    final payload = _pendingPayload;
    _pendingPayload = null;
    return payload;
  }
}
