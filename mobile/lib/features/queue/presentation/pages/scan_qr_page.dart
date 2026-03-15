import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:exequeue_mobile/core/di/service_locator.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/join_queue_cubit.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/join_queue_state.dart';
import 'package:exequeue_mobile/features/queue/presentation/session/pending_queue_link_store.dart';

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PendingQueueLinkStore _pendingQueueLinkStore =
      sl<PendingQueueLinkStore>();
  late MobileScannerController _scannerController;

  late final AnimationController _lineController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  bool _cooldownActive = false;
  bool _joinFormVisible = false;
  bool _lensChangeInProgress = false;
  _ScannerLensPreset _selectedLensPreset = _ScannerLensPreset.normal;

  bool get _isBusy {
    final state = context.read<JoinQueueCubit>().state;
    return state is JoinQueueLoading ||
        _cooldownActive ||
        _joinFormVisible ||
        _lensChangeInProgress;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = _buildScannerController();
    _pendingQueueLinkStore.addListener(_consumePendingPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingPayload();
    });
  }

  MobileScannerController _buildScannerController() {
    return MobileScannerController(
      androidCameraLensMode: _cameraLensModeForPreset(_selectedLensPreset),
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingQueueLinkStore.removeListener(_consumePendingPayload);
    _lineController.dispose();
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        unawaited(_pauseScanner());
        break;
      case AppLifecycleState.resumed:
        unawaited(_resumeScanner());
        break;
    }
  }

  void _handleDetection(String qrPayload, {bool manual = false}) {
    if (_isBusy) {
      return;
    }

    unawaited(_startJoinFlow(qrPayload, manual: manual));
  }

  void _consumePendingPayload() {
    if (!mounted || _isBusy) {
      return;
    }

    final payload = _pendingQueueLinkStore.consumePendingPayload();
    if (payload == null) {
      return;
    }

    _handleDetection(payload);
  }

  Future<void> _startJoinFlow(
    String qrPayload, {
    required bool manual,
  }) async {
    setState(() => _joinFormVisible = true);
    await _pauseScanner();
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return _JoinQueueDetailsSheet(
          manual: manual,
          onSubmit: (formData) => _submitJoinRequest(
            qrPayload,
            formData,
            manual: manual,
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() => _joinFormVisible = false);
    await _resumeScanner();
  }

  Future<bool> _submitJoinRequest(
    String qrPayload,
    _JoinQueueFormData formData, {
    required bool manual,
  }) async {
    _startCooldown();
    return context.read<JoinQueueCubit>().joinQueue(
          qrPayload,
          studentId: formData.studentId,
          transactionType: formData.transactionType,
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

  Future<void> _pauseScanner() async {
    final scannerState = _scannerController.value;
    if (!scannerState.isInitialized || !scannerState.isRunning) {
      return;
    }

    try {
      await _scannerController.stop();
    } catch (_) {
      // The scanner can already be stopped while Flutter is transitioning
      // between lifecycle states.
    }
  }

  Future<void> _resumeScanner() async {
    final scannerState = _scannerController.value;
    if (scannerState.error != null || scannerState.isRunning) {
      return;
    }

    try {
      await _scannerController.start(cameraDirection: CameraFacing.back);
    } catch (_) {
      // The scanner error panel will handle surfacing a recoverable failure.
    }
  }

  AndroidCameraLensMode _cameraLensModeForPreset(_ScannerLensPreset preset) {
    switch (preset) {
      case _ScannerLensPreset.ultraWide:
        return AndroidCameraLensMode.ultraWide;
      case _ScannerLensPreset.normal:
        return AndroidCameraLensMode.normal;
    }
  }

  String _cameraErrorMessage(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera access is blocked. Allow camera permission, then tap Retry Camera.';
      case MobileScannerErrorCode.unsupported:
        return 'This device does not expose a supported camera to the scanner.';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
      case MobileScannerErrorCode.controllerDisposed:
      case MobileScannerErrorCode.controllerUninitialized:
      case MobileScannerErrorCode.genericError:
        return error.errorDetails?.message?.trim().isNotEmpty == true
            ? error.errorDetails!.message!
            : 'Unable to start the camera preview.';
    }
  }

  Future<void> _retryScanner() async {
    if (_lensChangeInProgress) {
      return;
    }

    setState(() => _lensChangeInProgress = true);

    try {
      await _pauseScanner();
      await _scannerController.setAndroidCameraLensMode(
        _cameraLensModeForPreset(_selectedLensPreset),
      );
      await _scannerController.start(cameraDirection: CameraFacing.back);
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to restart the camera preview.');
      }
    } finally {
      if (mounted) {
        setState(() => _lensChangeInProgress = false);
      }
    }
  }

  Future<void> _switchLensPreset(_ScannerLensPreset preset) async {
    if (_lensChangeInProgress || _selectedLensPreset == preset) {
      return;
    }

    final previousPreset = _selectedLensPreset;
    setState(() {
      _selectedLensPreset = preset;
      _lensChangeInProgress = true;
    });

    try {
      await _scannerController.setAndroidCameraLensMode(
        _cameraLensModeForPreset(preset),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _selectedLensPreset = previousPreset);
      _showSnackBar('Unable to switch the camera lens on this device.');
    } finally {
      if (mounted) {
        setState(() => _lensChangeInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<JoinQueueCubit, JoinQueueState>(
      listener: _onJoinStateChanged,
      builder: (context, state) {
        final isProcessing = state is JoinQueueLoading;
        final assignedQueueNumber =
            state is JoinQueueSuccess ? state.result.queueNumber : null;
        final isScannerOverlayVisible = isProcessing || _lensChangeInProgress;

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
                              placeholderBuilder: (context, child) {
                                return const ColoredBox(
                                  color: Color(0xFF10243E),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, child) {
                                return ColoredBox(
                                  color: const Color(0xFF10243E),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.videocam_off,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          _cameraErrorMessage(error),
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        FilledButton.icon(
                                          onPressed: _retryScanner,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Retry Camera'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                          if (isScannerOverlayVisible)
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
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _scannerController,
                      builder: (context, scannerState, _) {
                        final isCameraReady = scannerState.isInitialized &&
                            scannerState.isRunning;
                        final availableCameras =
                            scannerState.availableCameras ?? 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Rear Camera Lens',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                ChoiceChip(
                                  label: const Text('Ultra Wide'),
                                  selected: _selectedLensPreset ==
                                      _ScannerLensPreset.ultraWide,
                                  onSelected: isCameraReady
                                      ? (_) {
                                          _switchLensPreset(
                                            _ScannerLensPreset.ultraWide,
                                          );
                                        }
                                      : null,
                                ),
                                ChoiceChip(
                                  label: const Text('Normal'),
                                  selected: _selectedLensPreset ==
                                      _ScannerLensPreset.normal,
                                  onSelected: isCameraReady
                                      ? (_) {
                                          _switchLensPreset(
                                            _ScannerLensPreset.normal,
                                          );
                                        }
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isCameraReady
                                  ? availableCameras >= 3
                                      ? 'Ultra Wide uses the phone\'s widest '
                                          'rear camera. Normal uses the '
                                          'primary rear camera.'
                                      : 'If this phone only exposes one rear '
                                          'camera to Android, both options '
                                          'may look the same.'
                                  : 'Wait for the camera preview to finish '
                                      'loading before switching lenses.',
                              style: textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF5F6E82),
                              ),
                            ),
                          ],
                        );
                      },
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

class _JoinQueueFormData {
  const _JoinQueueFormData({
    required this.studentId,
    required this.transactionType,
  });

  final String studentId;
  final String transactionType;
}

class _JoinQueueDetailsSheet extends StatefulWidget {
  const _JoinQueueDetailsSheet({
    required this.manual,
    required this.onSubmit,
  });

  final bool manual;
  final Future<bool> Function(_JoinQueueFormData formData) onSubmit;

  @override
  State<_JoinQueueDetailsSheet> createState() => _JoinQueueDetailsSheetState();
}

class _JoinQueueDetailsSheetState extends State<_JoinQueueDetailsSheet> {
  static const List<String> _transactionSuggestions = <String>[
    'Tuition Payment',
    'Assessment',
    'Document Request',
    'Other Cashier Concern',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentIdController =
      TextEditingController();
  late final TextEditingController _transactionTypeController =
      TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _transactionTypeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    final joinedSuccessfully = await widget.onSubmit(
      _JoinQueueFormData(
        studentId: _studentIdController.text.trim(),
        transactionType: _transactionTypeController.text.trim(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (joinedSuccessfully) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final title = widget.manual
        ? 'Manual Queue Request'
        : 'Complete Queue Request';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DEE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Provide the request type first. Student ID is optional for visitors or non-students.',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5F6E82),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _studentIdController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  hintText: '2024-12345',
                  helperText: 'Optional for non-students',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _transactionTypeController,
                enabled: !_isSubmitting,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Transaction Type',
                  hintText: 'Tuition Payment',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the request transaction type.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _transactionSuggestions
                    .map(
                      (suggestion) => ActionChip(
                        label: Text(suggestion),
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                _transactionTypeController.text = suggestion;
                              },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSubmitting ? 'Submitting...' : 'Join Queue',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ScannerLensPreset {
  ultraWide,
  normal,
}
