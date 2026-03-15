import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
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
}
