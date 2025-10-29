import 'dart:math';
import 'package:flutter/material.dart';

class Timer extends StatelessWidget {
  const Timer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF020C1D),
      body: Center(child: TimerView()),
    );
  }
}

class TimerView extends StatelessWidget {
  const TimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TimerArcPainter(0.75),
      child: const Center(
        child: Text(
          '15:00',
          style: TextStyle(
            color: Colors.white,
            fontSize: 80,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
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
