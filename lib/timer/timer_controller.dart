import 'dart:async';

enum TimerState { idle, running, paused, completed }

class TimerController {
  TimerState _state = TimerState.idle;
  List<TimeInterval> _intervals = [];
  final int secondsTotal;
  final void Function()? onComplete;

  final _elapsedController = StreamController<int>.broadcast();
  Timer? _ticker;

  TimerController({this.secondsTotal = 60 * 15, this.onComplete});

  void startTimer() {
    if (_state == TimerState.running) return;
    if (_state == TimerState.completed) {
      resetTimer();
    }
    _state = TimerState.running;
    _intervals.add(TimeInterval(DateTime.now()));
    _notifyListeners();
    _startTicking();
  }

  void pauseTimer() {
    if (_state != TimerState.running) return;
    _state = TimerState.paused;
    _intervals.last.close(DateTime.now());
    _stopTicking();
    _notifyListeners();
  }

  void stopTimer() {
    if (_state != TimerState.running) return;
    _state = TimerState.completed;
    _intervals.last.close(DateTime.now());
    _stopTicking();
    _notifyListeners();
  }

  void resetTimer() {
    _state = TimerState.idle;
    _intervals.clear();
    _stopTicking();
    _notifyListeners();
  }

  void _startTicking() {
    _stopTicking();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final totalDuration = _getTotalDuration();

      if (totalDuration.inSeconds >= secondsTotal) {
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

  void dispose() {
    _stopTicking();
    _elapsedController.close();
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
