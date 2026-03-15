import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLinkBridge {
  static const MethodChannel _methodChannel = MethodChannel(
    'exequeue_mobile/app_links/methods',
  );
  static const EventChannel _eventChannel = EventChannel(
    'exequeue_mobile/app_links/events',
  );

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Stream<String> get links {
    if (!_isSupportedPlatform) {
      return const Stream<String>.empty();
    }

    return _eventChannel
        .receiveBroadcastStream()
        .where((dynamic event) => event != null)
        .map(
          (dynamic event) => event.toString().trim(),
        )
        .where((String value) => value.isNotEmpty);
  }

  Future<String?> getInitialLink() async {
    if (!_isSupportedPlatform) {
      return null;
    }

    try {
      final link = await _methodChannel.invokeMethod<String>('getInitialLink');
      if (link == null) {
        return null;
      }

      final normalized = link.trim();
      return normalized.isEmpty ? null : normalized;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
