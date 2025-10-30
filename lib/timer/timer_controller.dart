import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

enum TimerState { idle, running, paused, completed }

class TimerController {
  TimerState _state = TimerState.idle;
  final List<TimeInterval> _intervals = [];
  int _secondsTotal;
  final void Function()? onComplete;
  final void Function(int)? onScheduleBackgroundNotification;
  final void Function()? onCancelBackgroundNotification;

  final _elapsedController = StreamController<int>.broadcast();
  final _stateController = StreamController<TimerState>.broadcast();
  Timer? _ticker;

  TimerController({
    required int secondsTotal,
    this.onComplete,
    this.onScheduleBackgroundNotification,
    this.onCancelBackgroundNotification,
  }) : _secondsTotal = secondsTotal;

  void startTimer() {
    if (_state == TimerState.running) return;
    if (_state == TimerState.completed) {
      resetTimer();
    }
    _state = TimerState.running;
    _stateController.add(_state);
    _intervals.add(TimeInterval(DateTime.now()));
    _notifyListeners();
    _startTicking();
    WakelockPlus.enable();

    // Schedule background notification for timer completion
    final elapsed = _getTotalDuration().inSeconds;
    final remaining = _secondsTotal - elapsed;
    if (remaining > 0) {
      onScheduleBackgroundNotification?.call(remaining);
    }
  }

  void pauseTimer() {
    if (_state != TimerState.running) return;
    _state = TimerState.paused;
    _stateController.add(_state);
    _intervals.last.close(DateTime.now());
    _stopTicking();
    _notifyListeners();
    WakelockPlus.disable();

    // Cancel background notification when paused
    onCancelBackgroundNotification?.call();
  }

  void stopTimer() {
    if (_state != TimerState.running) return;
    _state = TimerState.completed;
    _stateController.add(_state);
    _intervals.last.close(DateTime.now());
    _stopTicking();
    _notifyListeners();
    WakelockPlus.disable();

    // Cancel background notification when timer completes normally
    // (the foreground notification will be shown instead)
    onCancelBackgroundNotification?.call();
  }

  void resetTimer([int? newSecondsTotal]) {
    _state = TimerState.idle;
    _stateController.add(_state);
    _intervals.clear();
    _stopTicking();
    if (newSecondsTotal != null) {
      _secondsTotal = newSecondsTotal;
    }
    _notifyListeners();
    WakelockPlus.disable();

    // Cancel background notification when timer is reset
    onCancelBackgroundNotification?.call();
  }

  void _startTicking() {
    _stopTicking();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final totalDuration = _getTotalDuration();

      // Check if timer should complete
      if (totalDuration.inSeconds >= _secondsTotal) {
        stopTimer();
        // Ensure onComplete is called even if we're past the time
        onComplete?.call();
        return;
      }

      if (_state == TimerState.running) {
        _notifyListeners();
      }
    });
  }

  void _stopTicking() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _notifyListeners() {
    final totalDuration = _getTotalDuration();
    // Clamp elapsed seconds to never exceed the total to prevent negative display
    final clampedSeconds = totalDuration.inSeconds.clamp(0, _secondsTotal);
    _elapsedController.add(clampedSeconds);
  }

  Duration _getTotalDuration() {
    return _intervals.fold<Duration>(
      Duration.zero,
      (sum, interval) => sum + interval.duration,
    );
  }

  TimerState get state => _state;

  Stream<int> get elapsedSeconds => _elapsedController.stream;
  Stream<TimerState> get stateStream => _stateController.stream;

  void dispose() {
    _stopTicking();
    _elapsedController.close();
    _stateController.close();
  }
}

class TimeInterval {
  final DateTime _start;
  DateTime? _end;

  TimeInterval(this._start, [this._end]);

  Duration get duration {
    final endTime = _end ?? DateTime.now();
    return endTime.difference(_start);
  }

  void close(DateTime endTime) {
    if (_end != null) return;
    _end = endTime;
  }
}
