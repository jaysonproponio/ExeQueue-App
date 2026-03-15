import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  late final AnimationController _lineController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  bool _isProcessing = false;
  String? _assignedQueueNumber;

  Future<void> _handleDetection(String qrPayload, {bool manual = false}) async {
    if (_isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final queueNumber = await _apiService.joinQueueFromQr(
        qrPayload,
        manual: manual,
      );
      await NotificationService.subscribeToQueueTopic(queueNumber);

      if (!mounted) {
        return;
      }

      setState(() => _assignedQueueNumber = queueNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Queue Number Assigned: $queueNumber'),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _lineController.dispose();
    _scannerController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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

                            final rawValue = capture.barcodes.first.rawValue;
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
                                    borderRadius: BorderRadius.circular(99),
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
                      if (_isProcessing)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xAA10243E),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
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
                  onPressed: _isProcessing
                      ? null
                      : () => _handleDetection('manual-entry', manual: true),
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
          child: _assignedQueueNumber == null
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
                  key: ValueKey<String>(_assignedQueueNumber!),
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
                          _assignedQueueNumber!,
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
  }
}
