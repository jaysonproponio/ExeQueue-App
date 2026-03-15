import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:exequeue_mobile/features/queue/domain/entities/queue_alert.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_stage.dart';
import 'package:exequeue_mobile/features/queue/domain/entities/queue_status.dart';
import 'package:exequeue_mobile/features/queue/domain/services/queue_foreground_alert_bus.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/get_queue_status.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/queue_status_state.dart';
import 'package:exequeue_mobile/features/queue/presentation/session/queue_session_store.dart';

class QueueStatusCubit extends Cubit<QueueStatusState> {
  QueueStatusCubit({
    required GetQueueStatus getQueueStatus,
    required QueueForegroundAlertBus foregroundAlertBus,
    required QueueSessionStore queueSessionStore,
  })  : _getQueueStatus = getQueueStatus,
        _foregroundAlertBus = foregroundAlertBus,
        _queueSessionStore = queueSessionStore,
        super(const QueueStatusInitial());

  final GetQueueStatus _getQueueStatus;
  final QueueForegroundAlertBus _foregroundAlertBus;
  final QueueSessionStore _queueSessionStore;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  String? _lastForegroundAlertQueueNumber;

  Future<void> startStatusUpdates() async {
    _queueSessionStore.addListener(_handleQueueSessionChanged);
    if (_refreshTimer != null) {
      return;
    }

    await refreshQueueStatus(showLoader: true);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshQueueStatus(),
    );
  }

  Future<void> loadQueueStatus() async {
    await refreshQueueStatus(showLoader: true);
  }

  Future<void> refreshQueueStatus({bool showLoader = false}) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    final activeQueueNumber = _queueSessionStore.activeQueueNumber;
    if (activeQueueNumber == null || activeQueueNumber.trim().isEmpty) {
      emit(const QueueStatusEmpty());
      _isRefreshing = false;
      return;
    }

    if (showLoader || state is QueueStatusInitial) {
      emit(const QueueStatusLoading());
    }

    final result = await _getQueueStatus(
      GetQueueStatusParams(queueNumber: activeQueueNumber),
    );

    result.fold(
      (failure) => emit(QueueStatusError(failure)),
      (queueStatus) {
        _dispatchForegroundThresholdAlert(queueStatus);
        emit(QueueStatusLoaded(queueStatus));
      },
    );
    _isRefreshing = false;
  }

  void clearQueueStatus() {
    _lastForegroundAlertQueueNumber = null;
    _queueSessionStore.clear();
    emit(const QueueStatusEmpty());
  }

  void _handleQueueSessionChanged() {
    final activeQueueNumber = _queueSessionStore.activeQueueNumber;
    if (activeQueueNumber == null || activeQueueNumber.trim().isEmpty) {
      _lastForegroundAlertQueueNumber = null;
    }
    unawaited(refreshQueueStatus(showLoader: true));
  }

  void _dispatchForegroundThresholdAlert(QueueStatus queueStatus) {
    if (
        queueStatus.isDemo ||
        queueStatus.queueNumber.trim().isEmpty ||
        queueStatus.peopleAhead < 0 ||
        queueStatus.peopleAhead > 5 ||
        queueStatus.status == QueueStage.skipped ||
        queueStatus.status == QueueStage.done) {
      return;
    }

    if (_lastForegroundAlertQueueNumber == queueStatus.queueNumber) {
      return;
    }

    _lastForegroundAlertQueueNumber = queueStatus.queueNumber;
    _foregroundAlertBus.dispatch(
      QueueAlert(
        title: 'ExeQueue Alert',
        body: _buildForegroundAlertBody(queueStatus),
        queueNumber: queueStatus.queueNumber,
        distance: queueStatus.peopleAhead,
      ),
    );
  }

  String _buildForegroundAlertBody(QueueStatus queueStatus) {
    if (queueStatus.status == QueueStage.called || queueStatus.peopleAhead == 0) {
      return 'Your queue number ${queueStatus.queueNumber} is now being served.';
    }

    if (queueStatus.peopleAhead == 1) {
      return 'Your queue number ${queueStatus.queueNumber} has only 1 queue ahead.';
    }

    return 'Your queue number ${queueStatus.queueNumber} now has ${queueStatus.peopleAhead} queues ahead.';
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _queueSessionStore.removeListener(_handleQueueSessionChanged);
    return super.close();
  }
}
