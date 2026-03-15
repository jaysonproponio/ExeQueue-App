import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'EXEQUEUE_API_BASE_URL',
  );
  static const Duration requestTimeout = Duration(seconds: 2);

  static String get baseUrl {
    final configured = _configuredBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      return 'http://localhost/exequeue/backend/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2/exequeue/backend/api';
      default:
        return 'http://localhost/exequeue/backend/api';
    }
  }

  static bool get hasCustomBaseUrl => _configuredBaseUrl.trim().isNotEmpty;
}
