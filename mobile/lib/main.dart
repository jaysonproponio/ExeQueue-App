import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/core/bloc/app_bloc_observer.dart';
import 'package:exequeue_mobile/core/di/service_locator.dart';
import 'package:exequeue_mobile/core/theme/app_theme.dart';
import 'package:exequeue_mobile/core/usecases/usecase.dart';
import 'package:exequeue_mobile/features/home/presentation/pages/home_shell_page.dart';
import 'package:exequeue_mobile/features/queue/domain/services/queue_foreground_alert_bus.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/initialize_notifications.dart';
import 'package:exequeue_mobile/features/queue/presentation/widgets/queue_foreground_alert_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  await initDependencies();
  try {
    await sl<InitializeNotifications>()(const NoParams());
  } catch (_) {
    // Notification setup must never block the shell from rendering.
  }
  runApp(const ExeQueueApp());
}

class ExeQueueApp extends StatelessWidget {
  const ExeQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExeQueue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: QueueForegroundAlertHost(
        alertBus: sl<QueueForegroundAlertBus>(),
        child: const HomeShellPage(),
      ),
    );
  }
}
