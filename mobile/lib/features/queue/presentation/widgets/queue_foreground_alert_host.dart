import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:exequeue_mobile/features/queue/domain/entities/queue_alert.dart';
import 'package:exequeue_mobile/features/queue/domain/services/queue_foreground_alert_bus.dart';

class QueueForegroundAlertHost extends StatefulWidget {
  const QueueForegroundAlertHost({
    super.key,
    required this.alertBus,
    required this.child,
  });

  final QueueForegroundAlertBus alertBus;
  final Widget child;

  @override
  State<QueueForegroundAlertHost> createState() =>
      _QueueForegroundAlertHostState();
}

class _QueueForegroundAlertHostState extends State<QueueForegroundAlertHost> {
  StreamSubscription<QueueAlert>? _alertSubscription;
  bool _isShowingDialog = false;
  String? _lastAlertQueueNumber;

  @override
  void initState() {
    super.initState();
    _alertSubscription = widget.alertBus.alerts.listen((QueueAlert alert) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_showAlert(alert));
      });
    });
  }

  @override
  void dispose() {
    unawaited(_alertSubscription?.cancel());
    super.dispose();
  }

  Future<void> _showAlert(QueueAlert alert) async {
    if (!mounted || !alert.isThresholdAlert) {
      return;
    }

    if (_isShowingDialog && _lastAlertQueueNumber == alert.queueNumber) {
      return;
    }

    _isShowingDialog = true;
    _lastAlertQueueNumber = alert.queueNumber;

    await _vibratePhone();
    if (!mounted) {
      _isShowingDialog = false;
      return;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Queue alert',
      barrierColor: const Color(0x8010243E),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x3310243E),
                        blurRadius: 28,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0x141A73E8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFF1A73E8),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        alert.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10243E),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          alert.queueNumber,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        alert.body,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        alert.distanceLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF5F6E82),
                            ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Dismiss'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    _isShowingDialog = false;
  }

  Future<void> _vibratePhone() async {
    try {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await HapticFeedback.vibrate();
    } catch (_) {
      // Haptic feedback availability depends on the device.
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
