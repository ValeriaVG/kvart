import 'timer_controller.dart';

abstract class TimerView {
  final int secondsTotal;
  final int secondsElapsed;
  final TimerController controller;
  final bool ready;
  final void Function(int)? onSecondsChanged;

  const TimerView({
    required this.secondsTotal,
    required this.secondsElapsed,
    required this.controller,
    required this.ready,
    required this.onSecondsChanged,
  });
}
