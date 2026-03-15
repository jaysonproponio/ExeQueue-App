import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:exequeue_mobile/core/di/service_locator.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/join_queue_cubit.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/join_queue_state.dart';

class ScanQrPage extends StatelessWidget {
  const ScanQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JoinQueueCubit>(
      create: (_) => sl<JoinQueueCubit>(),
      child: const _ScanQrView(),
    );
  }
}

class _ScanQrView extends StatefulWidget {
  const _ScanQrView();

  @override
  State<_ScanQrView> createState() => _ScanQrViewState();
}

class _ScanQrViewState extends State<_ScanQrView>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  late final AnimationController _lineController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  bool _cooldownActive = false;

  bool get _isBusy {
    final state = context.read<JoinQueueCubit>().state;
    return state is JoinQueueLoading || _cooldownActive;
  }

  @override
  void dispose() {
    _lineController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleDetection(String qrPayload, {bool manual = false}) {
    if (_isBusy) {
      return;
    }

    _startCooldown();
    context.read<JoinQueueCubit>().joinQueue(
          qrPayload,
          manual: manual,
        );
  }

  void _startCooldown() {
    setState(() => _cooldownActive = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _cooldownActive = false);
      }
    });
  }

  void _onJoinStateChanged(BuildContext context, JoinQueueState state) {
    if (state is JoinQueueSuccess) {
      _showSnackBar(
        'Queue Number Assigned: ${state.result.queueNumber}',
      );
      return;
    }

    if (state is JoinQueueError) {
      _showSnackBar(state.failure.message);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<JoinQueueCubit, JoinQueueState>(
      listener: _onJoinStateChanged,
      builder: (context, state) {
        final isProcessing = state is JoinQueueLoading;
        final assignedQueueNumber = state is JoinQueueSuccess
            ? state.result.queueNumber
            : null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: MobileScanner(
                              controller: _scannerController,
                              onDetect: (capture) {
                                if (capture.barcodes.isEmpty) {
                                  return;
                                }

                                final rawValue =
                                    capture.barcodes.first.rawValue;
                                if (rawValue == null || rawValue.isEmpty) {
                                  return;
                                }

                                _handleDetection(rawValue);
                              },
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFFFFFFF),
                                width: 3,
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x331A73E8),
                                  blurRadius: 24,
                                  offset: Offset(0, 16),
                                ),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: AnimatedBuilder(
                                animation: _lineController,
                                builder: (context, _) {
                                  return Align(
                                    alignment: Alignment(
                                      0,
                                      (_lineController.value * 2) - 1,
                                    ),
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34A853),
                                        borderRadius:
                                            BorderRadius.circular(99),
                                        boxShadow: const <BoxShadow>[
                                          BoxShadow(
                                            color: Color(0x6634A853),
                                            blurRadius: 14,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (isProcessing)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xAA10243E),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Scan the QR code outside the cashier window to join the queue.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isBusy
                          ? null
                          : () => _handleDetection(
                                'manual-entry',
                                manual: true,
                              ),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Join Manually'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: assignedQueueNumber == null
                  ? Card(
                      key: const ValueKey<String>('idle'),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Your assigned queue number will appear here after a successful scan.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : Card(
                      key: ValueKey<String>(assignedQueueNumber),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Queue Number Assigned',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              assignedQueueNumber,
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
