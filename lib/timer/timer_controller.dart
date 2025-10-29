enum TimerState { idle, running, paused }

class TimerController {
  TimerState _state = TimerState.idle;
  List<TimeInterval> _intervals = [];

  void startTimer() {
    if (_state == TimerState.running) return;
    _state = TimerState.running;
    _intervals.add(TimeInterval(DateTime.now()));
  }

  void pauseTimer() {
    if (_state == TimerState.paused) return;
    _state = TimerState.paused;
    _intervals.last.close(DateTime.now());
  }

  void resetTimer() {
    _state = TimerState.idle;
    _intervals.clear();
  }

  TimerState get state => _state;

  // Stream of seconds elapsed
  Stream<int> get elapsedSeconds async* {
    while (true) {
      final totalDuration = _intervals.fold<Duration>(
        Duration.zero,
        (sum, interval) => sum + interval.duration,
      );
      yield totalDuration.inSeconds;
      await Future.delayed(const Duration(milliseconds: 500));
    }
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
