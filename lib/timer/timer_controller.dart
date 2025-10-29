import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

enum TimerState { idle, running, paused, completed }

class TimerController {
  TimerState _state = TimerState.idle;
  List<TimeInterval> _intervals = [];
  int _secondsTotal;
  final void Function()? onComplete;

  final _elapsedController = StreamController<int>.broadcast();
  final _stateController = StreamController<TimerState>.broadcast();
  Timer? _ticker;

  TimerController({required int secondsTotal, this.onComplete})
    : _secondsTotal = secondsTotal;

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
  }

  void pauseTimer() {
    if (_state != TimerState.running) return;
    _state = TimerState.paused;
    _stateController.add(_state);
    _intervals.last.close(DateTime.now());
    _stopTicking();
    _notifyListeners();
    WakelockPlus.disable();
  }

  void stopTimer() {
    if (_state != TimerState.running) return;
    _state = TimerState.completed;
    _stateController.add(_state);
    _intervals.last.close(DateTime.now());
    _stopTicking();
    _notifyListeners();
    WakelockPlus.disable();
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
  }

  void _startTicking() {
    _stopTicking();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final totalDuration = _getTotalDuration();

      if (totalDuration.inSeconds >= _secondsTotal) {
        stopTimer();
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
    _elapsedController.add(totalDuration.inSeconds);
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
