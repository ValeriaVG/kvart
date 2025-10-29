import 'package:flutter/material.dart';
import 'package:kvart/themes/default.dart';
import 'package:kvart/timer/timer_controller.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final int _secondsTotal = 1 * 60;
  late final TimerController _timerController;

  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _timerController = TimerController(secondsTotal: _secondsTotal);
    _timerController.elapsedSeconds.listen((seconds) {
      setState(() {
        _secondsElapsed = seconds;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF020C1D),
      body: Center(
        child: DefaultTimerView(
          secondsTotal: _secondsTotal,
          secondsElapsed: _secondsElapsed,
          controller: _timerController,
        ),
      ),
    );
  }
}
