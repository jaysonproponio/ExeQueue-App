import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.ensureInitialized();
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
      home: const HomeShell(),
    );
  }
}
