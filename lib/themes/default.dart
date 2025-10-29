import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kvart/timer/timer_controller.dart';
import 'package:kvart/timer/timer_view.dart';

class DefaultTimerView extends StatelessWidget implements TimerView {
  final int secondsTotal;
  final int secondsElapsed;
  final TimerController controller;

  const DefaultTimerView({
    super.key,
    required this.secondsTotal,
    required this.secondsElapsed,
    required this.controller,
  });

  String get _timeString {
    final remainingSeconds = secondsTotal - secondsElapsed;
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (secondsTotal - secondsElapsed) / secondsTotal;
    return CustomPaint(
      painter: TimerArcPainter(progress),
      child: Center(
        child: InkWell(
          onTap: () {
            if (controller.state == TimerState.running) {
              controller.pauseTimer();
            } else {
              controller.startTimer();
            }
          },
          child: Text(
            _timeString,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 80,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

class TimerArcPainter extends CustomPainter {
  final double progress;

  TimerArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -pi * 1.25;
    const sweepAngle = pi * 1.5;

    const strokeWidth = 32.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final progressSweepAngle = sweepAngle * progress;

    // Draw the background track
    final backgroundPaint = Paint()
      ..color = const Color(0xFF0A1A30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);

    // Draw the main arc
    final paint = Paint()
      ..color = const Color(0xFFC5F974)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, progressSweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
