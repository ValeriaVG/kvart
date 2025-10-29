import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kvart/timer/timer_controller.dart';
import 'package:kvart/timer/timer_view.dart';
import 'package:kvart/widgets/bell_animation.dart';
import 'package:kvart/widgets/seven_segment_display.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DefaultTimerView extends StatefulWidget implements TimerView {
  @override
  final int secondsTotal;
  @override
  final int secondsElapsed;
  @override
  final TimerController controller;

  const DefaultTimerView({
    super.key,
    required this.secondsTotal,
    required this.secondsElapsed,
    required this.controller,
  });

  @override
  State<DefaultTimerView> createState() => _DefaultTimerViewState();
}

class _DefaultTimerViewState extends State<DefaultTimerView> {
  bool _showBellAnimation = false;

  @override
  void initState() {
    super.initState();
    widget.controller.stateStream.listen((state) {
      if (state == TimerState.completed) {
        setState(() {
          _showBellAnimation = true;
        });
        // Hide the bell animation after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showBellAnimation = false;
            });
          }
        });
      } else if (state == TimerState.idle) {
        setState(() {
          _showBellAnimation = false;
        });
      }
    });
  }

  IconData get _iconForState {
    switch (widget.controller.state) {
      case TimerState.running:
        return LucideIcons.pause;
      case TimerState.idle:
      case TimerState.paused:
        return LucideIcons.play;
      case TimerState.completed:
        return LucideIcons.repeat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (widget.secondsTotal - widget.secondsElapsed) / widget.secondsTotal;
    final minSide = min(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final digitWidth = (minSide - 32 * 2) / 5 - 24;
    final digitHeight = digitWidth * 80 / 48;
    return Stack(
      children: [
        CustomPaint(
          painter: TimerArcPainter(progress),
          child: Center(
            child: SevenSegmentDisplay(
              minutes: (widget.secondsTotal - widget.secondsElapsed) ~/ 60,
              seconds: (widget.secondsTotal - widget.secondsElapsed) % 60,
              digitWidth: digitWidth,
              digitHeight: digitHeight,
            ),
          ),
        ),
        // Bell animation above the timer
        if (_showBellAnimation)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - minSide / 3,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: const BellAnimation(size: 64),
          ),
        Positioned(
          top: MediaQuery.of(context).size.height / 2 + minSide / 6 - 16,
          right: (MediaQuery.of(context).size.width - minSide) / 2 + 24,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              width: minSide / 3,
              height: minSide / 3,
              decoration: BoxDecoration(
                color: Color(0xFF0A1A30),
                shape: BoxShape.circle,
              ),
              child: InkWell(
                onTap: () {
                  if (widget.controller.state == TimerState.running) {
                    widget.controller.pauseTimer();
                  } else {
                    widget.controller.startTimer();
                  }
                },
                borderRadius: BorderRadius.circular(minSide / 6),
                child: Center(
                  child: Icon(
                    _iconForState,
                    color: Color(0xFF7A90B0),
                    size: minSide / 4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TimerArcPainter extends CustomPainter {
  final double progress;

  TimerArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -pi * 1.5;
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
