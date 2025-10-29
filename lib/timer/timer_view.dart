import 'timer_controller.dart';

abstract class TimerView {
  final int secondsTotal;
  final int secondsElapsed;
  final TimerController controller;

  const TimerView({
    required this.secondsTotal,
    required this.secondsElapsed,
    required this.controller,
  });
}
