import 'package:get_it/get_it.dart';

import 'package:exequeue_mobile/core/platform/app_link_bridge.dart';
import 'package:exequeue_mobile/features/home/home_injection.dart';
import 'package:exequeue_mobile/features/queue/queue_injection.dart';

final GetIt sl = GetIt.instance;
bool _initialized = false;

Future<void> initDependencies() async {
  if (_initialized) {
    return;
  }

  sl.registerLazySingleton<AppLinkBridge>(AppLinkBridge.new);
  registerQueueFeature(sl);
  registerHomeFeature(sl);
  _initialized = true;
}
