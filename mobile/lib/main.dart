import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import 'package:exequeue_mobile/core/bloc/app_bloc_observer.dart';
import 'package:exequeue_mobile/core/di/service_locator.dart';
import 'package:exequeue_mobile/core/theme/app_theme.dart';
import 'package:exequeue_mobile/core/usecases/usecase.dart';
import 'package:exequeue_mobile/features/home/presentation/pages/home_shell_page.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/initialize_notifications.dart';

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
      home: const HomeShellPage(),
    );
  }
}
